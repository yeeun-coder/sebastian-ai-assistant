import { ApiProperty } from '@nestjs/swagger';
import { ScheduleResponseDto } from './schedule-response.dto';

export class ScheduleListResponseDto {
  @ApiProperty({ type: [ScheduleResponseDto] })
  items: ScheduleResponseDto[];

  @ApiProperty()
  total: number;

  @ApiProperty()
  page: number;

  @ApiProperty()
  limit: number;
}
