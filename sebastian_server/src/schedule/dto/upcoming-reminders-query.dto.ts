import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';

export class UpcomingRemindersQueryDto {
  @ApiPropertyOptional({
    description: '지금부터 몇 시간 이내 시작 일정 (기본 24)',
    default: 24,
    minimum: 1,
    maximum: 168,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(168)
  withinHours?: number;
}
