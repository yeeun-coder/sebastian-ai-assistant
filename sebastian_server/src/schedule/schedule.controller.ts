import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
  ParseIntPipe
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { ScheduleService } from './schedule.service';
import { CreateScheduleDto } from './dto/create-schedule.dto';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { ScheduleResponseDto } from './dto/schedule-response.dto';
import { ScheduleListQueryDto } from './dto/schedule-list-query.dto';
import { ScheduleListResponseDto } from './dto/schedule-list-response.dto';
import { UpcomingRemindersQueryDto } from './dto/upcoming-reminders-query.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Schedule')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('schedule')
export class ScheduleController {
  constructor(private readonly scheduleService: ScheduleService) {}

  @Post()
  @ApiOperation({ summary: '일정 생성' })
  @ApiResponse({ status: 201, type: ScheduleResponseDto })
  async create(
    @Req() req: JwtReq,
    @Body() dto: CreateScheduleDto,
  ): Promise<ScheduleResponseDto> {
    return this.scheduleService.create(req.user.userId, dto);
  }

  /** 미루기용: 시작이 지났는데 미완료인 일정 — :id 보다 먼저 등록 */
  @Get('overdue')
  @ApiOperation({
    summary: '지난 미완료 일정 목록 (id·title·startTime만)',
    description:
      '앱 시작·포그라운드 복귀 시 호출. 결과가 있으면 채팅에서 미루기를 제안합니다.',
  })
  @ApiResponse({ status: 200 })
  async overdue(
    @Req() req: JwtReq,
  ): Promise<{ id: number; title: string; startTime: string }[]> {
    return this.scheduleService.findOverdue(req.user.userId);
  }

  /** 알림 폴링용 — :id 보다 먼저 등록 */
  @Get('reminders/upcoming')
  @ApiOperation({
    summary: '알림 대상 일정 (미완료·알림켜짐·시작이 곧 도래)',
    description:
      '앱에서 주기적으로 호출해 로컬 알림을 띄울 때 사용합니다. 서버 푸시는 별도입니다.',
  })
  @ApiResponse({ status: 200, type: [ScheduleResponseDto] })
  async upcomingReminders(
    @Req() req: JwtReq,
    @Query() query: UpcomingRemindersQueryDto,
  ): Promise<ScheduleResponseDto[]> {
    const h = query.withinHours ?? 24;
    return this.scheduleService.findUpcomingForAlarms(req.user.userId, h);
  }

  @Get()
  @ApiOperation({
    summary: '내 일정 목록 (페이징, 기간 겹침 필터 선택)',
  })
  @ApiQuery({
    name: 'from',
    required: false,
    description: 'ISO 날짜/시간 (구간 시작)',
  })
  @ApiQuery({
    name: 'to',
    required: false,
    description: 'ISO 날짜/시간 (구간 끝)',
  })
  @ApiQuery({ name: 'page', required: false, example: 1 })
  @ApiQuery({ name: 'limit', required: false, example: 50 })
  @ApiResponse({ status: 200, type: ScheduleListResponseDto })
  async findAll(
    @Req() req: JwtReq,
    @Query() query: ScheduleListQueryDto,
  ): Promise<ScheduleListResponseDto> {
    const hasRange = query.from && query.to;
    return this.scheduleService.findAll(
      req.user.userId,
      hasRange ? query.from : undefined,
      hasRange ? query.to : undefined,
      query.page ?? 1,
      query.limit ?? 50,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: '일정 단건 조회' })
  @ApiResponse({ status: 200, type: ScheduleResponseDto })
  async findOne(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number
  ): Promise<ScheduleResponseDto> {
    return this.scheduleService.findOne(id, req.user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: '일정 수정' })
  @ApiResponse({ status: 200, type: ScheduleResponseDto })
  async update(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateScheduleDto,
  ): Promise<ScheduleResponseDto> {
    return this.scheduleService.update(id, req.user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '일정 삭제' })
  @ApiResponse({ status: 200, description: '삭제 완료' })
  async remove(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number
  ): Promise<{ ok: true }> {
    await this.scheduleService.remove(id, req.user.userId);
    return { ok: true };
  }
}
