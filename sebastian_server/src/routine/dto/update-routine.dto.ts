import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';
import { RoutineRepeatInterval } from '../routine-repeat-interval.enum';

export class UpdateRoutineDto {
  @ApiPropertyOptional({ example: '영양제 복용' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  category?: string;

  @ApiPropertyOptional({ example: '유산균' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  title?: string;

  @ApiPropertyOptional({ example: '09:00' })
  @IsOptional()
  @IsString()
  @Matches(/^\d{1,2}:\d{2}$/)
  targetTime?: string;

  @ApiPropertyOptional({ enum: RoutineRepeatInterval })
  @IsOptional()
  @IsEnum(RoutineRepeatInterval)
  repeatInterval?: RoutineRepeatInterval;

  @ApiPropertyOptional({ example: 'MON,TUE,WED' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  repeatDays?: string;

  @ApiPropertyOptional({ example: 14, description: '1–31' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(31)
  repeatDayOfMonth?: number;

  @ApiPropertyOptional({ example: 3, description: '1–12, YEARLY' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(12)
  repeatMonth?: number;

  @ApiPropertyOptional({ example: '2026-01-06' })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  biweeklyAnchorDate?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
