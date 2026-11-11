import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class ResolvePasswordResetRequestDto {
  @ApiProperty({ example: 'TempPass123!', minLength: 6 })
  @IsString()
  @MinLength(6, { message: '비밀번호는 6자 이상이어야 합니다.' })
  newPassword!: string;

  @ApiPropertyOptional({ example: '본인 확인 완료 후 초기화' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  memo?: string;
}
