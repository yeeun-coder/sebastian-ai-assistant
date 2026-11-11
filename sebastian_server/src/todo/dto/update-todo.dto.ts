import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsBoolean,
  IsDateString,
  IsOptional,
  MaxLength,
  IsInt,
  Min,
  Max,
  IsIn,
} from 'class-validator';

export class UpdateTodoDto {
  @ApiPropertyOptional({ example: '물 두 잔 마시기' })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  title?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isDone?: boolean;

  @ApiPropertyOptional({ example: '하루 2L 목표', nullable: true })
  @IsOptional()
  @IsString()
  content?: string | null;

  @ApiPropertyOptional({ example: 1, description: '우선순위 (1: 높음, 2: 보통, 3: 낮음)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(3)
  priority?: number;

  @ApiPropertyOptional({ example: '건강', nullable: true })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string | null;

  @ApiPropertyOptional({ example: 'AI', enum: ['AI', 'MANUAL'] })
  @IsOptional()
  @IsString()
  @IsIn(['AI', 'MANUAL'])
  inputSource?: 'AI' | 'MANUAL';

  @ApiPropertyOptional({
    example: '내일 아침 스트레칭 루틴 추가',
    description: 'AI 입력 시 원문. 수동 입력 시 null',
    nullable: true,
  })
  @IsOptional()
  @IsString()
  originalText?: string | null;

  @ApiPropertyOptional({ example: '2026-04-20', nullable: true })
  @IsOptional()
  @IsDateString()
  dueDate?: string | null;

  @ApiPropertyOptional({ example: '2026-04-20T09:00:00.000Z', nullable: true })
  @IsOptional()
  @IsDateString()
  completedAt?: string | null;

  @ApiPropertyOptional({
    example: 3,
    description:
      '마감일 기준 며칠 전부터 일정에 표시할지. 0은 미선택(선행 표시 없음).',
  })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(365)
  scheduleLeadDays?: number;
}
