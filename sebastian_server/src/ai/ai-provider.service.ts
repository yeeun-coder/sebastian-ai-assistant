import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiConfig } from './ai-config.entity';
import { AiUsage } from './ai-usage.entity';

export type AiChatMessage = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

export interface AiChatResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
  costUsd: number;
  toolCall?: {
    name: string;
    id: string;
    input: Record<string, unknown>;
  };
  assistantToolUseContent?: unknown;
  provider?: string;
  model?: string;
}

/** USD per 1 M tokens */
export const MODEL_PRICING: Record<
  string,
  { input: number; output: number }
> = {
  // Claude
  'claude-sonnet-4-20250514': { input: 3, output: 15 },
  'claude-opus-4-20250514': { input: 15, output: 75 },
  'claude-haiku-4-5-20251001': { input: 0.8, output: 4 },
  // OpenAI
  'gpt-4o': { input: 2.5, output: 10 },
  'gpt-4o-mini': { input: 0.15, output: 0.6 },
  'gpt-4-turbo': { input: 10, output: 30 },
  'o4-mini': { input: 1.1, output: 4.4 },
  // Gemini
  'gemini-2.5-flash': { input: 0.15, output: 0.6 },
  'gemini-2.5-pro': { input: 1.25, output: 10 },
  'gemini-2.0-flash': { input: 0.1, output: 0.4 },
};

const DEFAULT_MODELS: Record<string, string> = {
  claude: 'claude-sonnet-4-20250514',
  openai: 'gpt-4o-mini',
  gemini: 'gemini-2.0-flash',
};

@Injectable()
export class AiProviderService {
  private readonly logger = new Logger(AiProviderService.name);
  private readonly scheduleTool = {
    name: 'create_schedule',
    description:
      '한국(Asia/Seoul) 기준으로 새 일정을 등록합니다. 날짜·제목이 확정됐을 때 호출하세요. 시간이 없으면 startTime·endTime 없이 종일로 등록합니다. 직전에 등록한 일정에 시간만 보충할 때는 create_schedule이 아니라 update_schedule을 사용하세요.',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: '일정 제목' },
        date: {
          type: 'string',
          description: 'YYYY-MM-DD (한국 달력 기준 날짜)',
        },
        endDate: {
          type: 'string',
          description: 'YYYY-MM-DD 종료 날짜 (선택, 한국 달력)',
        },
        startTime: {
          type: 'string',
          description:
            '시작 시각 24시간제 HH:mm (한국 시각). 오후 1시 30분 → 13:30. 없으면 종일',
        },
        endTime: {
          type: 'string',
          description: '종료 시각 24시간제 HH:mm (한국 시각, 선택)',
        },
        category: { type: 'string', description: '카테고리 (선택)' },
        description: { type: 'string', description: '메모 (선택)' },
        isAlarmOn: { type: 'boolean', description: '알림 여부 (선택, 기본 true)' },
      },
      required: ['title', 'date'],
    },
  };
  private readonly updateScheduleTool = {
    name: 'update_schedule',
    description:
      '이미 등록된 일정을 수정합니다. 사용자가 시간·날짜만 알려줄 때, 또는 직전 create_schedule 직후 응답의 scheduleId로 시간을 반영할 때 사용하세요. 새 일정을 만들지 마세요.',
    input_schema: {
      type: 'object',
      properties: {
        id: {
          type: 'number',
          description: '수정할 일정 ID (직전 등록 응답의 scheduleId)',
        },
        title: { type: 'string', description: '일정 제목 (선택)' },
        date: {
          type: 'string',
          description: 'YYYY-MM-DD (선택, 한국 달력 기준 날짜)',
        },
        endDate: {
          type: 'string',
          description: 'YYYY-MM-DD 종료 날짜 (선택)',
        },
        startTime: {
          type: 'string',
          description: '시작 시각 24시간제 HH:mm (한국 시각)',
        },
        endTime: {
          type: 'string',
          description: '종료 시각 24시간제 HH:mm (선택)',
        },
        category: { type: 'string', description: '카테고리 (선택)' },
        description: { type: 'string', description: '메모 (선택)' },
        isAlarmOn: { type: 'boolean', description: '알림 여부 (선택)' },
      },
      required: ['id'],
    },
  };
  private readonly todoTool = {
    name: 'create_todo',
    description:
      '한국(Asia/Seoul) 기준으로 새 할 일(To-Do)을 등록합니다. 제목이 확정됐을 때 호출하세요. 마감일이 없으면 dueDate 없이 등록합니다. 직전에 등록한 할 일에 마감일·시간만 보충할 때는 create_todo가 아니라 update_todo를 사용하세요.',
    input_schema: {
      type: 'object',
      properties: {
        title: { type: 'string', description: '할 일 제목' },
        dueDate: {
          type: 'string',
          description: '마감 날짜 YYYY-MM-DD (선택, 한국 달력 기준)',
        },
        description: { type: 'string', description: '상세 메모 (선택)' },
        category: { type: 'string', description: '카테고리 (선택)' },
        scheduleLeadDays: {
          type: 'number',
          description: '마감일 기준 며칠 전부터 표시할지 (선택, 기본 0)',
        },
      },
      required: ['title'],
    },
  };
  private readonly updateTodoTool = {
    name: 'update_todo',
    description:
      '이미 등록된 할 일을 수정합니다. 사용자가 마감일·알림만 알려줄 때, 또는 직전 create_todo 직후 응답의 todoId로 보충할 때 사용하세요. 새 할 일을 만들지 마세요.',
    input_schema: {
      type: 'object',
      properties: {
        id: {
          type: 'number',
          description: '수정할 할 일 ID (직전 등록 응답의 todoId)',
        },
        title: { type: 'string', description: '할 일 제목 (선택)' },
        dueDate: {
          type: 'string',
          description: '마감 날짜 YYYY-MM-DD (한국 달력 기준)',
        },
        description: { type: 'string', description: '상세 메모 (선택)' },
        category: { type: 'string', description: '카테고리 (선택)' },
        scheduleLeadDays: {
          type: 'number',
          description: '마감일 기준 며칠 전부터 표시할지 (선택)',
        },
      },
      required: ['id'],
    },
  };
  private readonly routineTool = {
    name: 'create_routine',
    description:
      '반복 루틴(같은 시각·같은 반복 규칙의 습관·알람)을 등록합니다. 여러 습관을 한 폴더에 넣을 때는 category에 그룹명(예: 사용자가 "마사지 루틴"이면 "마사지"), habits에 각 습관 제목 배열을 넣습니다. 습관이 하나면 title만 사용해도 됩니다. 일회성 일정은 create_schedule, 마감형 할 일은 create_todo. 한국(Asia/Seoul), targetTime은 24시간제 HH:mm.',
    input_schema: {
      type: 'object',
      properties: {
        category: {
          type: 'string',
          description:
            '앱에서 폴더로 묶이는 루틴 그룹명 (예: 마사지, 운동). 생략 시 "일반"',
        },
        title: {
          type: 'string',
          description:
            '습관 제목 1개만 등록할 때. habits가 있으면 생략 가능',
        },
        habits: {
          type: 'array',
          items: { type: 'string' },
          description:
            '같은 시간·반복으로 여러 줄 등록할 습관 제목 목록. 예: ["다리 마사지","허리 마사지"]. 있으면 각각 별도 행으로 저장됨.',
        },
        targetTime: {
          type: 'string',
          description: '알람 시각 24시간제 HH:mm (한국 시각)',
        },
        repeatInterval: {
          type: 'string',
          description:
            'DAILY(매일) | WEEKLY(매주) | BIWEEKLY(격주) | MONTHLY(매월 같은 날) | YEARLY(매년)',
        },
        repeatDays: {
          type: 'string',
          description:
            'WEEKLY·BIWEEKLY일 때만: 영문 요일 쉼표 구분 MON,TUE,WED,THU,FRI,SAT,SUN',
        },
        repeatDayOfMonth: {
          type: 'number',
          description: 'MONTHLY·YEARLY: 일(1–31)',
        },
        repeatMonth: { type: 'number', description: 'YEARLY: 월(1–12)' },
        biweeklyAnchorDate: {
          type: 'string',
          description: 'BIWEEKLY: 격주 기준일 YYYY-MM-DD (선택)',
        },
      },
      required: ['targetTime', 'repeatInterval'],
    },
  };
  private readonly diaryTool = {
    name: 'create_diary',
    description:
      '사용자의 일기(과거에 있었던 일·감정·경험)를 저장합니다. "일기에 적어줘", "오늘 ~했어 기록해" 등일 때 사용하세요. 미래 약속·알림은 create_schedule, 할 일은 create_todo. diaryDate 없으면 오늘(한국) 날짜.',
    input_schema: {
      type: 'object',
      properties: {
        diaryDate: {
          type: 'string',
          description: '기록 대상 날 YYYY-MM-DD (한국 달력, 선택)',
        },
        date: {
          type: 'string',
          description: 'diaryDate와 동일 (선택)',
        },
        title: { type: 'string', description: '제목 (선택)' },
        content: {
          type: 'string',
          description: '일기 본문 (필수)',
        },
        mood: { type: 'string', description: '기분 (선택)' },
      },
      required: ['content'],
    },
  };
  private readonly updateDiaryTool = {
    name: 'update_diary',
    description:
      '이미 저장된 일기에 내용을 추가·수정합니다. 직전 create_diary 응답의 diaryId로 보완할 때 사용하세요.',
    input_schema: {
      type: 'object',
      properties: {
        id: {
          type: 'number',
          description: '수정할 일기 ID (응답의 diaryId)',
        },
        title: { type: 'string', description: '제목 (선택)' },
        content: {
          type: 'string',
          description: '추가할 본문 (선택, 기존 뒤에 이어 붙임)',
        },
        mood: { type: 'string', description: '기분 (선택)' },
      },
      required: ['id'],
    },
  };
  private readonly searchDiaryTool = {
    name: 'search_diary',
    description:
      '사용자 일기에서 과거 기록을 검색합니다. "언제 ~했지?", "마지막으로 ~", "~ 먹은 날", "기억나?" 등 과거 회상 질문일 때 먼저 호출하세요. query에는 핵심 키워드만 넣으세요(예: "떡볶이"). 결과는 diaryDate 내림차순이며 latestMatch가 가장 최근 기록입니다. 결과가 없으면 일기에 없다고 안내하세요.',
    input_schema: {
      type: 'object',
      properties: {
        query: {
          type: 'string',
          description:
            '검색 키워드 (핵심 명사·동사만, 예: 떡볶이, 여행, 친구)',
        },
        dateFrom: {
          type: 'string',
          description: '검색 시작일 YYYY-MM-DD (선택)',
        },
        dateTo: {
          type: 'string',
          description: '검색 종료일 YYYY-MM-DD (선택)',
        },
        limit: {
          type: 'number',
          description: '최대 건수 (선택, 기본 10)',
        },
      },
      required: ['query'],
    },
  };

  private readonly managementTools = [
    this.scheduleTool,
    this.updateScheduleTool,
    this.todoTool,
    this.updateTodoTool,
    this.routineTool,
    this.diaryTool,
    this.updateDiaryTool,
    this.searchDiaryTool,
  ];

  private readonly managementToolNames = new Set(
    this.managementTools.map((t) => t.name),
  );

  constructor(
    @InjectRepository(AiConfig)
    private readonly configRepo: Repository<AiConfig>,
    @InjectRepository(AiUsage)
    private readonly usageRepo: Repository<AiUsage>,
    private readonly env: ConfigService,
  ) {}

  private get timeoutMs(): number {
    return Number(this.env.get<string>('AI_TIMEOUT_MS') ?? '120000');
  }

  /** 활성 프로바이더 설정 조회 */
  async getActiveConfig(): Promise<AiConfig | null> {
    return this.configRepo.findOne({ where: { isActive: true } });
  }

  /** 채팅 요청 — 활성 프로바이더로 라우팅 */
  async chat(
    messages: AiChatMessage[],
    userId?: number,
    options?: { includeScheduleTools?: boolean },
  ): Promise<AiChatResult> {
    const includeScheduleTools = options?.includeScheduleTools !== false;

    const config = await this.getActiveConfig();
    if (!config || !config.apiKey) {
      throw new Error(
        'AI 설정이 없습니다. 설정 화면에서 프로바이더와 API 키를 입력해 주세요.',
      );
    }

    let result: AiChatResult;
    switch (config.provider) {
      case 'claude':
        result = await this.callClaude(
          config,
          messages,
          includeScheduleTools,
        );
        break;
      case 'openai':
        result = await this.callOpenAI(
          config,
          messages,
          includeScheduleTools,
        );
        break;
      case 'gemini':
        result = await this.callGemini(
          config,
          messages,
          includeScheduleTools,
        );
        break;
      default:
        throw new Error(`지원하지 않는 프로바이더: ${config.provider}`);
    }

    if (userId) {
      await this.recordUsage(
        userId,
        config.provider,
        config.model,
        result.inputTokens,
        result.outputTokens,
      );
    }

    return { ...result, provider: config.provider, model: config.model };
  }

  async continueWithToolResult(
    toolUseId: string,
    originalMessages: AiChatMessage[],
    assistantToolUseContent: unknown,
    toolResultContent: string,
    provider?: string,
    model?: string,
  ): Promise<AiChatResult> {
    const config = provider && model
      ? await this.configRepo.findOne({ where: { provider, model } })
      : await this.getActiveConfig();
    if (!config || !config.apiKey) {
      throw new Error('AI 설정이 없습니다.');
    }

    if (config.provider === 'claude') {
      return this.callClaudeWithToolResult(
        config,
        originalMessages,
        assistantToolUseContent,
        toolUseId,
        toolResultContent,
      );
    }

    return {
      text: toolResultContent,
      inputTokens: 0,
      outputTokens: 0,
      costUsd: 0,
      provider: config.provider,
      model: config.model,
    };
  }

  /**
   * 일정 저장 후 Gemini에 functionResponse를 보내 자연어 답을 받습니다.
   * (Claude의 tool_result 2차 요청과 동일한 역할)
   */
  async continueGeminiAfterSchedule(
    originalMessages: AiChatMessage[],
    functionCall: { id: string; name: string; args: Record<string, unknown> },
    toolResultPayload: Record<string, unknown>,
    provider?: string,
    model?: string,
    userId?: number,
  ): Promise<AiChatResult> {
    const config = provider && model
      ? await this.configRepo.findOne({ where: { provider, model } })
      : await this.getActiveConfig();
    if (!config || !config.apiKey) {
      throw new Error('AI 설정이 없습니다.');
    }
    if (config.provider !== 'gemini') {
      throw new Error('continueGeminiAfterSchedule는 Gemini 전용입니다.');
    }
    const result = await this.callGeminiWithFunctionResponse(
      config,
      originalMessages,
      functionCall,
      toolResultPayload,
    );
    if (userId) {
      await this.recordUsage(
        userId,
        config.provider,
        config.model,
        result.inputTokens,
        result.outputTokens,
      );
    }
    return { ...result, provider: config.provider, model: config.model };
  }

  /* ───── Claude ───── */

  private async callClaude(
    config: AiConfig,
    messages: AiChatMessage[],
    includeScheduleTools = true,
  ): Promise<AiChatResult> {
    const systemMsg = messages.find((m) => m.role === 'system');
    const chatMsgs = messages.filter((m) => m.role !== 'system');

    const body: Record<string, unknown> = {
      model: config.model,
      max_tokens: 4096,
      messages: chatMsgs.map((m) => ({ role: m.role, content: m.content })),
    };
    if (includeScheduleTools) {
      body.tools = this.managementTools;
    }
    if (systemMsg) {
      body.system = systemMsg.content;
    }

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(this.timeoutMs),
    });

    const raw = await res.text();
    if (!res.ok) {
      const errMsg = this.parseErrorMessage(raw) ?? `HTTP ${res.status}`;
      throw new Error(`Claude 오류: ${errMsg}`);
    }

    const data = JSON.parse(raw);
    const text =
      data.content
        ?.filter((b: { type: string }) => b.type === 'text')
        .map((b: { text: string }) => b.text)
        .join('') ?? '';
    const toolUse = data.content?.find(
      (b: { type: string }) => b.type === 'tool_use',
    );
    const usage = data.usage;

    return {
      text: text.trim(),
      inputTokens: usage?.input_tokens ?? 0,
      outputTokens: usage?.output_tokens ?? 0,
      costUsd: this.calcCost(
        config.model,
        usage?.input_tokens ?? 0,
        usage?.output_tokens ?? 0,
      ),
      toolCall: toolUse
        ? {
            name: toolUse.name,
            id: toolUse.id,
            input: toolUse.input ?? {},
          }
        : undefined,
      assistantToolUseContent: toolUse ? [toolUse] : undefined,
    };
  }

  private async callClaudeWithToolResult(
    config: AiConfig,
    messages: AiChatMessage[],
    assistantToolUseContent: unknown,
    toolUseId: string,
    toolResultContent: string,
  ): Promise<AiChatResult> {
    const systemMsg = messages.find((m) => m.role === 'system');
    const chatMsgs = messages.filter((m) => m.role !== 'system');
    const anthropicMessages: unknown[] = chatMsgs.map((m) => ({
      role: m.role,
      content: m.content,
    }));
    anthropicMessages.push({
      role: 'assistant',
      content: assistantToolUseContent,
    });
    anthropicMessages.push({
      role: 'user',
      content: [
        {
          type: 'tool_result',
          tool_use_id: toolUseId,
          content: toolResultContent,
        },
      ],
    });

    const body: Record<string, unknown> = {
      model: config.model,
      max_tokens: 4096,
      messages: anthropicMessages,
      tools: this.managementTools,
    };
    if (systemMsg) {
      body.system = systemMsg.content;
    }

    const res = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    const raw = await res.text();
    if (!res.ok) {
      const errMsg = this.parseErrorMessage(raw) ?? `HTTP ${res.status}`;
      throw new Error(`Claude 오류: ${errMsg}`);
    }
    const data = JSON.parse(raw);
    const text =
      data.content
        ?.filter((b: { type: string }) => b.type === 'text')
        .map((b: { text: string }) => b.text)
        .join('') ?? '';
    const usage = data.usage;
    return {
      text: text.trim(),
      inputTokens: usage?.input_tokens ?? 0,
      outputTokens: usage?.output_tokens ?? 0,
      costUsd: this.calcCost(
        config.model,
        usage?.input_tokens ?? 0,
        usage?.output_tokens ?? 0,
      ),
      provider: config.provider,
      model: config.model,
    };
  }

  /* ───── OpenAI ───── */

  private async callOpenAI(
    config: AiConfig,
    messages: AiChatMessage[],
    includeScheduleTools = true,
  ): Promise<AiChatResult> {
    const payload: Record<string, unknown> = {
      model: config.model,
      messages: messages.map((m) => ({ role: m.role, content: m.content })),
    };
    if (includeScheduleTools) {
      payload.tools = this.managementTools.map((tool) => ({
        type: 'function',
        function: {
          name: tool.name,
          description: tool.description,
          parameters: tool.input_schema,
        },
      }));
    }

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(this.timeoutMs),
    });

    const raw = await res.text();
    if (!res.ok) {
      const errMsg = this.parseErrorMessage(raw) ?? `HTTP ${res.status}`;
      throw new Error(`OpenAI 오류: ${errMsg}`);
    }

    const data = JSON.parse(raw);
    const choice = data.choices?.[0];
    const text = choice?.message?.content ?? '';
    const toolCall = choice?.message?.tool_calls?.[0];
    const usage = data.usage;

    return {
      text: text.trim(),
      inputTokens: usage?.prompt_tokens ?? 0,
      outputTokens: usage?.completion_tokens ?? 0,
      costUsd: this.calcCost(
        config.model,
        usage?.prompt_tokens ?? 0,
        usage?.completion_tokens ?? 0,
      ),
      toolCall: toolCall
        ? {
            name: toolCall.function?.name ?? '',
            id: toolCall.id ?? '',
            input: this.parseJsonObject(toolCall.function?.arguments),
          }
        : undefined,
    };
  }

  /* ───── Gemini ───── */

  /** Gemini REST용 `create_schedule` 도구 (functionDeclarations) */
  private geminiScheduleToolsPayload(): Record<string, unknown> {
    return {
      functionDeclarations: this.managementTools.map((tool) => ({
        name: tool.name,
        description: tool.description,
        parameters: tool.input_schema,
      })),
    };
  }

  private buildGeminiContents(
    messages: AiChatMessage[],
  ): {
    contents: Record<string, unknown>[];
    systemInstruction?: { parts: { text: string }[] };
  } {
    const systemMsg = messages.find((m) => m.role === 'system');
    const chatMsgs = messages.filter((m) => m.role !== 'system');
    const contents = chatMsgs.map((m) => ({
      role: m.role === 'assistant' ? 'model' : 'user',
      parts: [{ text: m.content }],
    }));
    return {
      contents,
      systemInstruction: systemMsg
        ? { parts: [{ text: systemMsg.content }] }
        : undefined,
    };
  }

  private geminiGenerateBody(
    contents: Record<string, unknown>[],
    systemInstruction?: { parts: { text: string }[] },
    includeScheduleTools = true,
  ): Record<string, unknown> {
    const body: Record<string, unknown> = { contents };
    if (systemInstruction) {
      body.systemInstruction = systemInstruction;
    }
    if (includeScheduleTools) {
      body.tools = [this.geminiScheduleToolsPayload()];
      body.toolConfig = {
        functionCallingConfig: {
          mode: 'AUTO',
        },
      };
    }
    return body;
  }

  /** functionResponse 전달 후 모델의 텍스트 응답만 사용 */
  private async callGeminiWithFunctionResponse(
    config: AiConfig,
    originalMessages: AiChatMessage[],
    functionCall: { id: string; name: string; args: Record<string, unknown> },
    toolResultPayload: Record<string, unknown>,
  ): Promise<AiChatResult> {
    const { contents, systemInstruction } =
      this.buildGeminiContents(originalMessages);

    const fcPart: Record<string, unknown> = {
      name: functionCall.name,
      args: functionCall.args,
    };
    if (functionCall.id) {
      fcPart.id = functionCall.id;
    }
    contents.push({
      role: 'model',
      parts: [{ functionCall: fcPart }],
    });

    const responseStruct = JSON.parse(
      JSON.stringify(toolResultPayload),
    ) as Record<string, unknown>;

    const frPart: Record<string, unknown> = {
      name: functionCall.name,
      response: responseStruct,
    };
    if (functionCall.id) {
      frPart.id = functionCall.id;
    }
    contents.push({
      role: 'user',
      parts: [{ functionResponse: frPart }],
    });

    const body = this.geminiGenerateBody(contents, systemInstruction);
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(this.timeoutMs),
    });

    const raw = await res.text();
    if (!res.ok) {
      const errMsg = this.parseErrorMessage(raw) ?? `HTTP ${res.status}`;
      throw new Error(`Gemini 오류: ${errMsg}`);
    }

    const data = JSON.parse(raw);
    const parts = data.candidates?.[0]?.content?.parts ?? [];
    let text = '';
    for (const p of parts as Record<string, unknown>[]) {
      if (typeof p?.text === 'string') {
        text += p.text as string;
      }
    }
    const meta = data.usageMetadata;

    return {
      text: text.trim(),
      inputTokens: meta?.promptTokenCount ?? 0,
      outputTokens: meta?.candidatesTokenCount ?? 0,
      costUsd: this.calcCost(
        config.model,
        meta?.promptTokenCount ?? 0,
        meta?.candidatesTokenCount ?? 0,
      ),
      provider: config.provider,
      model: config.model,
    };
  }

  private async callGemini(
    config: AiConfig,
    messages: AiChatMessage[],
    includeScheduleTools = true,
  ): Promise<AiChatResult> {
    const { contents, systemInstruction } = this.buildGeminiContents(messages);
    const body = this.geminiGenerateBody(
      contents,
      systemInstruction,
      includeScheduleTools,
    );

    const url = `https://generativelanguage.googleapis.com/v1beta/models/${config.model}:generateContent?key=${config.apiKey}`;
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(this.timeoutMs),
    });

    const raw = await res.text();
    if (!res.ok) {
      const errMsg = this.parseErrorMessage(raw) ?? `HTTP ${res.status}`;
      throw new Error(`Gemini 오류: ${errMsg}`);
    }

    const data = JSON.parse(raw);
    const parts = data.candidates?.[0]?.content?.parts ?? [];
    let text = '';
    let functionCall:
      | { name: string; args: Record<string, unknown>; id?: string }
      | undefined;
    for (const p of parts as Record<string, unknown>[]) {
      if (typeof p?.text === 'string') {
        text += p.text as string;
      }
      const fc = p?.functionCall as Record<string, unknown> | undefined;
      if (fc && typeof fc.name === 'string') {
        const rawArgs = fc.args;
        const args =
          rawArgs &&
          typeof rawArgs === 'object' &&
          !Array.isArray(rawArgs)
            ? (rawArgs as Record<string, unknown>)
            : {};
        functionCall = {
          name: fc.name,
          args,
          id: typeof fc.id === 'string' ? fc.id : undefined,
        };
      }
    }
    const meta = data.usageMetadata;

    return {
      text: text.trim(),
      inputTokens: meta?.promptTokenCount ?? 0,
      outputTokens: meta?.candidatesTokenCount ?? 0,
      costUsd: this.calcCost(
        config.model,
        meta?.promptTokenCount ?? 0,
        meta?.candidatesTokenCount ?? 0,
      ),
      toolCall:
        functionCall && this.managementToolNames.has(functionCall.name)
          ? {
              name: functionCall.name,
              id: functionCall.id ?? `gemini-fc-${Date.now()}`,
              input: functionCall.args,
            }
          : undefined,
    };
  }

  /* ───── 비용 계산 ───── */

  private calcCost(
    model: string,
    inputTokens: number,
    outputTokens: number,
  ): number {
    const p = MODEL_PRICING[model];
    if (!p) return 0;
    return (inputTokens * p.input + outputTokens * p.output) / 1_000_000;
  }

  /* ───── 사용량 기록 ───── */

  async recordUsage(
    userId: number,
    provider: string,
    model: string,
    inputTokens: number,
    outputTokens: number,
  ): Promise<void> {
    const costUsd = this.calcCost(model, inputTokens, outputTokens);
    const row = this.usageRepo.create({
      userId,
      provider,
      model,
      inputTokens,
      outputTokens,
      costUsd,
    });
    await this.usageRepo.save(row);
  }

  /* ───── 사용량 조회 ───── */

  async getUsageSummary(
    userId: number,
    days?: number,
  ): Promise<{
    totalCostUsd: number;
    totalInputTokens: number;
    totalOutputTokens: number;
    totalRequests: number;
    byProvider: Record<
      string,
      { costUsd: number; inputTokens: number; outputTokens: number; requests: number }
    >;
    byModel: Record<
      string,
      { costUsd: number; inputTokens: number; outputTokens: number; requests: number }
    >;
    daily: { date: string; costUsd: number; requests: number }[];
  }> {
    let qb = this.usageRepo
      .createQueryBuilder('u')
      .where('u.userId = :userId', { userId });

    if (days && days > 0) {
      const from = new Date();
      from.setDate(from.getDate() - days);
      qb = qb.andWhere('u.createdAt >= :from', { from: from.toISOString() });
    }

    const rows = await qb.orderBy('u.createdAt', 'ASC').getMany();

    let totalCostUsd = 0;
    let totalInputTokens = 0;
    let totalOutputTokens = 0;

    const byProvider: Record<
      string,
      { costUsd: number; inputTokens: number; outputTokens: number; requests: number }
    > = {};
    const byModel: Record<
      string,
      { costUsd: number; inputTokens: number; outputTokens: number; requests: number }
    > = {};
    const dailyMap: Record<string, { costUsd: number; requests: number }> = {};

    for (const r of rows) {
      totalCostUsd += r.costUsd;
      totalInputTokens += r.inputTokens;
      totalOutputTokens += r.outputTokens;

      if (!byProvider[r.provider]) {
        byProvider[r.provider] = {
          costUsd: 0,
          inputTokens: 0,
          outputTokens: 0,
          requests: 0,
        };
      }
      byProvider[r.provider].costUsd += r.costUsd;
      byProvider[r.provider].inputTokens += r.inputTokens;
      byProvider[r.provider].outputTokens += r.outputTokens;
      byProvider[r.provider].requests++;

      if (!byModel[r.model]) {
        byModel[r.model] = {
          costUsd: 0,
          inputTokens: 0,
          outputTokens: 0,
          requests: 0,
        };
      }
      byModel[r.model].costUsd += r.costUsd;
      byModel[r.model].inputTokens += r.inputTokens;
      byModel[r.model].outputTokens += r.outputTokens;
      byModel[r.model].requests++;

      const date = r.createdAt.toISOString().slice(0, 10);
      if (!dailyMap[date]) {
        dailyMap[date] = { costUsd: 0, requests: 0 };
      }
      dailyMap[date].costUsd += r.costUsd;
      dailyMap[date].requests++;
    }

    const daily = Object.entries(dailyMap)
      .map(([date, v]) => ({ date, ...v }))
      .sort((a, b) => a.date.localeCompare(b.date))
      .slice(-30);

    return {
      totalCostUsd,
      totalInputTokens,
      totalOutputTokens,
      totalRequests: rows.length,
      byProvider,
      byModel,
      daily,
    };
  }

  async clearUsage(userId: number): Promise<void> {
    await this.usageRepo.delete({ userId });
  }

  /** 프로바이더 · 모델 목록 */
  getProviders(): {
    provider: string;
    label: string;
    models: { id: string; name: string }[];
  }[] {
    return [
      {
        provider: 'claude',
        label: 'Anthropic Claude',
        models: [
          { id: 'claude-sonnet-4-20250514', name: 'Claude Sonnet 4' },
          { id: 'claude-opus-4-20250514', name: 'Claude Opus 4' },
          { id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5' },
        ],
      },
      {
        provider: 'openai',
        label: 'OpenAI (ChatGPT)',
        models: [
          { id: 'gpt-4o-mini', name: 'GPT-4o Mini' },
          { id: 'gpt-4o', name: 'GPT-4o' },
          { id: 'gpt-4-turbo', name: 'GPT-4 Turbo' },
          { id: 'o4-mini', name: 'o4-mini' },
        ],
      },
      {
        provider: 'gemini',
        label: 'Google Gemini',
        models: [
          { id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash' },
          { id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash' },
          { id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro' },
        ],
      },
    ];
  }

  /** 모델 가격표 */
  getPricing(): Record<string, { input: number; output: number }> {
    return { ...MODEL_PRICING };
  }

  /* ───── 설정 관리 ───── */

  async getAllConfigs(): Promise<AiConfig[]> {
    return this.configRepo.find({ order: { id: 'ASC' } });
  }

  async updateConfig(
    provider: string,
    model?: string,
    apiKey?: string,
  ): Promise<AiConfig> {
    await this.configRepo
      .createQueryBuilder()
      .update(AiConfig)
      .set({ isActive: false })
      .where('isActive = :v', { v: true })
      .execute();

    let config = await this.configRepo.findOne({ where: { provider } });
    if (!config) {
      config = this.configRepo.create({
        provider,
        model: model ?? DEFAULT_MODELS[provider] ?? '',
        apiKey: apiKey ?? '',
        isActive: true,
      });
    } else {
      config.isActive = true;
      if (model) config.model = model;
      if (apiKey) config.apiKey = apiKey;
    }
    return this.configRepo.save(config);
  }

  /* ───── helpers ───── */

  private parseErrorMessage(raw: string): string | null {
    try {
      const j = JSON.parse(raw);
      return j.error?.message ?? j.error ?? null;
    } catch {
      return raw.slice(0, 200);
    }
  }

  private parseJsonObject(raw: string | undefined): Record<string, unknown> {
    if (!raw) return {};
    try {
      const parsed: unknown = JSON.parse(raw);
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        return parsed as Record<string, unknown>;
      }
      return {};
    } catch {
      this.logger.warn('AI tool arguments JSON parse failed');
      return {};
    }
  }
}
