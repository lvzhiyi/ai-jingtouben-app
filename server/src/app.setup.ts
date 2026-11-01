import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';

/** 应用级配置。main.ts 和端到端测试共用，保证测试跑的是线上同一套校验、跨域和代理设置。 */
export function configureApp(app: NestExpressApplication): void {
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
}
