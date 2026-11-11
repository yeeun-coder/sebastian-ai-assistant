import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class ScheduleListQueryDto {
  @ApiPropertyOptional({ description: '구간 시작 (ISO 문자열)' })
  @IsOptional()
  @IsString()
  from?: string;

  @ApiPropertyOptional({
    description: '구간 끝 (ISO 문자열) — from과 함께 사용',
  })
  @IsOptional()
  @IsString()
  to?: string;

  @ApiPropertyOptional({ default: 1, minimum: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ default: 50, minimum: 1, maximum: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number;
}
