import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsIn,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { INPUT_SOURCE_AI, INPUT_SOURCE_MANUAL } from '../schedule.entity';
import { ScheduleDdayDateBasis } from '../schedule-dday-date-basis.enum';

export class CreateScheduleDto {
  @ApiProperty({ example: '팀 미팅' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  title: string;

  @ApiPropertyOptional({ example: '회의실 A' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ description: 'AI 등록 시 사용자 채팅 원문' })
  @IsOptional()
  @IsString()
  originalText?: string;

  @ApiProperty({ example: '2026-04-10T09:00:00.000Z' })
  @IsString()
  @IsNotEmpty()
  startDate: string;

  @ApiProperty({ example: '2026-04-10T10:00:00.000Z' })
  @IsString()
  @IsNotEmpty()
  endDate: string;

  @ApiPropertyOptional({ example: '회의' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string;

  @ApiPropertyOptional({
    example: 2,
    description: '우선순위 (1=높음, 2=보통, 3=낮음, 생략 시 2)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(3)
  priority?: number;

  @ApiPropertyOptional({
    enum: [INPUT_SOURCE_AI, INPUT_SOURCE_MANUAL],
    default: INPUT_SOURCE_MANUAL,
    description: '생략 시 수동',
  })
  @IsOptional()
  @IsString()
  @IsIn([INPUT_SOURCE_AI, INPUT_SOURCE_MANUAL])
  inputSource?: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  isCompleted?: boolean;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isAlarmOn?: boolean;

  @ApiPropertyOptional({
    default: false,
    description: '중요 표시 여부',
  })
  @IsOptional()
  @IsBoolean()
  isImportant?: boolean;

  @ApiPropertyOptional({
    example: 30,
    description: '일정 시작 몇 분 전 알림 (1–10080, 생략 시 30)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(10080)
  notificationLeadMinutes?: number;

  @ApiPropertyOptional({
    default: false,
    description: 'true이면 일정과 함께 D-Day를 생성합니다.',
  })
  @IsOptional()
  @IsBoolean()
  createDday?: boolean;

  @ApiPropertyOptional({
    enum: ScheduleDdayDateBasis,
    default: ScheduleDdayDateBasis.START,
    description: 'D-Day 목표일 기준 (createDday가 true일 때)',
  })
  @IsOptional()
  @IsString()
  @IsIn([ScheduleDdayDateBasis.START, ScheduleDdayDateBasis.END])
  ddayDateBasis?: ScheduleDdayDateBasis;
}
