import { PartialType } from '@nestjs/swagger';
import { CreateDDayDto } from './create-dday.dto';

export class UpdateDDayDto extends PartialType(CreateDDayDto) {}
