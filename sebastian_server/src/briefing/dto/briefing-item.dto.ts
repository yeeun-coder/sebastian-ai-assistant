import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type BriefingItemType = 'schedule' | 'todo' | 'routine';

export class BriefingItemDto {
  @ApiProperty({ enum: ['schedule', 'todo', 'routine'] })
  type: BriefingItemType;

  @ApiProperty()
  id: number;

  @ApiProperty()
  title: string;

  @ApiProperty({ example: '일정' })
  subTitle: string;

  @ApiProperty({
    example: '오후 2:30',
    description: '표시용 시간 또는 "하루 종일"',
  })
  time: string;

  @ApiProperty({
    example: '1430',
    description: '목록 정렬용 키',
  })
  sortKey: string;

  @ApiPropertyOptional({
    description: '완료 시각 ISO8601 (completedToday 항목)',
    nullable: true,
  })
  completedAt?: string | null;
}
