import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessages } from '../chat/chat_messages.entity';
import { AiProviderService, AiChatMessage } from '../ai/ai-provider.service';
import { User } from './user.entity';

const TAG_COUNT = 5;

function buildAnalysisSystemPrompt(): string {
  return `당신은 사용자 대화만 보고 성향 태그를 뽑는 분석기입니다.
아래에 주어지는 것은 사용자와 AI 비서 사이의 최근 대화 로그입니다.
대화 톤·관심사·표현 방식을 바탕으로 이 사용자를 나타내는 짧은 한국어 태그를 정확히 ${TAG_COUNT}개만 제시하세요.

반드시 이런 형식의 JSON만 출력하세요. 다른 문장·마크다운·코드 펜스는 쓰지 마세요.
{"tags":["태그1","태그2","태그3","태그4","태그5"]}

조건:
- 각 태그는 2~12자 정도의 한국어 명사형·형용사형
- 비방·민감 추측(질병·정치 성향 등)은 피하고, 대화에서 드러난 특성 위주`;
}

@Injectable()
export class PersonalityTagsService {
  private readonly logger = new Logger(PersonalityTagsService.name);

  constructor(
    @InjectRepository(ChatMessages)
    private readonly chatRepo: Repository<ChatMessages>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly ai: AiProviderService,
    private readonly config: ConfigService,
  ) {}

  /**
   * 홈 채팅 일부를 읽어 성향 태그 TAG_COUNT개를 생성하고 `users.tags`에 저장합니다.
   */
  async analyzeFromChatAndSave(userId: number): Promise<string[]> {
    const maxRaw = this.config.get<string>('USER_TAGS_MAX_MESSAGES') ?? '80';
    const maxHistory = Number(maxRaw);
    const cap =
      Number.isFinite(maxHistory) && maxHistory > 0 ? maxHistory : 80;

    const rows = await this.chatRepo.find({
      where: { userId },
      order: { createdAt: 'ASC' },
    });
    const filtered = rows.filter(
      (r) => r.senderRole === 'user' || r.senderRole === 'assistant',
    );
    const context = filtered.slice(-cap);

    const userLines = context.filter((r) => r.senderRole === 'user').length;
    if (userLines < 2 || context.length < 4) {
      throw new BadRequestException(
        '태그를 만들기에 대화가 부족합니다. 홈에서 조금 더 대화한 뒤 다시 시도해 주세요.',
      );
    }

    const transcript = context
      .map((r) =>
        r.senderRole === 'user'
          ? `사용자: ${r.message}`
          : `AI: ${r.message}`,
      )
      .join('\n');

    const messages: AiChatMessage[] = [
      { role: 'system', content: buildAnalysisSystemPrompt() },
      {
        role: 'user',
        content: `다음은 대화 로그입니다.\n\n${transcript}`,
      },
    ];

    let text: string;
    try {
      const result = await this.ai.chat(messages, userId, {
        includeScheduleTools: false,
      });
      text = result.text;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      this.logger.warn(`AI 태그 분석 실패: ${msg}`);
      throw new BadRequestException(msg);
    }

    const tags = this.parseTagsJson(text);

    const user = await this.userRepo.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('사용자를 찾을 수 없습니다');
    }
    user.tags = tags;
    await this.userRepo.save(user);

    return tags;
  }

  private parseTagsJson(text: string): string[] {
    let t = text.trim();
    const fence = /^```(?:json)?\s*([\s\S]*?)```/im;
    const m = t.match(fence);
    if (m) {
      t = m[1].trim();
    }

    let obj: unknown;
    try {
      obj = JSON.parse(t);
    } catch {
      const start = t.indexOf('{');
      const end = t.lastIndexOf('}');
      if (start >= 0 && end > start) {
        try {
          obj = JSON.parse(t.slice(start, end + 1));
        } catch {
          throw new BadRequestException('AI 응답을 JSON으로 읽을 수 없습니다.');
        }
      } else {
        throw new BadRequestException('AI 응답을 JSON으로 읽을 수 없습니다.');
      }
    }

    const rawTags = (obj as { tags?: unknown }).tags;
    if (!Array.isArray(rawTags)) {
      throw new BadRequestException('AI 응답에 tags 배열이 없습니다.');
    }

    const strings = rawTags
      .filter((x): x is string => typeof x === 'string')
      .map((s) => s.trim())
      .filter((s) => s.length > 0);

    if (strings.length < TAG_COUNT) {
      throw new BadRequestException(
        `태그가 ${TAG_COUNT}개가 아닙니다. 다시 시도해 주세요.`,
      );
    }

    const out = strings.slice(0, TAG_COUNT);
    for (const s of out) {
      if (s.length > 32) {
        throw new BadRequestException('태그 한 항목이 너무 깁니다.');
      }
    }
    return out;
  }
}
