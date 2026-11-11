import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
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
import { TodoService } from './todo.service';
import { CreateTodoDto } from './dto/create-todo.dto';
import { UpdateTodoDto } from './dto/update-todo.dto';
import { TodoResponseDto } from './dto/todo-response.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Todo')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('todos')
export class TodoController {
  constructor(private readonly todoService: TodoService) {}

  @Get()
  @ApiOperation({ summary: '내 할 일 목록 조회' })
  @ApiResponse({ status: 200, type: [TodoResponseDto] })
  async getMyTodos(@Req() req: JwtReq): Promise<TodoResponseDto[]> {
    return this.todoService.getMyTodos(req.user.userId);
  }

  @Post()
  @ApiOperation({ summary: '할 일 생성' })
  @ApiResponse({ status: 201, type: TodoResponseDto })
  async create(
    @Req() req: JwtReq,
    @Body() dto: CreateTodoDto,
  ): Promise<TodoResponseDto> {
    return this.todoService.create(req.user.userId, dto);
  }

  @Patch(':id')
  @ApiOperation({
    summary:
      '할 일 수정 (제목 / 상세 / 우선순위 / 카테고리 / 입력출처 / 원문 / 완료여부 / 완료일시 / 마감일)',
  })
  @ApiResponse({ status: 200, type: TodoResponseDto })
  async update(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateTodoDto,
  ): Promise<TodoResponseDto> {
    return this.todoService.update(req.user.userId, id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: '할 일 삭제' })
  @ApiResponse({ status: 200 })
  async remove(
    @Req() req: JwtReq,
    @Param('id', ParseIntPipe) id: number,
  ): Promise<void> {
    return this.todoService.remove(req.user.userId, id);
  }
}
