import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DiaryResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty({ example: '2026-06-01' })
  diaryDate: string;

  @ApiPropertyOptional({ nullable: true })
  title: string | null;

  @ApiProperty()
  content: string;

  @ApiPropertyOptional({ nullable: true })
  mood: string | null;

  @ApiProperty({ enum: ['AI', 'MANUAL'] })
  inputSource: 'AI' | 'MANUAL';

  @ApiPropertyOptional({ nullable: true })
  originalText: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
