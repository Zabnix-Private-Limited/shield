import {
  Controller,
  Get,
  Post,
  Param,
  Body,
} from '@nestjs/common';
import { CreditService } from './credit.service';

@Controller('credit/accounts')
export class CreditController {
  constructor(private creditService: CreditService) {}

  @Get(':id')
  async getAccount(@Param('id') id: string) {
    const data = await this.creditService.getCreditAccount(BigInt(id));
    return {
      success: true,
      message: 'Credit account details retrieved',
      data,
    };
  }

  @Get(':id/transactions')
  async getTransactions(@Param('id') id: string) {
    const txns = await this.creditService.getTransactions(BigInt(id));
    return {
      success: true,
      message: 'Credit transactions retrieved',
      data: txns,
    };
  }

  @Post(':id/approve')
  async approve(@Param('id') id: string, @Body() body: any) {
    const account = await this.creditService.approveLimitIncrease(
      BigInt(id),
      Number(body.amount),
      body.remarks,
    );
    return {
      success: true,
      message: 'Credit limit increase approved',
      data: account,
    };
  }
}
