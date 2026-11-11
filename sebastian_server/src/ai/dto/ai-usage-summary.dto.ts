import { ApiProperty } from '@nestjs/swagger';

export class AiDailyUsageItemDto {
  @ApiProperty({ example: '2026-04-07' })
  date: string;

  @ApiProperty()
  costUsd: number;

  @ApiProperty()
  requests: number;
}

export class AiUsageSummaryResponseDto {
  @ApiProperty()
  totalCostUsd: number;

  @ApiProperty()
  totalInputTokens: number;

  @ApiProperty()
  totalOutputTokens: number;

  @ApiProperty()
  totalRequests: number;

  @ApiProperty({
    description: '프로바이더 ID → 집계',
    type: 'object',
    additionalProperties: {
      type: 'object',
      properties: {
        costUsd: { type: 'number' },
        inputTokens: { type: 'number' },
        outputTokens: { type: 'number' },
        requests: { type: 'number' },
      },
    },
  })
  byProvider: Record<
    string,
    {
      costUsd: number;
      inputTokens: number;
      outputTokens: number;
      requests: number;
    }
  >;

  @ApiProperty({
    description: '모델 ID → 집계',
    type: 'object',
    additionalProperties: {
      type: 'object',
      properties: {
        costUsd: { type: 'number' },
        inputTokens: { type: 'number' },
        outputTokens: { type: 'number' },
        requests: { type: 'number' },
      },
    },
  })
  byModel: Record<
    string,
    {
      costUsd: number;
      inputTokens: number;
      outputTokens: number;
      requests: number;
    }
  >;

  @ApiProperty({
    type: [AiDailyUsageItemDto],
    description:
      '일별 비용·요청 수(날짜 오름차순). 데이터가 길면 **가장 최근 30개 일자**만 반환됩니다.',
  })
  daily: AiDailyUsageItemDto[];
}
