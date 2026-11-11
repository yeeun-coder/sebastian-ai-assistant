import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Routine } from './routine.entity';
import { RoutineCompletion } from './routine-completion.entity';
import { RoutineService } from './routine.service';
import { RoutineController } from './routine.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Routine, RoutineCompletion])],
  controllers: [RoutineController],
  providers: [RoutineService],
  exports: [TypeOrmModule, RoutineService],
})
export class RoutineModule {}
