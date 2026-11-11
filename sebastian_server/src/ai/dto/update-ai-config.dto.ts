import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class UpdateAiConfigDto {
  @ApiProperty({
    description: 'AI 프로바이더',
    enum: ['claude', 'openai', 'gemini'],
    example: 'openai',
  })
  @IsString()
  @IsNotEmpty()
  @IsIn(['claude', 'openai', 'gemini'])
  provider: string;

  @ApiPropertyOptional({
    description: '사용할 모델명',
    example: 'gpt-4o-mini',
  })
  @IsOptional()
  @IsString()
  model?: string;

  @ApiPropertyOptional({
    description: 'API 키 (빈 문자열이면 기존 키 유지)',
    example: 'sk-...',
  })
  @IsOptional()
  @IsString()
  apiKey?: string;
}
