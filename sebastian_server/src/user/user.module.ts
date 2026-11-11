import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './user.entity';
import { Persona } from '../chat/persona.entity';
import { ChatMessages } from '../chat/chat_messages.entity';
import { AiModule } from '../ai/ai.module';
import { PersonalityTagsService } from './personality-tags.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, Persona, ChatMessages]),
    AiModule,
  ],
  controllers: [UsersController],
  providers: [UsersService, PersonalityTagsService],
  exports: [UsersService], // 🔥 중요 (auth에서 사용)
})
export class UsersModule {}