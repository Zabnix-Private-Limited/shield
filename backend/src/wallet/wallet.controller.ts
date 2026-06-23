import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { WalletService } from './wallet.service';
import { MockAuthGuard } from '../auth/mock-auth.guard';

@Controller('wallets')
@UseGuards(MockAuthGuard)
export class WalletController {
  constructor(private walletService: WalletService) {}

  @Get(':customerId')
  async getWallet(@Param('customerId') customerId: string) {
    const data = await this.walletService.getWalletByCustomerId(BigInt(customerId));
    return {
      success: true,
      message: 'Wallet profile retrieved successfully',
      data,
    };
  }

  @Post('recharge')
  async recharge(@Body() body: any, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : undefined;
    const txn = await this.walletService.recharge(
      BigInt(body.customer_id),
      Number(body.amount),
      staffId,
      body.remarks,
    );
    return {
      success: true,
      message: 'Wallet recharged successfully',
      data: txn,
    };
  }

  @Post('adjustments')
  async adjust(@Body() body: any, @Request() req: any) {
    const staffId = req.user.isStaff ? BigInt(req.user.id) : undefined;
    const txn = await this.walletService.adjust(
      BigInt(body.customer_id),
      Number(body.amount),
      body.type,
      staffId,
      body.remarks,
    );
    return {
      success: true,
      message: 'Wallet adjustment processed successfully',
      data: txn,
    };
  }

  @Get(':id/transactions')
  async getTransactions(
    @Param('id') id: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('type') type?: string,
  ) {
    const txns = await this.walletService.getTransactions(BigInt(id), {
      from,
      to,
      type,
    });
    return {
      success: true,
      message: 'Transactions feed retrieved',
      data: txns,
    };
  }
}
