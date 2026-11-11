import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ScheduleDdayDateBasis } from '../schedule-dday-date-basis.enum';

export class ScheduleResponseDto {
  @ApiProperty()
  id: number

  @ApiProperty()
  userId: number;

  @ApiProperty()
  title: string;

  @ApiPropertyOptional({ nullable: true })
  content: string | null;

  @ApiPropertyOptional({ nullable: true })
  originalText: string | null;

  @ApiProperty()
  startDate: Date;

  @ApiProperty()
  endDate: Date;

  @ApiProperty()
  createdAt: Date;

  @ApiPropertyOptional({ nullable: true })
  category: string | null;

  @ApiProperty({
    example: 2,
    description: '우선순위 (1=높음, 2=보통, 3=낮음)',
  })
  priority: number;

  @ApiProperty()
  inputSource: string;

  @ApiProperty()
  isCompleted: boolean;

  @ApiPropertyOptional({ nullable: true })
  completedAt: Date | null;

  @ApiProperty()
  isAlarmOn: boolean;

  @ApiProperty({ default: false })
  isImportant: boolean;

  @ApiProperty({
    example: 30,
    description: '일정 시작 몇 분 전 알림',
  })
  notificationLeadMinutes: number;

  @ApiPropertyOptional({
    nullable: true,
    description: '일정과 연결된 D-Day ID',
  })
  ddayId: number | null;

  @ApiPropertyOptional({
    enum: ScheduleDdayDateBasis,
    nullable: true,
    description: '연결 D-Day의 목표일 기준',
  })
  ddayDateBasis: ScheduleDdayDateBasis | null;
}
