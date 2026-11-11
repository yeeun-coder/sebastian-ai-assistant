import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PasswordResetService } from './password-reset.service';
import { CreatePasswordResetRequestDto } from './dto/create-password-reset-request.dto';

@ApiTags('Auth')
@Controller('auth/password-reset-requests')
export class PasswordResetController {
  constructor(private readonly service: PasswordResetService) {}

  @Post()
  @HttpCode(200)
  @ApiOperation({
    summary: '비밀번호 초기화 요청',
    description:
      '관리자에게 비밀번호 초기화를 요청합니다. 이메일 존재 여부와 무관하게 동일한 응답을 반환합니다.',
  })
  @ApiResponse({ status: 200 })
  async create(@Body() dto: CreatePasswordResetRequestDto) {
    await this.service.createRequest(dto.email);
    return { ok: true };
  }
}
