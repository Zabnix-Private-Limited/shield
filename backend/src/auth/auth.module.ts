import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { MockAuthGuard } from './mock-auth.guard';

@Module({
  controllers: [AuthController],
  providers: [MockAuthGuard],
  exports: [MockAuthGuard],
})
export class AuthModule {}
