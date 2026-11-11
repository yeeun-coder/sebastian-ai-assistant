import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { BriefingService } from './briefing.service';
import { TodayBriefingResponseDto } from './dto/today-briefing-response.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Briefing')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('briefing')
export class BriefingController {
  constructor(private readonly briefingService: BriefingService) {}

  @Get('today')
  @ApiOperation({
    summary: '오늘 브리핑 (남은 일정·To-Do·루틴 + 오늘 완료 항목)',
    description:
      'KST 기준 오늘. upcoming은 미완료, completedToday는 오늘 체크 완료한 항목입니다.',
  })
  @ApiResponse({ status: 200, type: TodayBriefingResponseDto })
  async getToday(@Req() req: JwtReq): Promise<TodayBriefingResponseDto> {
    return this.briefingService.getTodayBriefing(req.user.userId);
  }
}
