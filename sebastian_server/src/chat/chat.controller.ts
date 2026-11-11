import {
  Body,
  Controller,
  Get,
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
import { ChatService } from './chat.service';
import { SendChatMessageDto } from './dto/send-chat-message.dto';
import { OverdueBriefingDto } from './dto/overdue-briefing.dto';
import { UpdatePersonaProfileDto } from './dto/update-persona-profile.dto';
import { ChatMessageResponseDto } from './dto/chat-message-response.dto';
import { PersonaListItemDto } from './dto/persona-list-item.dto';
import { PersonaProfileResponseDto } from './dto/persona-profile-response.dto';
import { SendChatMessageResponseDto } from './dto/send-chat-message-response.dto';

type JwtReq = { user: { userId: number; email: string } };

@ApiTags('Chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('messages')
  @ApiOperation({ summary: '내 홈 채팅 메시지 목록 (시간순)' })
  @ApiResponse({ status: 200, type: [ChatMessageResponseDto] })
  async getMessages(@Req() req: JwtReq): Promise<ChatMessageResponseDto[]> {
    return this.chatService.getMessages(req.user.userId);
  }

  @Post('messages')
  @ApiOperation({ summary: '메시지 전송 (사용자 메시지 저장 + placeholder AI 응답)' })
  @ApiResponse({ status: 201, type: SendChatMessageResponseDto })
  async sendMessage(
    @Req() req: JwtReq,
    @Body() dto: SendChatMessageDto,
  ): Promise<SendChatMessageResponseDto> {
    return this.chatService.sendMessage(req.user.userId, dto);
  }

  @Post('overdue-briefing')
  @ApiOperation({
    summary: '지난(overdue) 일정 브리핑을 페르소나 말투로 생성 (DB 미저장)',
  })
  @ApiResponse({ status: 201, schema: { example: { text: '...' } } })
  async overdueBriefing(
    @Req() req: JwtReq,
    @Body() dto: OverdueBriefingDto,
  ): Promise<{ text: string }> {
    return this.chatService.generateOverdueBriefing(req.user.userId, dto.items);
  }

  @Get('personas')
  @ApiOperation({ summary: '페르소나 목록 (선택 UI용)' })
  @ApiResponse({ status: 200, type: [PersonaListItemDto] })
  async listPersonas(): Promise<PersonaListItemDto[]> {
    return this.chatService.listPersonas();
  }

  @Get('persona-profile')
  @ApiOperation({ summary: '내 활성 페르소나 및 호칭 조회' })
  @ApiResponse({ status: 200, type: PersonaProfileResponseDto })
  async getPersonaProfile(@Req() req: JwtReq): Promise<PersonaProfileResponseDto> {
    return this.chatService.getPersonaProfile(req.user.userId);
  }

  @Patch('persona-profile')
  @ApiOperation({ summary: '활성 페르소나 / 호칭 수정' })
  @ApiResponse({ status: 200, type: PersonaProfileResponseDto })
  async updatePersonaProfile(
    @Req() req: JwtReq,
    @Body() dto: UpdatePersonaProfileDto,
  ): Promise<PersonaProfileResponseDto> {
    return this.chatService.updatePersonaProfile(req.user.userId, dto);
  }
}
