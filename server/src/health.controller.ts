import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SkipThrottle } from '@nestjs/throttler';

@SkipThrottle()
@Controller('health')
export class HealthController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  check(): { ok: true; mode: 'live' | 'mock' } {
    return { ok: true, mode: this.config.get<string>('LLM_API_KEY') ? 'live' : 'mock' };
  }
}
