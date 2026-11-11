import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, MinLength, MaxLength, Matches, IsDateString, IsIn, IsOptional } from 'class-validator';

export class CreateUserDto {
  @ApiProperty({ example: 'test@test.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '1234' })
  @IsString()
  @MinLength(6)
  password: string;
  
  @ApiProperty({ example: '엄마 저 힘낼게요' })
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  nickname: string;
  
  @ApiProperty({ example: '2026-01-01' })
  @IsDateString()
  birthDate: string;
  
  @ApiProperty({ example: '남', enum: ['남', '여'] })
  @IsOptional()
  @IsString()
  @IsIn(['남', '여'])
  gender?: '남' | '여';
}
