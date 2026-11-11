import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
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
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { DDayService } from './dday.service';
import { CreateDDayDto } from './dto/create-dday.dto';
import { UpdateDDayDto } from './dto/update-dday.dto';
import { DDayResponseDto } from './dto/dday-response.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('DDay')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('dday')
export class DDayController {
  constructor(private readonly ddayService: DDayService) {}

  @Get()
  @ApiOperation({ summary: '내 D-Day 목록 (daysLeft·label 포함)' })
  @ApiQuery({
    name: 'pinnedOnly',
    required: false,
    type: Boolean,
    description: 'true면 고정된 항목만',
  })
  @ApiResponse({ status: 200, type: [DDayResponseDto] })
  async findAll(
    @Req() req: JwtReq,
    @Query('pinnedOnly') pinnedOnly?: string,
  ): Promise<DDayResponseDto[]> {
    const onlyPinned = pinnedOnly === 'true' || pinnedOnly === '1';
    return this.ddayService.findAll(req.user.userId, onlyPinned);
  }

  @Get(':id')
  @ApiOperation({ summary: 'D-Day 단건 조회' })
  @ApiResponse({ status: 200, type: DDayResponseDto })
  async findOne(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<DDayResponseDto> {
    return this.ddayService.findOne(id, req.user.userId);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({ summary: 'D-Day 등록' })
  @ApiResponse({ status: 200, type: DDayResponseDto })
  async create(
    @Req() req: JwtReq,
    @Body() dto: CreateDDayDto,
  ): Promise<DDayResponseDto> {
    return this.ddayService.create(req.user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'D-Day 수정' })
  @ApiResponse({ status: 200, type: DDayResponseDto })
  async update(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDDayDto,
  ): Promise<DDayResponseDto> {
    return this.ddayService.update(id, req.user.userId, dto);
  }

  @Delete(':id')
  @HttpCode(200)
  @ApiOperation({ summary: 'D-Day 삭제' })
  @ApiResponse({ status: 200, description: '삭제 완료' })
  async remove(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<void> {
    return this.ddayService.remove(id, req.user.userId);
  }
}
