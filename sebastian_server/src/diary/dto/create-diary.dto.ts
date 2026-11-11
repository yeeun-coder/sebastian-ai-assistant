import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsDateString,
  IsOptional,
  IsIn,
} from 'class-validator';

export class CreateDiaryDto {
  @ApiProperty({ example: '2026-06-01', description: '기록 대상 날 (YYYY-MM-DD)' })
  @IsDateString()
  diaryDate: string;

  @ApiPropertyOptional({ example: '맛있는 하루' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @ApiProperty({ example: '오늘 떡볶이를 먹었다.' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(50000)
  content: string;

  @ApiPropertyOptional({ example: '좋음' })
  @IsOptional()
  @IsString()
  @MaxLength(30)
  mood?: string;

  @ApiPropertyOptional({ example: 'MANUAL', enum: ['AI', 'MANUAL'] })
  @IsOptional()
  @IsIn(['AI', 'MANUAL'])
  inputSource?: 'AI' | 'MANUAL';

  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  @IsString()
  originalText?: string | null;
}
