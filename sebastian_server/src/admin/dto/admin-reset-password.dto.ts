import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class AdminResetPasswordDto {
  @ApiProperty({ example: 'TempPass123!', minLength: 6 })
  @IsString()
  @MinLength(6, { message: '비밀번호는 6자 이상이어야 합니다.' })
  newPassword!: string;
}
