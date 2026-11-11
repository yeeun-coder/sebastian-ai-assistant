import { ApiProperty } from '@nestjs/swagger';
import { IsDateString } from 'class-validator';

export class RoutineCompletionDateDto {
  @ApiProperty({ example: '2026-05-19' })
  @IsDateString()
  date: string;
}

export class RoutineCompletionSummaryDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  category: string;

  @ApiProperty()
  title: string;

  @ApiProperty({ example: '09:30' })
  targetTime: string;
}

export class RoutineCompletionsResponseDto {
  @ApiProperty({ type: [Number], example: [1, 3, 5] })
  routineIds: number[];

  @ApiProperty({
    type: [RoutineCompletionSummaryDto],
    description: '완료한 루틴 요약 (브리핑·UI용)',
  })
  routines: RoutineCompletionSummaryDto[];
}
