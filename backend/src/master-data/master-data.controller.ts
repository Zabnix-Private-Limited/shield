import { Controller, Get, Param } from '@nestjs/common';
import { RequirePermissions } from '../auth/permissions.decorator';
import { MasterDataService } from './master-data.service';

@Controller('master-data')
export class MasterDataController {
  constructor(private readonly masterDataService: MasterDataService) {}

  @RequirePermissions('settings.view')
  @Get('admin/catalog')
  async getCatalog() {
    return {
      success: true,
      message: 'Master data catalog retrieved successfully.',
      data: await this.masterDataService.getCatalog(),
    };
  }

  @RequirePermissions('settings.view')
  @Get('admin/bootstrap')
  async getBootstrapSnapshot() {
    return {
      success: true,
      message: 'Master data bootstrap snapshot retrieved successfully.',
      data: await this.masterDataService.getBootstrapSnapshot(),
    };
  }

  @RequirePermissions('settings.view')
  @Get('admin/:domain')
  async getDomainDataset(@Param('domain') domain: string) {
    return {
      success: true,
      message: `Master data domain "${domain}" retrieved successfully.`,
      data: await this.masterDataService.getDomainDataset(domain),
    };
  }
}
