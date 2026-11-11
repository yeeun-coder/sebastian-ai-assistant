import { ApiProperty } from '@nestjs/swagger';

export class AiProviderModelItemDto {
  @ApiProperty({ example: 'gpt-4o-mini' })
  id: string;

  @ApiProperty({ example: 'GPT-4o Mini' })
  name: string;
}

export class AiProviderListItemDto {
  @ApiProperty({ example: 'openai' })
  provider: string;

  @ApiProperty({ example: 'OpenAI (ChatGPT)' })
  label: string;

  @ApiProperty({ type: [AiProviderModelItemDto] })
  models: AiProviderModelItemDto[];
}
