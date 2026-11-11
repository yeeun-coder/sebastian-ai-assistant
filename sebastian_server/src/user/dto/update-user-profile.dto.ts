import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, IsDateString, IsInt, Min, Max } from 'class-validator';

export class UpdateUserProfileDto {
  @ApiPropertyOptional({ example: '엄마 저 힘낼게요' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  nickname?: string;

  @ApiPropertyOptional({ example: '2026-01-01' })
  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @ApiPropertyOptional({ example: 30, description: '만 나이 (birthDate 미전송 시 생년월일로 변환)' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(150)
  age?: number;

  @ApiPropertyOptional({ example: '남', enum: ['남', '여'] })
  @IsOptional()
  @IsString()
  @IsIn(['남', '여'])
  gender?: '남' | '여';

  @ApiPropertyOptional({
    example: 'https://cdn.example.com/profile/me.png',
    description: '사용자 프로필 이미지 URL',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  profileImage?: string;
}
