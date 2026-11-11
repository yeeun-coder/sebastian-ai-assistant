import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

export class UpdatePersonaProfileDto {
  @ApiPropertyOptional({
    description:
      '활성 페르소나 ID. 생략하면 변경 없음, null이면 해제',
    nullable: true,
    example: 1,
  })
  @IsOptional()
  @ValidateIf((_, v) => v !== null && v !== undefined)
  @Type(() => Number)
  @IsInt()
  @Min(1)
  activePersonaId?: number | null;

  @ApiPropertyOptional({
    description: '페르소나 호칭(별명). 빈 문자열이면 null로 저장',
    example: '세바스찬',
    maxLength: 100,
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  personaNickname?: string | null;
}
