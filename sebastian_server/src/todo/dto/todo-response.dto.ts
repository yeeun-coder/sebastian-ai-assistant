import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class TodoResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional({ nullable: true })
  content: string | null;

  @ApiProperty({ example: 2, description: '우선순위 (1: 높음, 2: 보통, 3: 낮음)' })
  priority: number;

  @ApiPropertyOptional({ nullable: true, example: '건강' })
  category: string | null;

  @ApiProperty({ example: 'MANUAL', enum: ['AI', 'MANUAL'] })
  inputSource: 'AI' | 'MANUAL';

  @ApiPropertyOptional({ nullable: true, description: 'AI 입력 시 원문. 수동 입력 시 null' })
  originalText: string | null;

  @ApiProperty()
  isDone: boolean;

  @ApiPropertyOptional({ nullable: true })
  dueDate: string | null;

  @ApiProperty({
    description:
      '마감일 기준 며칠 전부터 일정에 표시할지. 0은 미선택(선행 표시 없음).',
    example: 3,
  })
  scheduleLeadDays: number;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional({ nullable: true })
  completedAt: Date | null;
}
