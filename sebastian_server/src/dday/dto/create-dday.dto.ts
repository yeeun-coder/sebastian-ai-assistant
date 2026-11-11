import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsDateString,
  IsOptional,
  IsBoolean,
  IsIn,
} from 'class-validator';
import { DDayCountMode } from '../dday-count-mode.enum';

export class CreateDDayDto {
  @ApiProperty({ example: '수능' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title: string;

  @ApiProperty({ example: '2026-11-19' })
  @IsDateString()
  targetDate: string;

  @ApiPropertyOptional({ example: '시험' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  category?: string;

  @ApiPropertyOptional({ example: '화이팅!' })
  @IsOptional()
  @IsString()
  memo?: string;

  @ApiPropertyOptional({ example: '#FF5252' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  color?: string;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  isPinned?: boolean;

  @ApiPropertyOptional({
    example: DDayCountMode.DOWN,
    enum: DDayCountMode,
    description: 'down: 목표일까지 남은 날, up: 목표일 이후 경과 일',
  })
  @IsOptional()
  @IsIn([DDayCountMode.DOWN, DDayCountMode.UP])
  countMode?: DDayCountMode;

  @ApiPropertyOptional({ example: 'MANUAL', enum: ['AI', 'MANUAL'] })
  @IsOptional()
  @IsIn(['AI', 'MANUAL'])
  inputSource?: 'AI' | 'MANUAL';

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  originalText?: string | null;
}
