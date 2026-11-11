import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessages } from './chat_messages.entity';
import { Persona } from './persona.entity';
import { User } from '../user/user.entity';
import { SendChatMessageDto } from './dto/send-chat-message.dto';
import { UpdatePersonaProfileDto } from './dto/update-persona-profile.dto';
import { ChatMessageResponseDto } from './dto/chat-message-response.dto';
import { PersonaListItemDto } from './dto/persona-list-item.dto';
import { PersonaProfileResponseDto } from './dto/persona-profile-response.dto';
import { SendChatMessageResponseDto } from './dto/send-chat-message-response.dto';
import { AiProviderService, AiChatMessage } from '../ai/ai-provider.service';
import { ScheduleService } from '../schedule/schedule.service';
import { ScheduleResponseDto } from '../schedule/dto/schedule-response.dto';
import { todayYmdKst } from '../schedule/schedule-datetime.util';
import { TodoService } from '../todo/todo.service';
import { TodoResponseDto } from '../todo/dto/todo-response.dto';
import { RoutineService } from '../routine/routine.service';
import { RoutineResponseDto } from '../routine/dto/routine-response.dto';
import { DiaryService } from '../diary/diary.service';
import { DiaryResponseDto } from '../diary/dto/diary-response.dto';

/** DB `persona.type` — 활성 페르소나가 없을 때 시스템 프롬프트 소스 */
const DEFAULT_PERSONA_TYPE = 'basic';

const DEFAULT_SYSTEM_PROMPT =
  '당신은 친절한 AI 비서입니다. 한국어로 간결하게 답합니다.';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatMessages)
    private readonly chatMessagesRepo: Repository<ChatMessages>,
    @InjectRepository(Persona)
    private readonly personaRepo: Repository<Persona>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly aiProvider: AiProviderService,
    private readonly scheduleService: ScheduleService,
    private readonly todoService: TodoService,
    private readonly routineService: RoutineService,
    private readonly diaryService: DiaryService,
    private readonly config: ConfigService,
  ) {}

  private toMessageDto(row: ChatMessages): ChatMessageResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      senderRole: row.senderRole,
      message: row.message,
      createdAt: row.createdAt,
    };
  }

  /**
   * 모든 사용자 대면 AI 호출의 진입점.
   * userId로 활성 페르소나를 DB에서 매 호출마다 조회해 시스템 프롬프트를 생성한다.
   * sendMessage, generateOverdueBriefing 등 모든 경로가 이 메서드를 사용한다.
   */
  private async buildPersonaSystemPrompt(
    userId: number,
    extraContext?: string,
  ): Promise<{ systemPrompt: string; personaName: string }> {
    const userWithPersona = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['activePersona'],
    });
    const personaName = userWithPersona?.activePersona?.name ?? '비서';
    const base = await this.resolveSystemPrompt(userWithPersona, userId);
    const systemPrompt = extraContext
      ? `${base}\n\n[이번 호출 컨텍스트]\n${extraContext}`
      : base;
    return { systemPrompt, personaName };
  }

  /** 활성 페르소나 → 없으면 `type=basic` 페르소나 → 없으면 고정 문구 + 일정 도구 지침 + 사용자 일정 목록 */
  private async resolveSystemPrompt(
    user: User | null,
    userId: number,
  ): Promise<string> {
    const fromActive = user?.activePersona?.system_prompt?.trim();
    const basic = await this.personaRepo.findOne({
      where: { type: DEFAULT_PERSONA_TYPE },
    });
    const fromBasic = basic?.system_prompt?.trim();
    const persona = fromActive || fromBasic || DEFAULT_SYSTEM_PROMPT;
    const personaName = user?.activePersona?.name ?? basic?.name ?? '비서';
    const basePrompt = this.buildPersonaForceBlock(personaName, persona);
    const [schedules, recentDiaries] = await Promise.all([
      this.scheduleService.findActiveForAiContext(userId),
      this.diaryService.findRecentForAiContext(userId),
    ]);
    return `${basePrompt}\n\n${this.buildScheduleInstructionBlock()}\n\n${this.buildUserSchedulesBlock(schedules)}\n\n${this.buildDiaryInstructionBlock()}\n\n${this.buildRecentDiariesBlock(recentDiaries)}\n\n${this.buildPersonaToneLock(personaName)}`;
  }

  /** 시스템 프롬프트 첫 블록: 페르소나 강제 고정. 이 블록이 모든 것보다 우선한다. */
  private buildPersonaForceBlock(name: string, prompt: string): string {
    return `=== PERSONA LOCK (HIGHEST PRIORITY — NEVER OVERRIDE) ===
You are "${name}". This is your ONLY identity.
Your speaking style is defined in [페르소나: ${name}] below.
The ━━━ 내부 처리 규칙 ━━━ sections are INTERNAL machine rules — their writing style is NOT your speaking style.
NEVER use the style of those internal rules in your responses to the user.

[페르소나: ${name}]
${prompt}
=== END PERSONA LOCK ===`;
  }

  /**
   * 시스템 프롬프트 맨 끝 — 페르소나를 다시 한번 못박아 도구 지침 문체가 출력에 스며드는 것을 막는다.
   */
  private buildPersonaToneLock(name: string): string {
    return `=== 최종 말투 확인 (응답 생성 직전 반드시 확인) ===
· 나는 지금 "${name}"이다.
· 위 ━━━ 내부 처리 규칙 ━━━ 블록의 문체(~해라/~한다/~합니다/~하세요 등)는 절대 사용자 응답에 반영하지 않는다.
· 대화 히스토리에 다른 말투 응답이 있어도 무시하고 "${name}" 말투만 사용한다.
· 도구를 쓰든 안 쓰든, 일정을 등록하든 안내하든 → 항상 "${name}" 말투로만 출력.
=== END ===`;
  }

  /** 사용자의 미완료 일정 목록 — 자연어로 scheduleId 매칭에 사용 (id·title·startTime만) */
  private buildUserSchedulesBlock(
    schedules: { id: number; title: string; startTime: string }[],
  ): string {
    if (schedules.length === 0) {
      return `[사용자의 현재 일정 목록]
(등록된 미완료 일정이 없습니다.)`;
    }
    return `[사용자의 현재 일정 목록 — 미완료 일정만, JSON 배열]
${JSON.stringify(schedules)}

- 사용자가 일정 수정·삭제·확인을 요청할 때 메시지에 [scheduleId=숫자]가 없더라도, 위 목록에서 title·startTime을 자연어로 매칭해 id를 찾아 update_schedule을 호출하세요.
- 예: "내일 회의 시간 4시로 바꿔줘" → title에 "회의"가 포함되고 startTime이 내일(KST)인 항목의 id를 사용.
- 위 목록은 오늘(KST) 이후의 미완료 일정만 포함합니다. 지난 일정은 들어있지 않습니다.
- startTime은 ISO8601 한국시간(+09:00)입니다. 날짜·"오늘/내일" 판단은 이 값을 그대로 사용하세요.
- 후보가 여러 개면 사용자에게 어떤 일정인지 되묻고, 후보가 없으면 새 일정을 만들지 말고 먼저 사용자에게 확인하세요.`;
  }

  /**
   * 도구 사용 규칙 블록. 행동 지침만 담으며 말투와 무관하다.
   * 주의: 이 블록의 문체(~해라/~한다 등)는 내부 지시용이며 사용자 응답 말투와 무관하다.
   */
  private buildScheduleInstructionBlock(): string {
    const todayKst = todayYmdKst();
    return `━━━ 내부 처리 규칙 (말투와 무관 — 도구 사용 지침) ━━━
[도구 선택 기준 — 한국 시간(Asia/Seoul) 기준]
· 일정 등록 요청 → create_schedule
· 할 일(투두) 등록 요청 → create_todo
· 반복 루틴/습관/매일알림 등록 요청 → create_routine
  - repeatDays(WEEKLY·BIWEEKLY): 영문 요일 MON,TUE,WED,THU,FRI,SAT,SUN 쉼표 구분
  - category: 루틴 폴더명(예: "운동", "마사지"), habits: 제목 배열(여러 습관일 때)
· 기존 일정·할 일 시간/마감 변경 → update_schedule / update_todo (create_* 금지)
· 날짜·시간 불분명 → 도구 호출 전 되묻기

[시간 변환 규칙 (필수)]
· startTime·endTime 형식: 24시간제 HH:mm (한국 시각)
· 오전 N시 = N:00 (01:00~11:00), 오전 12시(자정) = 00:00
· 오후 N시 = (N+12):00 — 오후 1시=13:00, 오후 6시=18:00, 오후 7시=19:00, 오후 11시=23:00
· 오후 12시(정오) = 12:00
· 오늘 날짜(KST): ${todayKst}

[날짜/시간 사용자 표기] 사용자에게 말할 때는 "오전 9시 30분", "오후 7시" 형식 사용.
[dueDate] YYYY-MM-DD 형식(선택). [scheduleLeadDays] "3일 전 알림" 같은 표현에서 추출.
━━━ 내부 처리 규칙 끝 ━━━`;
  }

  private buildDiaryInstructionBlock(): string {
    return `━━━ 내부 처리 규칙 (말투와 무관 — 일기 도구) ━━━
· "일기에 적어줘"/"오늘 ~했어 기록해" → create_diary
· 기존 일기 수정 → update_diary (응답의 diaryId 사용)
· 과거 회상 질문(예: "언제 ~했지?", "마지막으로 ~", "~ 먹은 날", "기억나?") → search_diary 먼저 호출
  - query에는 핵심 키워드만 넣기 (예: "내가 언제 마지막으로 떡볶이를 먹었더라?" → query: "떡볶이")
  - "마지막"/"언제" 질문이면 search_diary 결과의 latestMatch(가장 최근 일기)를 기준으로 답변
  - 사용자에게 날짜는 diaryDateLabel(예: 4월 15일) 형식으로 알려주기
· search_diary 결과 없으면: 일기에 해당 내용 없다고 알림 (채팅 로그·추측으로 답하지 말 것)
· 날짜 표기: 한국 달력 YYYY-MM-DD
━━━ 내부 처리 규칙 끝 ━━━`;
  }

  private buildRecentDiariesBlock(
    diaries: { id: number; diaryDate: string; title: string | null; excerpt: string }[],
  ): string {
    if (diaries.length === 0) {
      return `[최근 일기 요약]
(최근 2주 일기가 없습니다. 과거 회상은 search_diary를 사용하세요.)`;
    }
    return `[최근 일기 요약 — 최근 2주, JSON]
${JSON.stringify(diaries)}

- 위는 요약입니다. 구체적 날짜·내용이 필요하면 search_diary로 검색하세요.`;
  }

  private toPersonaListItem(p: Persona): PersonaListItemDto {
    return {
      id: p.id,
      type: p.type,
      name: p.name,
      description: p.description,
      image: p.image,
    };
  }

  /**
   * 지난(overdue) 일정 브리핑을 활성 페르소나 말투로 생성한다.
   * DB(채팅 로그)에는 저장하지 않으며, 생성된 문장만 반환한다.
   */
  async generateOverdueBriefing(
    userId: number,
    items: { title: string; startTime?: string }[],
  ): Promise<{ text: string }> {
    if (!items || items.length === 0) return { text: '' };

    // 통합 페르소나 시스템 프롬프트 사용 (sendMessage와 동일 경로)
    const { systemPrompt } = await this.buildPersonaSystemPrompt(userId);

    const lines = items
      .map((it) => `- ${it.title}${it.startTime ? ` (${it.startTime})` : ''}`)
      .join('\n');
    const userContent =
      items.length === 1
        ? `아래는 isCompleted=false(미완료)이고 시작 시각이 이미 지난 일정입니다. 완료된 일정은 포함되지 않았습니다:\n${lines}\n` +
          `너의 페르소나 말투 그대로, 이 일정이 지났다고 알리고 미룰지 자연스럽게 한두 문장으로 물어봐. 목록을 기계적으로 나열하지 말고 네 성격대로 말해.`
        : `아래는 isCompleted=false(미완료)이고 시작 시각이 이미 지난 일정 ${items.length}개입니다. 완료된 일정은 포함되지 않았습니다:\n${lines}\n` +
          `너의 페르소나 말투 그대로, 지난 일정이 있다고 브리핑하고 미룰 일정이 있는지 자연스럽게 물어봐. 목록을 기계적으로 그대로 나열하지 말고 네 성격대로 말해.`;

    const aiMessages: AiChatMessage[] = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userContent },
    ];

    const result = await this.aiProvider.chat(aiMessages, userId);
    return { text: result.text?.trim() || '' };
  }

  async getMessages(userId: number): Promise<ChatMessageResponseDto[]> {
    const rows = await this.chatMessagesRepo.find({
      where: { userId },
      order: { createdAt: 'ASC' },
    });
    return rows.map((r) => this.toMessageDto(r));
  }

  async sendMessage(
    userId: number,
    dto: SendChatMessageDto,
  ): Promise<SendChatMessageResponseDto> {
    const userRef = { id: userId } as User;

    const userRow = this.chatMessagesRepo.create({
      userId,
      user: userRef,
      senderRole: 'user',
      message: dto.message.trim(),
    });
    const userMessage = await this.chatMessagesRepo.save(userRow);

    const contextHint = dto.contextHint?.trim();
    const { systemPrompt, personaName } = await this.buildPersonaSystemPrompt(
      userId,
      contextHint || undefined,
    );

    const maxHistory = Number(
      this.config.get<string>('AI_MAX_HISTORY_MESSAGES') ?? '40',
    );
    const historyCap = Number.isFinite(maxHistory) && maxHistory > 0
      ? maxHistory
      : 40;

    const allRows = await this.chatMessagesRepo.find({
      where: { userId },
      order: { createdAt: 'ASC' },
    });
    const contextRows = allRows
      .filter(
        (r) => r.senderRole === 'user' || r.senderRole === 'assistant',
      )
      .slice(-historyCap);

    const historyMsgs: AiChatMessage[] = contextRows.map((r) => ({
      role: r.senderRole as 'user' | 'assistant',
      content: r.message,
    }));

    // 현재 메시지(마지막 항목)와 이전 히스토리를 분리.
    // 히스토리가 있을 때 현재 메시지 바로 앞에 페르소나 리마인더 쌍을 삽입한다.
    // → 이전 페르소나 말투가 히스토리에 남아있어도 현재 페르소나로 강제 전환.
    const priorHistory = historyMsgs.slice(0, -1);
    const currentMsg = historyMsgs.at(-1);
    const reminderPair: AiChatMessage[] =
      priorHistory.length > 0 && currentMsg
        ? [
            {
              role: 'user',
              content: `[시스템: 말투 재확인] 너는 지금 "${personaName}"이야. 이 말투를 계속 유지해.`,
            },
            {
              role: 'assistant',
              content: `알겠어. "${personaName}" 말투를 유지할게.`,
            },
          ]
        : [];

    const aiMessages: AiChatMessage[] = [
      { role: 'system', content: systemPrompt },
      ...priorHistory,
      ...reminderPair,
      ...(currentMsg ? [currentMsg] : []),
    ];

    let assistantText: string;
    let createdSchedule: ScheduleResponseDto | null = null;
    let createdTodo: TodoResponseDto | null = null;
    let createdRoutine: RoutineResponseDto | null = null;
    let createdRoutines: RoutineResponseDto[] | null = null;
    let createdDiary: DiaryResponseDto | null = null;
    let itemUpdated = false;
    try {
      const result = await this.aiProvider.chat(aiMessages, userId);
      assistantText = result.text;

      if (result.toolCall?.name === 'create_schedule') {
        const created = await this.scheduleService.createFromAiToolInput(
          userId,
          result.toolCall.input,
          dto.message.trim(),
        );

        if (created.ok) {
          createdSchedule = created.schedule;
          itemUpdated = created.updated === true;
          if (result.provider === 'claude') {
            const finalReply = await this.aiProvider.continueWithToolResult(
              result.toolCall.id,
              aiMessages,
              result.assistantToolUseContent ?? [],
              JSON.stringify({
                ok: true,
                updated: itemUpdated,
                schedule: created.schedule,
              }),
              result.provider,
              result.model,
            );
            assistantText =
              finalReply.text ||
              (itemUpdated ? '일정을 수정했습니다.' : '일정을 등록했습니다.');
          } else if (result.provider === 'gemini') {
            const finalReply = await this.aiProvider.continueGeminiAfterSchedule(
              aiMessages,
              {
                id: result.toolCall.id,
                name: 'create_schedule',
                args: result.toolCall.input,
              },
              {
                ok: true,
                updated: itemUpdated,
                schedule: created.schedule as unknown as Record<string, unknown>,
              },
              result.provider,
              result.model,
              userId,
            );
            assistantText =
              finalReply.text ||
              (itemUpdated ? '일정을 수정했습니다.' : '일정을 등록했습니다.');
          } else {
            assistantText = itemUpdated
              ? `"${created.schedule.title}" 일정 시간을 반영했습니다. [scheduleId=${created.schedule.id}]`
              : `"${created.schedule.title}" 일정을 등록했습니다. [scheduleId=${created.schedule.id}]`;
          }
        } else {
          assistantText = `일정 등록에 실패했어요: ${created.error}`;
        }
      } else if (result.toolCall?.name === 'update_schedule') {
        const scheduleId = this.parseToolId(result.toolCall.input);
        if (scheduleId == null) {
          assistantText = '수정할 일정 id가 필요합니다.';
        } else {
          const updated = await this.scheduleService.updateFromAiToolInput(
            userId,
            scheduleId,
            result.toolCall.input,
            dto.message.trim(),
          );

          if (updated.ok) {
            createdSchedule = updated.schedule;
            itemUpdated = true;
            if (result.provider === 'claude') {
              const finalReply = await this.aiProvider.continueWithToolResult(
                result.toolCall.id,
                aiMessages,
                result.assistantToolUseContent ?? [],
                JSON.stringify({
                  ok: true,
                  updated: true,
                  schedule: updated.schedule,
                }),
                result.provider,
                result.model,
              );
              assistantText = finalReply.text || '일정을 수정했습니다.';
            } else if (result.provider === 'gemini') {
              const finalReply =
                await this.aiProvider.continueGeminiAfterSchedule(
                  aiMessages,
                  {
                    id: result.toolCall.id,
                    name: 'update_schedule',
                    args: result.toolCall.input,
                  },
                  {
                    ok: true,
                    updated: true,
                    schedule: updated.schedule as unknown as Record<
                      string,
                      unknown
                    >,
                  },
                  result.provider,
                  result.model,
                  userId,
                );
              assistantText = finalReply.text || '일정을 수정했습니다.';
            } else {
              assistantText = `"${updated.schedule.title}" 일정 시간을 반영했습니다. [scheduleId=${updated.schedule.id}]`;
            }
          } else {
            assistantText = `일정 수정에 실패했어요: ${updated.error}`;
          }
        }
      } else if (result.toolCall?.name === 'create_todo') {
        const created = await this.todoService.createFromAiToolInput(
          userId,
          result.toolCall.input,
          dto.message.trim(),
        );

        if (created.ok) {
          createdTodo = created.todo;
          itemUpdated = created.updated === true;
          if (result.provider === 'claude') {
            const finalReply = await this.aiProvider.continueWithToolResult(
              result.toolCall.id,
              aiMessages,
              result.assistantToolUseContent ?? [],
              JSON.stringify({
                ok: true,
                updated: itemUpdated,
                todo: created.todo,
              }),
              result.provider,
              result.model,
            );
            assistantText =
              finalReply.text ||
              (itemUpdated ? '할 일을 수정했습니다.' : '할 일을 등록했습니다.');
          } else if (result.provider === 'gemini') {
            const finalReply = await this.aiProvider.continueGeminiAfterSchedule(
              aiMessages,
              {
                id: result.toolCall.id,
                name: 'create_todo',
                args: result.toolCall.input,
              },
              {
                ok: true,
                updated: itemUpdated,
                todo: created.todo as unknown as Record<string, unknown>,
              },
              result.provider,
              result.model,
              userId,
            );
            assistantText =
              finalReply.text ||
              (itemUpdated ? '할 일을 수정했습니다.' : '할 일을 등록했습니다.');
          } else {
            assistantText = itemUpdated
              ? `"${created.todo.title}" 할 일 마감 정보를 반영했습니다. [todoId=${created.todo.id}]`
              : `"${created.todo.title}" 할 일을 등록했습니다. [todoId=${created.todo.id}]`;
          }
        } else {
          assistantText = `할 일 등록에 실패했어요: ${created.error}`;
        }
      } else if (result.toolCall?.name === 'update_todo') {
        const todoId = this.parseToolId(result.toolCall.input);
        if (todoId == null) {
          assistantText = '수정할 할 일 id가 필요합니다.';
        } else {
          const updated = await this.todoService.updateFromAiToolInput(
            userId,
            todoId,
            result.toolCall.input,
            dto.message.trim(),
          );

          if (updated.ok) {
            createdTodo = updated.todo;
            itemUpdated = true;
            if (result.provider === 'claude') {
              const finalReply = await this.aiProvider.continueWithToolResult(
                result.toolCall.id,
                aiMessages,
                result.assistantToolUseContent ?? [],
                JSON.stringify({
                  ok: true,
                  updated: true,
                  todo: updated.todo,
                }),
                result.provider,
                result.model,
              );
              assistantText = finalReply.text || '할 일을 수정했습니다.';
            } else if (result.provider === 'gemini') {
              const finalReply =
                await this.aiProvider.continueGeminiAfterSchedule(
                  aiMessages,
                  {
                    id: result.toolCall.id,
                    name: 'update_todo',
                    args: result.toolCall.input,
                  },
                  {
                    ok: true,
                    updated: true,
                    todo: updated.todo as unknown as Record<string, unknown>,
                  },
                  result.provider,
                  result.model,
                  userId,
                );
              assistantText = finalReply.text || '할 일을 수정했습니다.';
            } else {
              assistantText = `"${updated.todo.title}" 할 일 마감 정보를 반영했습니다. [todoId=${updated.todo.id}]`;
            }
          } else {
            assistantText = `할 일 수정에 실패했어요: ${updated.error}`;
          }
        }
      } else if (result.toolCall?.name === 'create_routine') {
        const created = await this.routineService.createFromAiToolInput(
          userId,
          result.toolCall.input,
          dto.message.trim(),
        );

        if (created.ok) {
          createdRoutines = created.routines;
          createdRoutine = created.routines[0] ?? null;
          const routinePayload = {
            ok: true,
            routines: created.routines,
            count: created.routines.length,
          };
          if (result.provider === 'claude') {
            const finalReply = await this.aiProvider.continueWithToolResult(
              result.toolCall.id,
              aiMessages,
              result.assistantToolUseContent ?? [],
              JSON.stringify(routinePayload),
              result.provider,
              result.model,
            );
            assistantText = finalReply.text || '루틴을 등록했습니다.';
          } else if (result.provider === 'gemini') {
            const finalReply = await this.aiProvider.continueGeminiAfterSchedule(
              aiMessages,
              {
                id: result.toolCall.id,
                name: 'create_routine',
                args: result.toolCall.input,
              },
              routinePayload as unknown as Record<string, unknown>,
              result.provider,
              result.model,
              userId,
            );
            assistantText = finalReply.text || '루틴을 등록했습니다.';
          } else {
            const cat = created.routines[0]?.category ?? '루틴';
            const names = created.routines.map((r) => r.title).join('", "');
            assistantText =
              created.routines.length > 1
                ? `"${cat}"에 ${created.routines.length}개 습관("${names}")을 등록했습니다.`
                : `"${created.routines[0]!.title}" 루틴을 등록했습니다.`;
          }
        } else {
          assistantText = `루틴 등록에 실패했어요: ${created.error}`;
        }
      } else if (result.toolCall?.name === 'create_diary') {
        const created = await this.diaryService.createFromAiToolInput(
          userId,
          result.toolCall.input,
          dto.message.trim(),
        );

        if (created.ok) {
          createdDiary = created.diary;
          const payload = {
            ok: true,
            diary: created.diary,
          };
          if (result.provider === 'claude') {
            const finalReply = await this.aiProvider.continueWithToolResult(
              result.toolCall.id,
              aiMessages,
              result.assistantToolUseContent ?? [],
              JSON.stringify(payload),
              result.provider,
              result.model,
            );
            assistantText =
              finalReply.text || '일기를 저장했습니다.';
          } else if (result.provider === 'gemini') {
            const finalReply = await this.aiProvider.continueGeminiAfterSchedule(
              aiMessages,
              {
                id: result.toolCall.id,
                name: 'create_diary',
                args: result.toolCall.input,
              },
              payload as unknown as Record<string, unknown>,
              result.provider,
              result.model,
              userId,
            );
            assistantText =
              finalReply.text || '일기를 저장했습니다.';
          } else {
            assistantText = `일기를 저장했습니다. [diaryId=${created.diary.id}]`;
          }
        } else {
          assistantText = `일기 저장에 실패했어요: ${created.error}`;
        }
      } else if (result.toolCall?.name === 'update_diary') {
        const diaryId = this.parseToolId(result.toolCall.input);
        if (diaryId == null) {
          assistantText = '수정할 일기 id가 필요합니다.';
        } else {
          const updated = await this.diaryService.updateFromAiToolInput(
            userId,
            diaryId,
            result.toolCall.input,
            dto.message.trim(),
          );

          if (updated.ok) {
            createdDiary = updated.diary;
            itemUpdated = true;
            const payload = { ok: true, updated: true, diary: updated.diary };
            if (result.provider === 'claude') {
              const finalReply = await this.aiProvider.continueWithToolResult(
                result.toolCall.id,
                aiMessages,
                result.assistantToolUseContent ?? [],
                JSON.stringify(payload),
                result.provider,
                result.model,
              );
              assistantText = finalReply.text || '일기를 수정했습니다.';
            } else if (result.provider === 'gemini') {
              const finalReply =
                await this.aiProvider.continueGeminiAfterSchedule(
                  aiMessages,
                  {
                    id: result.toolCall.id,
                    name: 'update_diary',
                    args: result.toolCall.input,
                  },
                  payload as unknown as Record<string, unknown>,
                  result.provider,
                  result.model,
                  userId,
                );
              assistantText = finalReply.text || '일기를 수정했습니다.';
            } else {
              assistantText = `일기를 수정했습니다. [diaryId=${updated.diary.id}]`;
            }
          } else {
            assistantText = `일기 수정에 실패했어요: ${updated.error}`;
          }
        }
      } else if (result.toolCall?.name === 'search_diary') {
        const searched = await this.diaryService.searchFromAiToolInput(
          userId,
          result.toolCall.input,
        );

        if (searched.ok) {
          const payload = {
            ok: true,
            query: searched.query,
            searchTerms: searched.searchTerms,
            count: searched.items.length,
            latestMatch: searched.latestMatch,
            items: searched.items,
            hint:
              searched.latestMatch != null
                ? `"${searched.query}" 관련 가장 최근 기록: ${searched.latestMatch.diaryDateLabel ?? searched.latestMatch.diaryDate} (diaryDate=${searched.latestMatch.diaryDate})`
                : null,
          };
          if (result.provider === 'claude') {
            const finalReply = await this.aiProvider.continueWithToolResult(
              result.toolCall.id,
              aiMessages,
              result.assistantToolUseContent ?? [],
              JSON.stringify(payload),
              result.provider,
              result.model,
            );
            assistantText = finalReply.text || this.formatDiarySearchFallback(searched);
          } else if (result.provider === 'gemini') {
            const finalReply = await this.aiProvider.continueGeminiAfterSchedule(
              aiMessages,
              {
                id: result.toolCall.id,
                name: 'search_diary',
                args: result.toolCall.input,
              },
              payload as unknown as Record<string, unknown>,
              result.provider,
              result.model,
              userId,
            );
            assistantText =
              finalReply.text || this.formatDiarySearchFallback(searched);
          } else {
            assistantText = this.formatDiarySearchFallback(searched);
          }
        } else {
          assistantText = `일기 검색에 실패했어요: ${searched.error}`;
        }
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      assistantText = `[AI 오류] ${msg}`;
    }

    const assistantRow = this.chatMessagesRepo.create({
      userId,
      user: userRef,
      senderRole: 'assistant',
      message: assistantText,
    });
    const assistantMessage = await this.chatMessagesRepo.save(assistantRow);

    return {
      userMessage: this.toMessageDto(userMessage),
      assistantMessage: this.toMessageDto(assistantMessage),
      schedule: createdSchedule,
      todo: createdTodo,
      routine: createdRoutine,
      routines: createdRoutines,
      diary: createdDiary,
      updated: itemUpdated || undefined,
    };
  }

  private formatDiarySearchFallback(searched: {
    ok: true;
    query: string;
    items: {
      diaryDate: string;
      diaryDateLabel?: string;
      title: string | null;
      content: string;
    }[];
    latestMatch: {
      diaryDate: string;
      diaryDateLabel?: string;
      title: string | null;
      content: string;
    } | null;
  }): string {
    if (searched.items.length === 0) {
      return `일기에서 "${searched.query}"(와)과 관련된 기록을 찾지 못했어요.`;
    }

    const latest = searched.latestMatch ?? searched.items[0];
    const dateLabel = latest.diaryDateLabel ?? latest.diaryDate;
    const title = latest.title ? `「${latest.title}」` : '';
    const snippet =
      latest.content.length > 120
        ? `${latest.content.slice(0, 120)}…`
        : latest.content;

    if (searched.items.length === 1) {
      return `일기를 확인해 보니 ${dateLabel}에 ${title} 관련 기록이 있어요.\n${snippet}`;
    }

    const lines = searched.items.map((item) => {
      const itemTitle = item.title ? `「${item.title}」` : '';
      const itemSnippet =
        item.content.length > 80
          ? `${item.content.slice(0, 80)}…`
          : item.content;
      const itemDate = item.diaryDateLabel ?? item.diaryDate;
      return `- ${itemDate}${itemTitle}: ${itemSnippet}`;
    });

    return `일기에서 "${searched.query}" 관련 기록을 찾았어요. 가장 최근은 ${dateLabel}이에요.\n${lines.join('\n')}`;
  }

  private parseToolId(input: Record<string, unknown>): number | null {
    const raw = input.id;
    if (typeof raw === 'number' && Number.isFinite(raw)) {
      return Math.floor(raw);
    }
    const parsed = Number(String(raw ?? '').trim());
    return Number.isFinite(parsed) ? Math.floor(parsed) : null;
  }

  async listPersonas(): Promise<PersonaListItemDto[]> {
    const list = await this.personaRepo.find({ order: { id: 'ASC' } });
    return list.map((p) => this.toPersonaListItem(p));
  }

  async getPersonaProfile(userId: number): Promise<PersonaProfileResponseDto> {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['activePersona'],
    });
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    return this.buildPersonaProfileResponse(user);
  }

  async updatePersonaProfile(
    userId: number,
    dto: UpdatePersonaProfileDto,
  ): Promise<PersonaProfileResponseDto> {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['activePersona'],
    });
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }

    const oldPersonaId = user.activePersona?.id ?? null;
    let personaChanged = false;

    if (dto.activePersonaId !== undefined) {
      if (dto.activePersonaId === null) {
        if (oldPersonaId !== null) personaChanged = true;
        user.activePersona = null;
      } else {
        const persona = await this.personaRepo.findOne({
          where: { id: dto.activePersonaId },
        });
        if (!persona) {
          throw new BadRequestException('존재하지 않는 페르소나입니다');
        }
        if (dto.activePersonaId !== oldPersonaId) personaChanged = true;
        user.activePersona = persona;
      }
    }

    if (dto.personaNickname !== undefined) {
      const v = dto.personaNickname;
      user.personaNickname =
        v === null || (typeof v === 'string' && v.trim() === '')
          ? null
          : v.trim();
    }

    await this.userRepo.save(user);

    // 페르소나가 실제로 변경된 경우에만 히스토리 삭제. 이전 말투가 AI 컨텍스트에 남지 않도록 함.
    if (personaChanged) {
      await this.chatMessagesRepo.delete({ userId });
    }

    const reloaded = await this.userRepo.findOne({
      where: { id: userId },
      relations: ['activePersona'],
    });
    if (!reloaded) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    return this.buildPersonaProfileResponse(reloaded);
  }

  private buildPersonaProfileResponse(user: User): PersonaProfileResponseDto {
    const ap = user.activePersona;
    return {
      activePersonaId: ap?.id ?? null,
      personaNickname: user.personaNickname,
      activePersona: ap ? this.toPersonaListItem(ap) : null,
    };
  }
}
