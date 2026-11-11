import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class SendChatMessageDto {
  @ApiProperty({ example: '안녕', description: '사용자가 보낸 메시지 본문' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(8000)
  message: string;

  /**
   * 이번 한 번의 AI 호출에만 시스템 프롬프트로 덧붙이는 컨텍스트 (예: 미루기 대상 일정 정보).
   * DB 채팅 로그에는 저장하지 않습니다.
   */
  @ApiPropertyOptional({
    description:
      '이번 호출에만 시스템 프롬프트에 주입할 컨텍스트. DB에는 저장되지 않음.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  contextHint?: string;
}
