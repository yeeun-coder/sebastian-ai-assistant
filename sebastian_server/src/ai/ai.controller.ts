import {
  Body,
  Controller,
  Delete,
  Get,
  Put,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiExtraModels,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  getSchemaPath,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { AiProviderService } from './ai-provider.service';
import { AiClearUsageResponseDto } from './dto/clear-usage-response.dto';
import {
  AiConfigListItemDto,
  AiConfigSavedResponseDto,
} from './dto/ai-config-response.dto';
import { AiProviderListItemDto } from './dto/ai-provider-list-item.dto';
import { AiUsageSummaryResponseDto } from './dto/ai-usage-summary.dto';
import { ModelTokenPriceDto } from './dto/model-token-price.dto';
import { UpdateAiConfigDto } from './dto/update-ai-config.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('AI')
@ApiBearerAuth()
@ApiUnauthorizedResponse({
  description:
    'Authorization Bearer 토큰이 없거나, 형식이 잘못되었거나, 만료·위조된 JWT입니다.',
})
@ApiExtraModels(ModelTokenPriceDto)
@UseGuards(JwtAuthGuard)
@Controller('ai')
export class AiController {
  constructor(private readonly ai: AiProviderService) {}

  /* ───── 프로바이더 & 모델 목록 ───── */

  @Get('providers')
  @ApiOperation({ summary: '지원 프로바이더 · 모델 목록' })
  @ApiResponse({ status: 200, type: [AiProviderListItemDto] })
  getProviders(): ReturnType<AiProviderService['getProviders']> {
    return this.ai.getProviders();
  }

  @Get('pricing')
  @ApiOperation({ summary: '모델별 토큰 가격표 (USD/1M tokens)' })
  @ApiResponse({
    status: 200,
    description: '모델 ID → USD/1M input·output 토큰 가격',
    schema: {
      type: 'object',
      additionalProperties: { $ref: getSchemaPath(ModelTokenPriceDto) },
    },
  })
  getPricing(): ReturnType<AiProviderService['getPricing']> {
    return this.ai.getPricing();
  }

  /* ───── 설정 관리 ───── */

  @Get('config')
  @ApiOperation({ summary: '현재 AI 설정 목록 (API 키 마스킹)' })
  @ApiResponse({ status: 200, type: [AiConfigListItemDto] })
  async getConfig() {
    const configs = await this.ai.getAllConfigs();
    return configs.map((c) => ({
      id: c.id,
      provider: c.provider,
      model: c.model,
      hasApiKey: !!c.apiKey,
      apiKeyHint: c.apiKey ? maskKey(c.apiKey) : '',
      isActive: c.isActive,
    }));
  }

  @Put('config')
  @ApiOperation({ summary: 'AI 프로바이더 활성화 & 설정 변경' })
  @ApiBody({ type: UpdateAiConfigDto })
  @ApiBadRequestResponse({
    description:
      '요청 본문 검증 실패 (예: provider가 허용 목록이 아님, 타입 불일치)',
  })
  @ApiResponse({ status: 200, type: AiConfigSavedResponseDto })
  async updateConfig(@Body() dto: UpdateAiConfigDto) {
    const saved = await this.ai.updateConfig(
      dto.provider,
      dto.model,
      dto.apiKey,
    );
    return {
      id: saved.id,
      provider: saved.provider,
      model: saved.model,
      hasApiKey: !!saved.apiKey,
      isActive: saved.isActive,
    };
  }

  /* ───── 사용량 / 비용 ───── */

  @Get('usage/summary')
  @ApiOperation({
    summary: 'AI 사용량 요약 (기간 필터)',
    description:
      '응답의 `daily`는 날짜 오름차순이며, 일자가 많을 때 **최근 30일**만 포함됩니다.',
  })
  @ApiQuery({
    name: 'days',
    required: false,
    description:
      '집계할 기간: **오늘부터 역산한 최근 N일**만 포함합니다. ' +
      '**양의 정수**로 파싱될 때만 적용됩니다. ' +
      '쿼리를 생략하거나, 숫자가 아니거나(`NaN`), 0 이하이면 **기간 제한 없이** 누적 전체를 집계합니다.',
    example: 30,
  })
  @ApiResponse({ status: 200, type: AiUsageSummaryResponseDto })
  async getUsageSummary(
    @Req() req: JwtReq,
    @Query('days') daysRaw?: string,
  ) {
    const days = daysRaw ? Number(daysRaw) : undefined;
    return this.ai.getUsageSummary(req.user.userId, days);
  }

  @Delete('usage')
  @ApiOperation({ summary: '내 사용량 기록 초기화' })
  @ApiResponse({ status: 200, type: AiClearUsageResponseDto })
  async clearUsage(@Req() req: JwtReq) {
    await this.ai.clearUsage(req.user.userId);
    return { cleared: true };
  }
}

function maskKey(key: string): string {
  if (key.length <= 8) return '••••••••';
  return key.slice(0, 4) + '••••' + key.slice(-4);
}
