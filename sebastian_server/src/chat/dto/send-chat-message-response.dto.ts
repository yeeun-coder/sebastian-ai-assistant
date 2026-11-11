import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ChatMessageResponseDto } from './chat-message-response.dto';
import { ScheduleResponseDto } from '../../schedule/dto/schedule-response.dto';
import { TodoResponseDto } from '../../todo/dto/todo-response.dto';
import { RoutineResponseDto } from '../../routine/dto/routine-response.dto';
import { DiaryResponseDto } from '../../diary/dto/diary-response.dto';

export class SendChatMessageResponseDto {
  @ApiProperty({ type: ChatMessageResponseDto })
  userMessage: ChatMessageResponseDto;

  @ApiProperty({ type: ChatMessageResponseDto })
  assistantMessage: ChatMessageResponseDto;

  @ApiPropertyOptional({ type: ScheduleResponseDto, nullable: true })
  schedule?: ScheduleResponseDto | null;

  @ApiPropertyOptional({ type: TodoResponseDto, nullable: true })
  todo?: TodoResponseDto | null;

  @ApiPropertyOptional({ type: RoutineResponseDto, nullable: true })
  routine?: RoutineResponseDto | null;

  @ApiPropertyOptional({
    type: [RoutineResponseDto],
    description: 'create_routine으로 여러 습관을 한 번에 넣을 때 전체 목록',
    nullable: true,
  })
  routines?: RoutineResponseDto[] | null;

  @ApiPropertyOptional({ type: DiaryResponseDto, nullable: true })
  diary?: DiaryResponseDto | null;

  @ApiPropertyOptional({
    description:
      'true이면 새로 만든 것이 아니라 기존 일정/할 일을 수정한 것입니다.',
  })
  updated?: boolean;
}
