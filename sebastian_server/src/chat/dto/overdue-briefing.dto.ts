import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class OverdueBriefingItemDto {
  @ApiProperty({ example: '회의 준비', description: '지난 일정 제목' })
  @IsString()
  @MaxLength(200)
  title: string;

  @ApiPropertyOptional({
    example: '6월 1일 오후 2시 30분',
    description: '사람이 읽는 시작 시각 표기 (선택)',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  startTime?: string;
}

export class OverdueBriefingDto {
  @ApiProperty({
    type: [OverdueBriefingItemDto],
    description: '브리핑할 지난(미완료) 일정 목록',
  })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OverdueBriefingItemDto)
  items: OverdueBriefingItemDto[];
}
