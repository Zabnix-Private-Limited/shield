import {
  BadRequestException,
  Body,
  Controller,
  Post,
  Req,
} from '@nestjs/common';
import type { Request } from 'express';
import { Public } from '../auth/public.decorator';
import { SupportService } from './support.service';
import { TurnstileService } from './turnstile.service';

function parseChannel(value: unknown) {
  return value?.toString().trim().toUpperCase() || 'WEB';
}

function parseCustomerId(value: unknown) {
  const raw = value?.toString().trim();
  if (!raw) {
    return undefined;
  }
  return BigInt(raw);
}

@Controller('support')
export class SupportController {
  constructor(
    private readonly supportService: SupportService,
    private readonly turnstileService: TurnstileService,
  ) {}

  @Public()
  @Post('contact')
  async submitContact(@Body() body: any, @Req() request: Request) {
    const name = body.name?.toString().trim() || '';
    const phone = body.phone?.toString().trim() || '';
    const email = body.email?.toString().trim() || '';
    const subject = body.subject?.toString().trim() || '';
    const message = body.message?.toString().trim() || '';
    const channel = parseChannel(body.channel);

    if (!name || !phone || !message) {
      throw new BadRequestException('name, phone, and message are required.');
    }

    let turnstileValidated = false;
    if (channel === 'WEB' && this.turnstileService.isConfigured()) {
      await this.turnstileService.assertValidToken(
        body.turnstile_token?.toString() || '',
        request.ip,
      );
      turnstileValidated = true;
    }

    const complaint = await this.supportService.submit({
      complaintType: 'CONTACT_US',
      customerId: parseCustomerId(body.customer_id),
      name,
      phone,
      email,
      subject,
      message,
      channel,
      turnstileValidated,
    });

    return {
      success: true,
      message: 'Contact request submitted successfully.',
      data: complaint,
    };
  }

  @Public()
  @Post('feedback')
  async submitFeedback(@Body() body: any, @Req() request: Request) {
    const message = body.message?.toString().trim() || '';
    const subject = body.subject?.toString().trim() || '';
    const channel = parseChannel(body.channel);
    const ratingRaw = body.rating?.toString().trim();
    const rating = ratingRaw ? Number(ratingRaw) : undefined;

    if (!message) {
      throw new BadRequestException('message is required.');
    }

    if (
      rating != null &&
      (!Number.isFinite(rating) || rating < 1 || rating > 5)
    ) {
      throw new BadRequestException('rating must be between 1 and 5.');
    }

    let turnstileValidated = false;
    if (channel === 'WEB' && this.turnstileService.isConfigured()) {
      await this.turnstileService.assertValidToken(
        body.turnstile_token?.toString() || '',
        request.ip,
      );
      turnstileValidated = true;
    }

    const complaint = await this.supportService.submit({
      complaintType: 'FEEDBACK',
      customerId: parseCustomerId(body.customer_id),
      name: body.name?.toString().trim() || '',
      phone: body.phone?.toString().trim() || '',
      email: body.email?.toString().trim() || '',
      subject,
      message,
      rating,
      channel,
      turnstileValidated,
    });

    return {
      success: true,
      message: 'Feedback submitted successfully.',
      data: complaint,
    };
  }
}
