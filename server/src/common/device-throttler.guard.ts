import { Injectable } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';

const DEVICE_ID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * 按设备限流：优先使用客户端生成的安装 ID（x-device-id），缺失或格式不对时退回按 IP。
 *
 * 安装 ID 可以被伪造，它挡的是正常用户的连点和脚本小号；真正防刷还要在网关层叠加 IP 限流和全局配额。
 */
@Injectable()
export class DeviceThrottlerGuard extends ThrottlerGuard {
  protected override async getTracker(req: Record<string, any>): Promise<string> {
    const deviceId: unknown = req.headers?.['x-device-id'];
    if (typeof deviceId === 'string' && DEVICE_ID.test(deviceId)) {
      return `device:${deviceId.toLowerCase()}`;
    }
    return `ip:${String(req.ip)}`;
  }
}
