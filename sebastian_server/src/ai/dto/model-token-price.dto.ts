import { ApiProperty } from '@nestjs/swagger';

/** USD per 1M tokens — 가격표 맵의 값 타입 */
export class ModelTokenPriceDto {
  @ApiProperty({ description: 'USD per 1M input tokens', example: 0.15 })
  input: number;

  @ApiProperty({ description: 'USD per 1M output tokens', example: 0.6 })
  output: number;
}
