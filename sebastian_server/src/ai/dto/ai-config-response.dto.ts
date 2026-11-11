import { ApiProperty } from '@nestjs/swagger';

/** GET /ai/config — 목록 항목 (키 마스킹 힌트 포함) */
export class AiConfigListItemDto {
  @ApiProperty()
  id: number;

  @ApiProperty({ example: 'openai' })
  provider: string;

  @ApiProperty({ example: 'gpt-4o-mini' })
  model: string;

  @ApiProperty({ description: 'API 키 존재 여부' })
  hasApiKey: boolean;

  @ApiProperty({
    description: '마스킹된 키 미리보기 (키 없으면 빈 문자열)',
    example: 'sk-••••••••',
  })
  apiKeyHint: string;

  @ApiProperty()
  isActive: boolean;
}

/** PUT /ai/config — 저장 후 응답 (힌트 없음) */
export class AiConfigSavedResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty({ example: 'openai' })
  provider: string;

  @ApiProperty({ example: 'gpt-4o-mini' })
  model: string;

  @ApiProperty({ description: 'API 키 존재 여부' })
  hasApiKey: boolean;

  @ApiProperty()
  isActive: boolean;
}
