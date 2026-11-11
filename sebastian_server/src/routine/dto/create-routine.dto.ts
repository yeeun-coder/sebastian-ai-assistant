import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { RoutineRepeatInterval } from '../routine-repeat-interval.enum';

function effectiveInterval(o: {
  repeatInterval?: RoutineRepeatInterval;
}): RoutineRepeatInterval {
  return o.repeatInterval ?? RoutineRepeatInterval.WEEKLY;
}

export class CreateRoutineDto {
  @ApiProperty({ example: '영양제 복용', description: '루틴 폴더명' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  category: string;

  @ApiProperty({ example: '유산균' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  title: string;

  @ApiProperty({ example: '09:00', description: '알람 시각 HH:mm' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{1,2}:\d{2}$/)
  targetTime: string;

  @ApiPropertyOptional({
    enum: RoutineRepeatInterval,
    example: RoutineRepeatInterval.WEEKLY,
    description:
      '생략 시 WEEKLY. DAILY: 추가 필드 없음. WEEKLY/BIWEEKLY: repeatDays 필수. MONTHLY: repeatDayOfMonth. YEARLY: repeatMonth+repeatDayOfMonth',
  })
  @IsOptional()
  @IsEnum(RoutineRepeatInterval)
  repeatInterval?: RoutineRepeatInterval;

  @ApiPropertyOptional({
    example: 'MON,TUE,WED',
    description: 'WEEKLY·BIWEEKLY만: 반복 요일 (쉼표 구분)',
  })
  @ValidateIf(
    (o) =>
      effectiveInterval(o) === RoutineRepeatInterval.WEEKLY ||
      effectiveInterval(o) === RoutineRepeatInterval.BIWEEKLY,
  )
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  repeatDays?: string;

  @ApiPropertyOptional({
    example: 14,
    description: 'MONTHLY 또는 YEARLY: 매달 같은 날 (1–31)',
  })
  @ValidateIf(
    (o) =>
      effectiveInterval(o) === RoutineRepeatInterval.MONTHLY ||
      effectiveInterval(o) === RoutineRepeatInterval.YEARLY,
  )
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(31)
  repeatDayOfMonth?: number;

  @ApiPropertyOptional({
    example: 3,
    description: 'YEARLY만: 월 (1–12)',
  })
  @ValidateIf((o) => effectiveInterval(o) === RoutineRepeatInterval.YEARLY)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(12)
  repeatMonth?: number;

  @ApiPropertyOptional({
    example: '2026-01-06',
    description:
      'BIWEEKLY: 격주 기준일 YYYY-MM-DD (생략 시 서버 오늘 날짜)',
  })
  @ValidateIf((o) => effectiveInterval(o) === RoutineRepeatInterval.BIWEEKLY)
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  biweeklyAnchorDate?: string;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
