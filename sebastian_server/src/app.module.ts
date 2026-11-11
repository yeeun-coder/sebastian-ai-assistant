import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from './user/user.module';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { AiModule } from './ai/ai.module';
import { TodoModule } from './todo/todo.module';
import { ScheduleModule } from './schedule/schedule.module';
import { RoutineModule } from './routine/routine.module';
import { DDayModule } from './dday/dday.module';
import { DiaryModule } from './diary/diary.module';
import { BriefingModule } from './briefing/briefing.module';
import { AdminModule } from './admin/admin.module';
import { PasswordResetModule } from './password-reset/password-reset.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env', '.env.local'],
    }),
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: 'db.sqlite',
      autoLoadEntities: true,
      synchronize: true,
    }),
    UsersModule,
    AuthModule,
    ChatModule,
    AiModule,
    TodoModule,
    ScheduleModule,
    RoutineModule,
    DDayModule,
    DiaryModule,
    BriefingModule,
    AdminModule,
    PasswordResetModule,
  ],
})
export class AppModule {}