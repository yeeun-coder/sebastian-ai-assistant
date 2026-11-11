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
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth/jwt-auth.guard';
import { DiaryService } from './diary.service';
import { CreateDiaryDto } from './dto/create-diary.dto';
import { UpdateDiaryDto } from './dto/update-diary.dto';
import { DiaryResponseDto } from './dto/diary-response.dto';
import { DiaryListQueryDto } from './dto/diary-list-query.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Diary')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('diary')
export class DiaryController {
  constructor(private readonly diaryService: DiaryService) {}

  @Get()
  @ApiOperation({ summary: '내 일기 목록 (기간 필터 optional)' })
  @ApiResponse({ status: 200, type: [DiaryResponseDto] })
  async findAll(
    @Req() req: JwtReq,
    @Query() query: DiaryListQueryDto,
  ): Promise<DiaryResponseDto[]> {
    return this.diaryService.findAll(
      req.user.userId,
      query.from,
      query.to,
    );
  }

  @Get(':id')
  @ApiOperation({ summary: '일기 단건 조회' })
  @ApiResponse({ status: 200, type: DiaryResponseDto })
  async findOne(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<DiaryResponseDto> {
    return this.diaryService.findOne(id, req.user.userId);
  }

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: '일기 등록',
    description: '새 일기를 등록합니다. 같은 날짜에 여러 편을 작성할 수 있습니다.',
  })
  @ApiResponse({ status: 200, type: DiaryResponseDto })
  async create(
    @Req() req: JwtReq,
    @Body() dto: CreateDiaryDto,
  ): Promise<DiaryResponseDto> {
    return this.diaryService.create(req.user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: '일기 수정' })
  @ApiResponse({ status: 200, type: DiaryResponseDto })
  async update(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateDiaryDto,
  ): Promise<DiaryResponseDto> {
    return this.diaryService.update(id, req.user.userId, dto);
  }

  @Delete(':id')
  @HttpCode(200)
  @ApiOperation({ summary: '일기 삭제' })
  @ApiResponse({ status: 200, description: '삭제 완료' })
  async remove(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<void> {
    return this.diaryService.remove(id, req.user.userId);
  }
}
