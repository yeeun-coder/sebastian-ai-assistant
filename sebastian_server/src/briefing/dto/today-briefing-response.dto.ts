import { ApiProperty } from '@nestjs/swagger';
import { BriefingItemDto } from './briefing-item.dto';

export class TodayBriefingResponseDto {
  @ApiProperty({ example: '2026-06-01', description: 'KST 기준 오늘' })
  date: string;

  @ApiProperty({
    type: [BriefingItemDto],
    description: '오늘 남은 일정·To-Do·루틴',
  })
  upcoming: BriefingItemDto[];

  @ApiProperty({
    type: [BriefingItemDto],
    description: '오늘 체크 완료한 일정·To-Do·루틴',
  })
  completedToday: BriefingItemDto[];
}
