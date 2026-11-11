import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional } from 'class-validator';

export class DiaryListQueryDto {
  @ApiPropertyOptional({
    example: '2026-06-01',
    description: '조회 시작일 (YYYY-MM-DD, inclusive)',
  })
  @IsOptional()
  @IsDateString()
  from?: string;

  @ApiPropertyOptional({
    example: '2026-06-30',
    description: '조회 종료일 (YYYY-MM-DD, inclusive)',
  })
  @IsOptional()
  @IsDateString()
  to?: string;
}
