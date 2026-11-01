import 'reflect-metadata';
import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  configureApp(app);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
  const mode = process.env.LLM_API_KEY ? '真实模型' : '模拟模式';
  new Logger('Bootstrap').log(`镜头本转发服务已启动：http://localhost:${port}（${mode}）`);
}

void bootstrap();
