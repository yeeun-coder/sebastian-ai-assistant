import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { UsersModule } from '../user/user.module';
import { AdminController } from './admin.controller';
import { AdminApiKeyGuard } from './admin-api-key.guard';
import { PasswordResetModule } from '../password-reset/password-reset.module';

@Module({
  imports: [
    UsersModule,
    PasswordResetModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        secret: cfg.get<string>('JWT_SECRET') ?? 'secretKey',
        signOptions: { expiresIn: '8h' },
      }),
    }),
  ],
  controllers: [AdminController],
  providers: [AdminApiKeyGuard],
})
export class AdminModule {}
