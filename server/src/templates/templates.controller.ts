import { Controller, Get, Header } from '@nestjs/common';
import { SkipThrottle } from '@nestjs/throttler';
import templates from './prompt-templates.json';

/**
 * 下发各视频平台的提示词模板。平台写法变化时只改 prompt-templates.json 并发布服务端，客户端不用发版。
 * 客户端缓存最近一次结果，离线时使用缓存或安装包内置的同一份文件。
 */
@SkipThrottle()
@Controller('templates')
export class TemplatesController {
  @Get()
  @Header('Cache-Control', 'public, max-age=300')
  list(): typeof templates {
    return templates;
  }
}
