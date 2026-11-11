import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DDay } from './dday.entity';
import { CreateDDayDto } from './dto/create-dday.dto';
import { UpdateDDayDto } from './dto/update-dday.dto';
import { DDayResponseDto } from './dto/dday-response.dto';
import { DDayCountMode } from './dday-count-mode.enum';
import { computeDDayMetrics } from './dday-date.util';

@Injectable()
export class DDayService {
  constructor(
    @InjectRepository(DDay)
    private readonly ddayRepo: Repository<DDay>,
  ) {}

  private toDto(row: DDay): DDayResponseDto {
    const { daysLeft, label } = computeDDayMetrics(
      row.targetDate,
      row.countMode ?? DDayCountMode.DOWN,
    );

    return {
      id: row.id,
      userId: row.userId,
      title: row.title,
      targetDate: row.targetDate,
      category: row.category,
      memo: row.memo,
      color: row.color,
      isPinned: row.isPinned,
      countMode: row.countMode ?? DDayCountMode.DOWN,
      inputSource: row.inputSource,
      originalText: row.originalText,
      createdAt: row.createdAt,
      daysLeft,
      label,
    };
  }

  async findAll(
    userId: number,
    pinnedOnly?: boolean,
  ): Promise<DDayResponseDto[]> {
    const rows = await this.ddayRepo.find({
      where: {
        user: { id: userId },
        ...(pinnedOnly ? { isPinned: true } : {}),
      },
      order: { isPinned: 'DESC', targetDate: 'ASC', id: 'ASC' },
    });
    return rows.map((r) => this.toDto(r));
  }

  async findOne(id: number, userId: number): Promise<DDayResponseDto> {
    const row = await this.ddayRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('D-Day를 찾을 수 없습니다');
    }
    return this.toDto(row);
  }

  async create(userId: number, dto: CreateDDayDto): Promise<DDayResponseDto> {
    const row = this.ddayRepo.create({
      title: dto.title.trim(),
      targetDate: dto.targetDate,
      category: dto.category?.trim() ?? null,
      memo: dto.memo?.trim() ?? null,
      color: dto.color?.trim() ?? null,
      isPinned: dto.isPinned ?? false,
      countMode: dto.countMode ?? DDayCountMode.DOWN,
      inputSource: dto.inputSource ?? 'MANUAL',
      originalText: dto.originalText ?? null,
      user: { id: userId },
    });
    const saved = await this.ddayRepo.save(row);
    return this.toDto(saved);
  }

  async update(
    id: number,
    userId: number,
    dto: UpdateDDayDto,
  ): Promise<DDayResponseDto> {
    const row = await this.ddayRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('D-Day를 찾을 수 없습니다');
    }

    if (dto.title !== undefined) row.title = dto.title.trim();
    if (dto.targetDate !== undefined) row.targetDate = dto.targetDate;
    if (dto.category !== undefined) {
      row.category = dto.category?.trim() ?? null;
    }
    if (dto.memo !== undefined) row.memo = dto.memo?.trim() ?? null;
    if (dto.color !== undefined) row.color = dto.color?.trim() ?? null;
    if (dto.isPinned !== undefined) row.isPinned = dto.isPinned;
    if (dto.countMode !== undefined) row.countMode = dto.countMode;
    if (dto.inputSource !== undefined) row.inputSource = dto.inputSource;
    if (dto.originalText !== undefined) row.originalText = dto.originalText;

    const saved = await this.ddayRepo.save(row);
    return this.toDto(saved);
  }

  async remove(id: number, userId: number): Promise<void> {
    const row = await this.ddayRepo.findOne({
      where: { id, user: { id: userId } },
    });
    if (!row) {
      throw new NotFoundException('D-Day를 찾을 수 없습니다');
    }
    await this.ddayRepo.remove(row);
  }
}
