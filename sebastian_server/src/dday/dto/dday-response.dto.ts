import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DDayCountMode } from '../dday-count-mode.enum';

export class DDayResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty()
  title: string;

  @ApiProperty({ example: '2026-11-19' })
  targetDate: string;

  @ApiPropertyOptional({ nullable: true })
  category: string | null;

  @ApiPropertyOptional({ nullable: true })
  memo: string | null;

  @ApiPropertyOptional({ nullable: true })
  color: string | null;

  @ApiProperty()
  isPinned: boolean;

  @ApiProperty({ enum: DDayCountMode })
  countMode: DDayCountMode;

  @ApiProperty({ enum: ['AI', 'MANUAL'] })
  inputSource: 'AI' | 'MANUAL';

  @ApiPropertyOptional({ nullable: true })
  originalText: string | null;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty({ example: 178, description: '양수: 남은/경과 일, 0: D-Day, 음수: 반대 방향' })
  daysLeft: number;

  @ApiProperty({ example: 'D-178' })
  label: string;
}
