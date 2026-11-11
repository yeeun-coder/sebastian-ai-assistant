import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { PersonaListItemDto } from './persona-list-item.dto';

export class PersonaProfileResponseDto {
  @ApiPropertyOptional({ nullable: true })
  activePersonaId: number | null;

  @ApiPropertyOptional({ nullable: true })
  personaNickname: string | null;

  @ApiPropertyOptional({ type: PersonaListItemDto, nullable: true })
  activePersona: PersonaListItemDto | null;
}
