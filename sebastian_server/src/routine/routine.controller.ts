import {
  BadRequestException,
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { RoutineService } from './routine.service';
import { CreateRoutineDto } from './dto/create-routine.dto';
import { UpdateRoutineDto } from './dto/update-routine.dto';
import { RoutineResponseDto } from './dto/routine-response.dto';
import {
  RoutineCompletionDateDto,
  RoutineCompletionsResponseDto,
} from './dto/routine-completion.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Routine')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('routine')
export class RoutineController {
  constructor(private readonly routineService: RoutineService) {}

  @Post()
  @ApiOperation({ summary: '루틴 생성' })
  @ApiResponse({ status: 201, type: RoutineResponseDto })
  async create(
    @Req() req: JwtReq,
    @Body() dto: CreateRoutineDto,
  ): Promise<RoutineResponseDto> {
    return this.routineService.create(req.user.userId, dto);
  }

  @Get()
  @ApiOperation({ summary: '내 루틴 목록' })
  @ApiResponse({ status: 200, type: [RoutineResponseDto] })
  async findAll(@Req() req: JwtReq): Promise<RoutineResponseDto[]> {
    return this.routineService.findAll(req.user.userId);
  }

  @Get('completions')
  @ApiOperation({ summary: '특정 날짜에 완료한 루틴 ID 목록' })
  @ApiResponse({ status: 200, type: RoutineCompletionsResponseDto })
  async getCompletions(
    @Req() req: JwtReq,
    @Query('date') date: string,
  ): Promise<RoutineCompletionsResponseDto> {
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException('date 쿼리(YYYY-MM-DD)가 필요합니다');
    }
    const routines = await this.routineService.findCompletedTodayForBriefing(
      req.user.userId,
      date,
    );
    return {
      routineIds: routines.map((r) => r.id),
      routines: routines.map((r) => ({
        id: r.id,
        category: r.category,
        title: r.title,
        targetTime: r.targetTime,
      })),
    };
  }

  @Post(':id/complete')
  @ApiOperation({ summary: '특정 날짜 루틴 완료 처리' })
  async complete(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: RoutineCompletionDateDto,
  ): Promise<{ ok: true }> {
    await this.routineService.setCompletion(
      req.user.userId,
      id,
      dto.date,
      true,
    );
    return { ok: true };
  }

  @Delete(':id/complete')
  @ApiOperation({ summary: '특정 날짜 루틴 완료 취소' })
  async uncomplete(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Query('date') date: string,
  ): Promise<{ ok: true }> {
    if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
      throw new BadRequestException('date 쿼리(YYYY-MM-DD)가 필요합니다');
    }
    await this.routineService.setCompletion(
      req.user.userId,
      id,
      date,
      false,
    );
    return { ok: true };
  }

  @Get(':id')
  @ApiOperation({ summary: '루틴 단건 조회' })
  @ApiResponse({ status: 200, type: RoutineResponseDto })
  async findOne(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<RoutineResponseDto> {
    return this.routineService.findOne(id, req.user.userId);
  }

  @Patch(':id')
  @ApiOperation({ summary: '루틴 수정' })
  @ApiResponse({ status: 200, type: RoutineResponseDto })
  async update(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateRoutineDto,
  ): Promise<RoutineResponseDto> {
    return this.routineService.update(id, req.user.userId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '루틴 삭제' })
  @ApiResponse({ status: 200, description: '삭제 완료' })
  async remove(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<void> {
    return this.routineService.remove(id, req.user.userId);
  }
}
