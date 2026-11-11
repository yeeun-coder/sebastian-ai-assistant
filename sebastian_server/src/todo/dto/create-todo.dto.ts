import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsDateString,
  IsOptional,
  IsInt,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export class CreateTodoDto {
  @ApiProperty({ example: '물 마시기' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  title: string;

  @ApiPropertyOptional({ example: '2026-04-20' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ example: '하루 2L 목표' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: 1, default: 2, description: '우선순위 (1: 높음, 2: 보통, 3: 낮음)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  priority?: number;

  @ApiPropertyOptional({ example: '건강' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string;

  @ApiPropertyOptional({ example: 'MANUAL', enum: ['AI', 'MANUAL'], default: 'MANUAL' })
  @IsOptional()
  @IsString()
  @IsIn(['AI', 'MANUAL'])
  inputSource?: 'AI' | 'MANUAL';

  @ApiPropertyOptional({
    example: '오늘 물 3잔 마시기',
    description: 'AI 입력 시 원문. 수동 입력 시 null',
    nullable: true,
  })
  @IsOptional()
  @IsString()
  originalText?: string | null;

  @ApiPropertyOptional({
    example: 3,
    default: 0,
    description:
      '마감일 기준 며칠 전부터 일정에 표시할지. 0은 미선택(선행 표시 없음).',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  scheduleLeadDays?: number;
}
