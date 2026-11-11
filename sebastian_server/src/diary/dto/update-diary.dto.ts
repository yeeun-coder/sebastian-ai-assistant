import { PartialType, OmitType } from '@nestjs/swagger';
import { CreateDiaryDto } from './create-diary.dto';

export class UpdateDiaryDto extends PartialType(
  OmitType(CreateDiaryDto, ['diaryDate'] as const),
) {}
