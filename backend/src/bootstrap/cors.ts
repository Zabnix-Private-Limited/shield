import type { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';
import type { NextFunction, Request, Response } from 'express';
import type { ShieldAppEnv } from '../config/app-env';
import { getAppEnv } from '../config/app-env';

const CORS_METHODS = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'] as const;
const CORS_HEADERS = [
  'Content-Type',
  'Authorization',
  'sentry-trace',
  'baggage',
  'Accept',
] as const;
const CORS_MAX_AGE_SECONDS = 86400;

export function createShieldCorsOptions(
  env: ShieldAppEnv = getAppEnv(),
): CorsOptions {
  return {
    origin: (
      origin: string | undefined,
      callback: (error: Error | null, allow?: boolean) => void,
    ) => {
      if (isAllowedCorsOrigin(origin, env)) {
        callback(null, true);
        return;
      }

      callback(new Error(`Origin not allowed by CORS: ${origin}`), false);
    },
    methods: [...CORS_METHODS],
    allowedHeaders: [...CORS_HEADERS],
    credentials: true,
    maxAge: CORS_MAX_AGE_SECONDS,
    optionsSuccessStatus: 204,
    preflightContinue: false,
  };
}

export function createImmediatePreflightHandler(
  env: ShieldAppEnv = getAppEnv(),
) {
  return (request: Request, response: Response, next: NextFunction) => {
    if (request.method.toUpperCase() !== 'OPTIONS') {
      next();
      return;
    }

    const origin = request.headers.origin?.toString();
    if (!isAllowedCorsOrigin(origin, env)) {
      response.status(403).send('Origin not allowed by CORS');
      return;
    }

    if (origin != null && origin.trim().length > 0) {
      response.setHeader('Access-Control-Allow-Origin', origin);
    }

    response.setHeader(
      'Vary',
      'Origin, Access-Control-Request-Method, Access-Control-Request-Headers',
    );
    response.setHeader('Access-Control-Allow-Credentials', 'true');
    response.setHeader('Access-Control-Allow-Methods', CORS_METHODS.join(', '));
    response.setHeader('Access-Control-Allow-Headers', CORS_HEADERS.join(', '));
    response.setHeader(
      'Access-Control-Max-Age',
      CORS_MAX_AGE_SECONDS.toString(),
    );
    response.status(204).send();
  };
}

export function isAllowedCorsOrigin(
  origin?: string,
  env: ShieldAppEnv = getAppEnv(),
) {
  if (!origin || origin === 'null') {
    return true;
  }

  const allowedOrigins = new Set<string>(
    [env.appUrl, ...env.corsOrigins]
      .map((value) => {
        try {
          return new URL(value).origin;
        } catch (_) {
          return value.trim();
        }
      })
      .filter(Boolean),
  );

  if (allowedOrigins.has(origin)) {
    return true;
  }

  try {
    const uri = new URL(origin);
    const hostname = uri.hostname.toLowerCase();
    return (
      uri.protocol === 'https:' &&
      hostname.endsWith('.vercel.app') &&
      hostname.startsWith('shield-')
    );
  } catch (_) {
    return false;
  }
}
