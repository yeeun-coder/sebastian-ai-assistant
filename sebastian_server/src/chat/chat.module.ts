import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatMessages } from './chat_messages.entity';
import { Persona } from './persona.entity';
import { User } from '../user/user.entity';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { PersonaSeedService } from './persona-seed.service';
import { AiModule } from '../ai/ai.module';
import { ScheduleModule } from '../schedule/schedule.module';
import { TodoModule } from '../todo/todo.module';
import { RoutineModule } from '../routine/routine.module';
import { DiaryModule } from '../diary/diary.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChatMessages, Persona, User]),
    AiModule,
    ScheduleModule,
    TodoModule,
    RoutineModule,
    DiaryModule,
  ],
  controllers: [ChatController],
  providers: [ChatService, PersonaSeedService],
  exports: [ChatService],
})
export class ChatModule {}
