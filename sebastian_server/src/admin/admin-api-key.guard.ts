import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

const ADMIN_JWT_TYP = 'sebastian-admin';

/** `x-admin-key`: 로그인 시 받은 관리자 JWT, 또는 (선택) 환경변수 `ADMIN_API_KEY`와 동일한 문자열 */
@Injectable()
export class AdminApiKeyGuard implements CanActivate {
  constructor(
    private readonly config: ConfigService,
    private readonly jwt: JwtService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<{
      headers: Record<string, string | string[] | undefined>;
    }>();
    const raw = req.headers['x-admin-key'];
    const key = (Array.isArray(raw) ? raw[0] : raw)?.trim();
    if (!key) {
      throw new UnauthorizedException('x-admin-key 헤더가 필요합니다.');
    }

    const legacy = this.config.get<string>('ADMIN_API_KEY')?.trim();
    if (legacy && legacy.length >= 16 && key === legacy) {
      return true;
    }

    try {
      const payload = this.jwt.verify<{ typ?: string }>(key);
      if (payload?.typ === ADMIN_JWT_TYP) {
        return true;
      }
    } catch {
      // fallthrough
    }

    throw new UnauthorizedException('관리자 토큰이 올바르지 않습니다.');
  }
}
