import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Between, FindOptionsWhere, Repository } from 'typeorm';
import { Diary } from './diary.entity';
import { CreateDiaryDto } from './dto/create-diary.dto';
import { UpdateDiaryDto } from './dto/update-diary.dto';
import { DiaryResponseDto } from './dto/diary-response.dto';
import { todayYmdKst } from '../schedule/schedule-datetime.util';

function scalarString(value: unknown): string {
  if (value == null) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return '';
}

const EXCERPT_MAX = 200;
const SEARCH_DEFAULT_LIMIT = 10;
const SEARCH_MAX_LIMIT = 20;
const RECENT_CONTEXT_DAYS = 14;
const RECENT_CONTEXT_MAX_ENTRIES = 50;

export type DiaryAiContextItem = {
  id: number;
  diaryDate: string;
  title: string | null;
  excerpt: string;
};

export type DiarySearchResultItem = {
  id: number;
  diaryDate: string;
  title: string | null;
  content: string;
  mood: string | null;
  diaryDateLabel?: string;
};

const DIARY_SEARCH_STOP_WORDS = new Set([
  '언제',
  '마지막',
  '마지막으로',
  '으로',
  '로',
  '를',
  '을',
  '가',
  '이',
  '는',
  '은',
  '에',
  '의',
  '도',
  '만',
  '했',
  '했더라',
  '했지',
  '먹었',
  '먹었더라',
  '먹었지',
  '기억',
  '기억나',
  '몇',
  '번',
  '뭐였',
  '더라',
  '지',
  '내가',
  '나는',
  '무엇',
  '어떻게',
  '왜',
  '어디',
  '누가',
  '언제였',
  '언젠지',
  '있었',
  '있었더라',
  '였',
  '였더라',
  '이었',
  'when',
  'last',
  'did',
  'the',
  'and',
]);

function escapeLikePattern(value: string): string {
  return value.replace(/[%_\\]/g, (ch) => `\\${ch}`);
}

function stripKoreanParticle(word: string): string {
  return word.replace(/(를|을|가|이|는|은|으로|로|에|의|도|만|라|야|요|죠|까)$/u, '');
}

function formatDiaryDateLabel(ymd: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(ymd);
  if (!match) return ymd;
  const month = Number(match[2]);
  const day = Number(match[3]);
  return `${month}월 ${day}일`;
}

function extractDiarySearchKeywords(query: string): string[] {
  const normalized = query.trim();
  if (!normalized) return [];

  const rawTokens = normalized.match(/[\p{L}\p{N}]{2,}/gu) ?? [];
  const keywords = new Set<string>();

  for (const token of rawTokens) {
    const lower = token.toLowerCase();
    if (DIARY_SEARCH_STOP_WORDS.has(lower)) continue;

    const stripped = stripKoreanParticle(lower);
    if (stripped.length >= 2 && !DIARY_SEARCH_STOP_WORDS.has(stripped)) {
      keywords.add(stripped);
    }
    if (lower.length >= 2) {
      keywords.add(lower);
    }
  }

  if (keywords.size === 0) {
    return [normalized];
  }

  return [...keywords].sort((a, b) => b.length - a.length);
}

@Injectable()
export class DiaryService {
  constructor(
    @InjectRepository(Diary)
    private readonly diaryRepo: Repository<Diary>,
  ) {}

  private toDto(row: Diary): DiaryResponseDto {
    return {
      id: row.id,
      userId: row.userId,
      diaryDate: row.diaryDate,
      title: row.title,
      content: row.content,
      mood: row.mood,
      inputSource: row.inputSource,
      originalText: row.originalText,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private excerpt(content: string): string {
    const t = content.trim();
    if (t.length <= EXCERPT_MAX) return t;
    return `${t.slice(0, EXCERPT_MAX)}…`;
  }

  private mergeContent(existing: string, addition: string): string {
    const a = existing.trim();
    const b = addition.trim();
    if (!a) return b;
    if (!b) return a;
    if (a.includes(b)) return a;
    return `${a}\n\n${b}`;
  }

  async findAll(
    userId: number,
    from?: string,
    to?: string,
  ): Promise<DiaryResponseDto[]> {
    const where: FindOptionsWhere<Diary> = { user: { id: userId } };

    if (from && to) {
      where.diaryDate = Between(from, to);
    } else if (from) {
      where.diaryDate = Between(from, '9999-12-31');
    } else if (to) {
      where.diaryDate = Between('0001-01-01', to);
    }

    const rows = await this.diaryRepo.find({
      where,
      order: { diaryDate: 'DESC', id: 'DESC' },
    });
    return rows.map((r) => this.toDto(r));
  }

  async findOne(id: number, userId: number): Promise<DiaryResponseDto> {
    const row = await this.diaryRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일기를 찾을 수 없습니다');
    }
    return this.toDto(row);
  }

  async create(userId: number, dto: CreateDiaryDto): Promise<DiaryResponseDto> {
    const diaryDate = dto.diaryDate.trim();
    const content = dto.content.trim();

    const row = this.diaryRepo.create({
      diaryDate,
      title: dto.title?.trim() ?? null,
      content,
      mood: dto.mood?.trim() ?? null,
      inputSource: dto.inputSource ?? 'MANUAL',
      originalText: dto.originalText ?? null,
      user: { id: userId },
    });
    const saved = await this.diaryRepo.save(row);
    return this.toDto(saved);
  }

  async update(
    id: number,
    userId: number,
    dto: UpdateDiaryDto,
  ): Promise<DiaryResponseDto> {
    const row = await this.diaryRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일기를 찾을 수 없습니다');
    }

    if (dto.title !== undefined) row.title = dto.title?.trim() ?? null;
    if (dto.content !== undefined) row.content = dto.content.trim();
    if (dto.mood !== undefined) row.mood = dto.mood?.trim() ?? null;
    if (dto.inputSource !== undefined) row.inputSource = dto.inputSource;
    if (dto.originalText !== undefined) row.originalText = dto.originalText;

    const saved = await this.diaryRepo.save(row);
    return this.toDto(saved);
  }

  async remove(id: number, userId: number): Promise<void> {
    const row = await this.diaryRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('일기를 찾을 수 없습니다');
    }
    await this.diaryRepo.remove(row);
  }

  async findRecentForAiContext(
    userId: number,
    days = RECENT_CONTEXT_DAYS,
  ): Promise<DiaryAiContextItem[]> {
    const to = todayYmdKst();
    const fromDate = new Date(`${to}T12:00:00+09:00`);
    fromDate.setDate(fromDate.getDate() - (days - 1));
    const from = fromDate.toLocaleDateString('en-CA', {
      timeZone: 'Asia/Seoul',
    });

    const rows = await this.diaryRepo.find({
      where: {
        user: { id: userId },
        diaryDate: Between(from, to),
      },
      order: { diaryDate: 'DESC', id: 'DESC' },
      take: RECENT_CONTEXT_MAX_ENTRIES,
    });

    return rows.map((r) => ({
      id: r.id,
      diaryDate: r.diaryDate,
      title: r.title,
      excerpt: this.excerpt(r.content),
    }));
  }

  async searchForAi(
    userId: number,
    options: {
      query: string;
      dateFrom?: string;
      dateTo?: string;
      limit?: number;
    },
  ): Promise<{ items: DiarySearchResultItem[]; searchTerms: string[] }> {
    const q = options.query.trim();
    if (!q) return { items: [], searchTerms: [] };

    let limit = options.limit ?? SEARCH_DEFAULT_LIMIT;
    if (!Number.isFinite(limit) || limit < 1) {
      limit = SEARCH_DEFAULT_LIMIT;
    }
    limit = Math.min(limit, SEARCH_MAX_LIMIT);

    const searchTerms = extractDiarySearchKeywords(q);
    const candidates = [q, ...searchTerms.filter((term) => term !== q)];

    for (const term of candidates) {
      const items = await this.searchDiariesByTerm(userId, term, {
        dateFrom: options.dateFrom,
        dateTo: options.dateTo,
        limit,
      });
      if (items.length > 0) {
        return { items, searchTerms };
      }
    }

    return { items: [], searchTerms };
  }

  private async searchDiariesByTerm(
    userId: number,
    term: string,
    options: {
      dateFrom?: string;
      dateTo?: string;
      limit: number;
    },
  ): Promise<DiarySearchResultItem[]> {
    const qb = this.diaryRepo
      .createQueryBuilder('d')
      .where('d.user_id = :userId', { userId })
      .andWhere('(d.content LIKE :pat ESCAPE \'\\\\\' OR d.title LIKE :pat ESCAPE \'\\\\\')', {
        pat: `%${escapeLikePattern(term)}%`,
      });

    if (options.dateFrom && /^\d{4}-\d{2}-\d{2}$/.test(options.dateFrom)) {
      qb.andWhere('d.diary_date >= :dateFrom', { dateFrom: options.dateFrom });
    }
    if (options.dateTo && /^\d{4}-\d{2}-\d{2}$/.test(options.dateTo)) {
      qb.andWhere('d.diary_date <= :dateTo', { dateTo: options.dateTo });
    }

    const rows = await qb
      .orderBy('d.diary_date', 'DESC')
      .addOrderBy('d.id', 'DESC')
      .take(options.limit)
      .getMany();

    return rows.map((r) => ({
      id: r.id,
      diaryDate: r.diaryDate,
      diaryDateLabel: formatDiaryDateLabel(r.diaryDate),
      title: r.title,
      content: r.content,
      mood: r.mood,
    }));
  }

  async createFromAiToolInput(
    userId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; diary: DiaryResponseDto }
    | { ok: false; error: string }
  > {
    try {
      const content = scalarString(input.content).trim();
      if (!content) {
        return { ok: false, error: 'content가 필요합니다.' };
      }

      let diaryDate = scalarString(input.diaryDate).trim();
      if (!diaryDate) {
        diaryDate = scalarString(input.date).trim();
      }
      if (!diaryDate || !/^\d{4}-\d{2}-\d{2}$/.test(diaryDate)) {
        diaryDate = todayYmdKst();
      }

      const title = scalarString(input.title).trim() || undefined;
      const mood = scalarString(input.mood).trim() || undefined;

      const diary = await this.create(userId, {
        diaryDate,
        title,
        content,
        mood,
        inputSource: 'AI',
        originalText: originalChat,
      });

      return { ok: true, diary };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '일기 저장에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  async updateFromAiToolInput(
    userId: number,
    diaryId: number,
    input: Record<string, unknown>,
    originalChat: string,
  ): Promise<
    | { ok: true; diary: DiaryResponseDto }
    | { ok: false; error: string }
  > {
    try {
      const row = await this.diaryRepo.findOne({
        where: { id: diaryId, user: { id: userId } },
      });
      if (!row) {
        return { ok: false, error: '일기를 찾을 수 없습니다.' };
      }

      const append = scalarString(input.content).trim();
      const title = scalarString(input.title).trim();
      const mood = scalarString(input.mood).trim();

      if (append) {
        row.content = this.mergeContent(row.content, append);
      }
      if (title) row.title = title;
      if (mood) row.mood = mood;
      row.inputSource = 'AI';
      row.originalText = originalChat;

      const saved = await this.diaryRepo.save(row);
      return { ok: true, diary: this.toDto(saved) };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '일기 수정에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }

  async searchFromAiToolInput(
    userId: number,
    input: Record<string, unknown>,
  ): Promise<
    | {
        ok: true;
        items: DiarySearchResultItem[];
        query: string;
        searchTerms: string[];
        latestMatch: DiarySearchResultItem | null;
      }
    | { ok: false; error: string }
  > {
    try {
      const query = scalarString(input.query).trim();
      if (!query) {
        return { ok: false, error: 'query가 필요합니다.' };
      }

      const dateFrom = scalarString(input.dateFrom).trim() || undefined;
      const dateTo = scalarString(input.dateTo).trim() || undefined;
      const limitRaw = input.limit;
      const limit =
        typeof limitRaw === 'number' && Number.isFinite(limitRaw)
          ? limitRaw
          : Number(String(limitRaw ?? '').trim()) || undefined;

      const { items, searchTerms } = await this.searchForAi(userId, {
        query,
        dateFrom,
        dateTo,
        limit,
      });

      return {
        ok: true,
        items,
        query,
        searchTerms,
        latestMatch: items[0] ?? null,
      };
    } catch (e: unknown) {
      const msg =
        e instanceof Error
          ? e.message
          : typeof e === 'string'
            ? e
            : '일기 검색에 실패했습니다.';
      return { ok: false, error: msg };
    }
  }
}
