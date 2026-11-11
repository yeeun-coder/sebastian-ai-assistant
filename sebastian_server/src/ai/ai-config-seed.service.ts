import { Injectable, Logger, OnApplicationBootstrap } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AiConfig } from './ai-config.entity';

@Injectable()
export class AiConfigSeedService implements OnApplicationBootstrap {
  private readonly logger = new Logger(AiConfigSeedService.name);

  constructor(
    @InjectRepository(AiConfig)
    private readonly repo: Repository<AiConfig>,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    const count = await this.repo.count();
    if (count > 0) return;

    await this.repo.save([
      {
        provider: 'claude',
        model: 'claude-sonnet-4-20250514',
        apiKey: '',
        isActive: true,
      },
      {
        provider: 'openai',
        model: 'gpt-4o-mini',
        apiKey: '',
        isActive: false,
      },
      {
        provider: 'gemini',
        model: 'gemini-2.0-flash',
        apiKey: '',
        isActive: false,
      },
    ]);

    this.logger.log('AI 설정 초기 데이터 3건 생성 (claude, openai, gemini)');
  }
}
