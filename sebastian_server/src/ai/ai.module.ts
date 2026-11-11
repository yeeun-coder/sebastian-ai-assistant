import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiConfig } from './ai-config.entity';
import { AiUsage } from './ai-usage.entity';
import { User } from '../user/user.entity';
import { AiProviderService } from './ai-provider.service';
import { AiConfigSeedService } from './ai-config-seed.service';
import { AiController } from './ai.controller';

@Module({
  imports: [TypeOrmModule.forFeature([AiConfig, AiUsage, User])],
  controllers: [AiController],
  providers: [AiProviderService, AiConfigSeedService],
  exports: [AiProviderService],
})
export class AiModule {}
