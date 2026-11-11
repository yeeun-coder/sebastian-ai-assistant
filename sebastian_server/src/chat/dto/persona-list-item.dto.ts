import { ApiProperty } from '@nestjs/swagger';

/** 목록/선택 UI용 (system_prompt 제외) */
export class PersonaListItemDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  type: string;

  @ApiProperty()
  name: string;

  @ApiProperty()
  description: string;

  @ApiProperty()
  image: string;
}
