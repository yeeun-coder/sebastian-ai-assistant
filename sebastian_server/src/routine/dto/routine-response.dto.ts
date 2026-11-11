import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { RoutineRepeatInterval } from '../routine-repeat-interval.enum';

export class RoutineResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty({ description: '루틴 폴더명' })
  category: string;

  @ApiProperty()
  title: string;

  @ApiProperty({ example: '09:00' })
  targetTime: string;

  @ApiProperty({ enum: RoutineRepeatInterval })
  repeatInterval: RoutineRepeatInterval;

  @ApiProperty({
    example: 'MON,TUE,WED',
    description: 'WEEKLY·BIWEEKLY일 때 요일. DAILY·MONTHLY·YEARLY는 빈 문자열',
  })
  repeatDays: string;

  @ApiPropertyOptional({
    example: 14,
    description: 'MONTHLY·YEARLY: 일(1–31)',
  })
  repeatDayOfMonth: number | null;

  @ApiPropertyOptional({
    example: 3,
    description: 'YEARLY: 월(1–12)',
  })
  repeatMonth: number | null;

  @ApiPropertyOptional({
    example: '2026-01-06',
    description: 'BIWEEKLY: 격주 기준일',
  })
  biweeklyAnchorDate: string | null;

  @ApiProperty()
  isActive: boolean;
}
