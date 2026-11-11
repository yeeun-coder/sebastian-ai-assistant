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
  UnauthorizedException,
  UseGuards,
} from '@nestjs/common';
import {
  ApiHeader,
  ApiOperation,
  ApiQuery,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../user/users.service';
import { AdminApiKeyGuard } from './admin-api-key.guard';
import { AdminResetPasswordDto } from './dto/admin-reset-password.dto';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AdminUpdateUserDto } from './dto/admin-update-user.dto';
import { CreateUserDto } from '../user/dto/create-user.dto';
import { PasswordResetService } from '../password-reset/password-reset.service';
import type { PasswordResetRequestStatus } from '../password-reset/password-reset-request.entity';
import { ResolvePasswordResetRequestDto } from '../password-reset/dto/resolve-password-reset-request.dto';
import { RejectPasswordResetRequestDto } from '../password-reset/dto/reject-password-reset-request.dto';

@ApiTags('Admin')
@Controller('admin')
export class AdminController {
  constructor(
    private readonly usersService: UsersService,
    private readonly config: ConfigService,
    private readonly jwt: JwtService,
    private readonly passwordResetService: PasswordResetService,
  ) {}

  @Post('login')
  @ApiOperation({
    summary: '관리자 로그인',
    description:
      'username/password 검증 후 JWT를 반환합니다. 이후 요청의 x-admin-key에 동일 값을 넣습니다.',
  })
  @ApiResponse({ status: 200 })
  login(@Body() dto: AdminLoginDto) {
    const expectedUser = (
      this.config.get<string>('ADMIN_USERNAME') ?? 'admin'
    ).trim();
    const expectedPass = (
      this.config.get<string>('ADMIN_PASSWORD') ?? 'admin1234'
    ).trim();

    if (dto.username !== expectedUser || dto.password !== expectedPass) {
      throw new UnauthorizedException(
        '아이디 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    const token = this.jwt.sign(
      { sub: 'admin-console', typ: 'sebastian-admin' },
      { expiresIn: '8h' },
    );
    return { token };
  }

  @Get('users')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '사용자 목록 (비밀번호 제외)' })
  @ApiResponse({ status: 200 })
  listUsers() {
    return this.usersService.adminListUsers();
  }

  @Post('users')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '사용자 추가' })
  @ApiResponse({ status: 201 })
  createUser(@Body() dto: CreateUserDto) {
    return this.usersService.adminCreateUser(dto);
  }

  @Patch('users/:id')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '사용자 정보 수정' })
  @ApiResponse({ status: 200 })
  updateUser(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AdminUpdateUserDto,
  ) {
    return this.usersService.adminUpdateUser(id, dto);
  }

  @Delete('users/:id')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '사용자 삭제' })
  @ApiResponse({ status: 200 })
  @HttpCode(200)
  async deleteUser(@Param('id', ParseIntPipe) id: number) {
    await this.usersService.adminDeleteUser(id);
    return { ok: true };
  }

  @Post('users/:id/reset-password')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '비밀번호 초기화' })
  @ApiResponse({ status: 200 })
  async resetPassword(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: AdminResetPasswordDto,
  ) {
    await this.usersService.adminResetPassword(id, dto.newPassword);
    return { ok: true };
  }

  @Get('password-reset-requests')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiQuery({
    name: 'status',
    required: false,
    enum: ['pending', 'done', 'rejected'],
  })
  @ApiOperation({ summary: '비밀번호 초기화 요청 목록' })
  @ApiResponse({ status: 200 })
  listPasswordResetRequests(@Query('status') status?: PasswordResetRequestStatus) {
    return this.passwordResetService.list(status);
  }

  @Get('password-reset-requests/pending-count')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '대기 중 비밀번호 초기화 요청 수' })
  @ApiResponse({ status: 200 })
  async pendingPasswordResetCount() {
    const count = await this.passwordResetService.countPending();
    return { count };
  }

  @Patch('password-reset-requests/:id/resolve')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({
    summary: '비밀번호 초기화 요청 처리 (새 비밀번호 적용)',
  })
  @ApiResponse({ status: 200 })
  resolvePasswordResetRequest(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: ResolvePasswordResetRequestDto,
  ) {
    return this.passwordResetService.resolve(
      id,
      dto.newPassword,
      this.config.get<string>('ADMIN_USERNAME') ?? 'admin',
      dto.memo,
    );
  }

  @Patch('password-reset-requests/:id/reject')
  @UseGuards(AdminApiKeyGuard)
  @ApiHeader({ name: 'x-admin-key', required: true })
  @ApiOperation({ summary: '비밀번호 초기화 요청 거절' })
  @ApiResponse({ status: 200 })
  rejectPasswordResetRequest(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: RejectPasswordResetRequestDto,
  ) {
    return this.passwordResetService.reject(
      id,
      this.config.get<string>('ADMIN_USERNAME') ?? 'admin',
      dto.memo,
    );
  }
}
