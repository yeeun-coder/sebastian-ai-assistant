import { ApiProperty } from '@nestjs/swagger';

export class ChatMessageResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  userId: number;

  @ApiProperty({ enum: ['user', 'assistant'] })
  senderRole: string;

  @ApiProperty()
  message: string;

  @ApiProperty()
  createdAt: Date;
}
