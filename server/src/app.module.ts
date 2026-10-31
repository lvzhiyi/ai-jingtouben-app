import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerModule } from '@nestjs/throttler';
import { DeviceThrottlerGuard } from './common/device-throttler.guard';
import { HealthController } from './health.controller';
import { StoryboardModule } from './storyboard/storyboard.module';
import { TemplatesModule } from './templates/templates.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        { ttl: 60_000, limit: Number(config.get('RATE_LIMIT_PER_MINUTE') ?? 10) },
      ],
    }),
    StoryboardModule,
    TemplatesModule,
  ],
  controllers: [HealthController],
  providers: [{ provide: APP_GUARD, useClass: DeviceThrottlerGuard }],
})
export class AppModule {}
