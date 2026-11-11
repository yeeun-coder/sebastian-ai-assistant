import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UserProfileResponseDto {
  @ApiProperty({ example: '세바스찬3세님' })
  nickname: string;

  @ApiProperty({ example: 25 })
  age: number;

  @ApiProperty({ example: '1995-01-01' })
  birthDate: string;

  @ApiProperty({ example: '남', enum: ['남', '여'] })
  gender: '남' | '여';

  @ApiProperty({
    example: ['귀여움', '친절함', '짜증이 없음', '자주 웃', '3세'],
    type: [String],
  })
  tags: string[];

  @ApiPropertyOptional({
    example: 'https://cdn.example.com/profile/me.png',
    nullable: true,
  })
  profileImage?: string | null;
}
