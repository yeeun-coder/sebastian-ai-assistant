import { Module } from '@nestjs/common';
import { ScheduleModule } from '../schedule/schedule.module';
import { TodoModule } from '../todo/todo.module';
import { RoutineModule } from '../routine/routine.module';
import { BriefingService } from './briefing.service';
import { BriefingController } from './briefing.controller';

@Module({
  imports: [ScheduleModule, TodoModule, RoutineModule],
  controllers: [BriefingController],
  providers: [BriefingService],
})
export class BriefingModule {}
