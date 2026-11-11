import { ApiProperty } from '@nestjs/swagger';

export class AiClearUsageResponseDto {
  @ApiProperty({ example: true })
  cleared: boolean;
}
