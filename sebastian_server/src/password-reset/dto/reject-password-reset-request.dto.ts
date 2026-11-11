import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class RejectPasswordResetRequestDto {
  @ApiPropertyOptional({ example: '본인 확인 실패' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  memo?: string;
}
