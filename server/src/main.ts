import 'reflect-metadata';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const origins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  app.enableCors({
    origin: origins.length > 0 ? origins : true,
    methods: ['GET', 'POST'],
    allowedHeaders: ['content-type', 'x-device-id'],
  });

  // 部署在 Nginx 等反向代理后面时，req.ip 取真实客户端地址，按 IP 兜底限流才有效
  app.set('trust proxy', 1);
  app.enableShutdownHooks();

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  const mode = process.env.LLM_API_KEY ? '真实模型' : '模拟模式';
  new Logger('Bootstrap').log(`镜头本转发服务已启动：http://localhost:${port}（${mode}）`);
}

void bootstrap();
