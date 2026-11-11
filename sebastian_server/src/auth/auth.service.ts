import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../user/users.service';
import bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async login(email: string, password: string) {
    const user = await this.usersService.findByEmail(email);
  
    if (!user) {
      throw new UnauthorizedException('유저 없음');
    }

    if (
      password == null ||
      typeof password !== 'string' ||
      password.length === 0
    ) {
      throw new UnauthorizedException('비밀번호를 입력해 주세요');
    }
    if (
      user.password == null ||
      typeof user.password !== 'string' ||
      user.password.length === 0
    ) {
      throw new UnauthorizedException('계정 정보가 올바르지 않습니다');
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      throw new UnauthorizedException('비밀번호 틀림');
    }

    const payload = { sub: user.id, email: user.email };

    return {
      access_token: this.jwtService.sign(payload),
    };
  }
}