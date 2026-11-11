import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  Patch,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { ApiTags, ApiOperation, ApiOkResponse, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth/jwt-auth.guard';
import { UpdatePasswordDto } from './dto/update-password.dto';
import { PersonalityTagsService } from './personality-tags.service';
import { UserProfileResponseDto } from './dto/user-profile-response.dto';
import { UpdateUserProfileDto } from './dto/update-user-profile.dto';
import { diskStorage } from 'multer';
import { existsSync, mkdirSync } from 'fs';
import { extname, join } from 'path';

type JwtReq = { user: { userId: number; email: string } };

const UPLOAD_DIR = join(process.cwd(), 'uploads');

function ensureUploadDir(): void {
  if (!existsSync(UPLOAD_DIR)) {
    mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

@ApiTags('Users')
@Controller('users')
export class UsersController {
    constructor(
        private readonly usersService: UsersService,
        private readonly personalityTagsService: PersonalityTagsService,
    ) {}

    @Post('signup')
    @ApiOperation({ summary: '회원가입' })
    async signup(@Body() dto: CreateUserDto) {
        return this.usersService.create(dto);
    }

    @Get('me')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: '내 프로필 조회 (이름·나이·성별·태그)' })
    @ApiOkResponse({ type: UserProfileResponseDto })
    async getProfile(@Req() req: JwtReq): Promise<UserProfileResponseDto> {
        return this.usersService.getProfile(req.user.userId);
    }

    @Patch('me')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: '내 프로필 설정 수정 (닉네임·생년월일·성별·프로필 이미지)' })
    @ApiOkResponse({ type: UserProfileResponseDto })
    async updateProfile(
        @Req() req: JwtReq,
        @Body() dto: UpdateUserProfileDto,
    ): Promise<UserProfileResponseDto> {
        return this.usersService.updateProfile(req.user.userId, dto);
    }

    @Post('me/avatar')
    @HttpCode(200)
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiConsumes('multipart/form-data')
    @ApiOperation({ summary: '프로필 이미지 업로드' })
    @ApiBody({
        schema: {
            type: 'object',
            properties: {
                image: { type: 'string', format: 'binary' },
            },
        },
    })
    @ApiOkResponse({ type: UserProfileResponseDto })
    @UseInterceptors(
        FileInterceptor('image', {
            storage: diskStorage({
                destination: (_req, _file, cb) => {
                    ensureUploadDir();
                    cb(null, UPLOAD_DIR);
                },
                filename: (req, file, cb) => {
                    const jwtReq = req as unknown as JwtReq;
                    const userId = jwtReq.user.userId;
                    const ext = extname(file.originalname).toLowerCase() || '.jpg';
                    cb(null, `profile-${userId}-${Date.now()}${ext}`);
                },
            }),
            limits: { fileSize: 5 * 1024 * 1024 },
            fileFilter: (_req, file, cb) => {
                const allowedMime =
                    /^image\/(jpeg|jpg|png|webp|gif|heic|heif)$/i.test(
                        file.mimetype,
                    );
                const ext = extname(file.originalname).toLowerCase();
                const allowedExt = [
                    '.jpg',
                    '.jpeg',
                    '.png',
                    '.webp',
                    '.gif',
                    '.heic',
                    '.heif',
                ].includes(ext);
                if (!allowedMime && !allowedExt) {
                    cb(
                        new BadRequestException(
                            '지원하지 않는 이미지 형식입니다.',
                        ),
                        false,
                    );
                    return;
                }
                cb(null, true);
            },
        }),
    )
    async uploadAvatar(
        @Req() req: JwtReq,
        @UploadedFile() file?: Express.Multer.File,
    ): Promise<UserProfileResponseDto> {
        if (!file) {
            throw new BadRequestException('이미지 파일이 필요합니다.');
        }
        return this.usersService.updateProfileImage(
            req.user.userId,
            `/uploads/${file.filename}`,
        );
    }

    @Get('tags')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: '내 성향 태그 조회 (저장된 값)' })
    @ApiOkResponse({
        description: '저장된 성향 태그 문자열 배열 (없으면 [])',
        schema: {
            type: 'array',
            items: { type: 'string' },
            example: ['차분함', '계획적', '호기심', '배려', '꼼꼼함'],
        },
    })
    async getTags(@Req() req: JwtReq) {
        return this.usersService.getTags(req.user.userId);
    }

    @Post('tags/analyze')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({
        summary: '홈 채팅 기반 성향 태그 분석·저장 (5개)',
        description:
            '최근 대화 일부를 AI로 분석해 태그를 만들고 DB에 저장한 뒤 배열을 반환합니다.',
    })
    @ApiOkResponse({
        description: '분석된 성향 태그 문자열 5개 (DB에도 저장됨)',
        schema: {
            type: 'array',
            items: { type: 'string' },
            minItems: 5,
            maxItems: 5,
            example: ['차분함', '계획적', '호기심', '배려', '꼼꼼함'],
        },
    })
    async analyzeTags(@Req() req: JwtReq) {
        return this.personalityTagsService.analyzeFromChatAndSave(
            req.user.userId,
        );
    }

    @Post('password')
    @UseGuards(JwtAuthGuard)
    @ApiBearerAuth()
    @ApiOperation({ summary: '비밀번호 변경 (현재 비밀번호 확인 필요)' })
    async updatePassword(@Req() req: JwtReq, @Body() dto: UpdatePasswordDto) {
        return this.usersService.updatePassword(req.user.userId, dto.currentPassword, dto.newPassword);
    }
}