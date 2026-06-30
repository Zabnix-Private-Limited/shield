import { Injectable, Logger } from '@nestjs/common';
import { getAppEnv } from '../config/app-env';
import { readFileSync, existsSync } from 'fs';
import {
  App,
  cert,
  getApps,
  initializeApp,
} from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getMessaging } from 'firebase-admin/messaging';

type ServiceAccountJson = {
  project_id?: string;
  client_email?: string;
  private_key?: string;
};

@Injectable()
export class FirebaseAdminService {
  private readonly logger = new Logger(FirebaseAdminService.name);
  private app: App | null = null;
  private initializationAttempted = false;

  private getOrInitializeApp() {
    if (this.app) {
      return this.app;
    }

    if (this.initializationAttempted) {
      return null;
    }

    this.initializationAttempted = true;

    const credentials = this.loadCredentials();
    if (!credentials) {
      this.logger.warn(
        'Firebase Admin credentials are unavailable; push delivery will stay disabled.',
      );
      return null;
    }

    const existing = getApps().find((app) => app.name === 'shield-admin');
    this.app =
      existing ??
      initializeApp(
        {
          credential: cert({
            projectId: credentials.projectId,
            clientEmail: credentials.clientEmail,
            privateKey: credentials.privateKey,
          }),
        },
        'shield-admin',
      );

    this.logger.log(
      `Firebase Admin initialized for project ${credentials.projectId}.`,
    );

    return this.app;
  }

  private loadCredentials() {
    const env = getAppEnv();
    const serviceAccountJson = env.firebaseServiceAccountJson.trim();
    if (serviceAccountJson) {
      try {
        const json = JSON.parse(serviceAccountJson) as ServiceAccountJson;
        if (json.project_id && json.client_email && json.private_key) {
          return {
            projectId: json.project_id,
            clientEmail: json.client_email,
            privateKey: json.private_key,
          };
        }
        this.logger.warn(
          'FIREBASE_SERVICE_ACCOUNT_JSON is present but missing required Firebase Admin fields.',
        );
      } catch (error) {
        this.logger.warn(
          `FIREBASE_SERVICE_ACCOUNT_JSON could not be parsed: ${error}`,
        );
      }
    }

    if (
      env.firebaseProjectId &&
      env.firebaseClientEmail &&
      env.firebasePrivateKey
    ) {
      return {
        projectId: env.firebaseProjectId,
        clientEmail: env.firebaseClientEmail,
        privateKey: env.firebasePrivateKey,
      };
    }

    const configuredPath = env.firebaseServiceAccountPath.trim();
    const candidatePaths = [configuredPath].filter(Boolean);

    for (const candidatePath of candidatePaths) {
      if (!existsSync(candidatePath)) {
        continue;
      }

      try {
        const raw = readFileSync(candidatePath, 'utf8');
        const json = JSON.parse(raw) as ServiceAccountJson;
        if (json.project_id && json.client_email && json.private_key) {
          return {
            projectId: json.project_id,
            clientEmail: json.client_email,
            privateKey: json.private_key,
          };
        }
      } catch (error) {
        this.logger.warn(
          `Firebase Admin credential file could not be read from ${candidatePath}: ${error}`,
        );
      }
    }

    return null;
  }

  isConfigured() {
    return this.getOrInitializeApp() != null;
  }

  async sendToTokens(
    tokens: string[],
    payload: {
      title: string;
      body: string;
      data?: Record<string, string>;
    },
  ) {
    if (tokens.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    const app = this.getOrInitializeApp();
    if (!app) {
      return { successCount: 0, failureCount: tokens.length };
    }

    const messaging = getMessaging(app);
    return messaging.sendEachForMulticast({
      tokens,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
    });
  }

  async verifyIdToken(idToken: string) {
    const normalized = idToken.trim();
    if (!normalized) {
      throw new Error('Firebase ID token is required.');
    }

    const app = this.getOrInitializeApp();
    if (!app) {
      throw new Error('Firebase Admin credentials are unavailable.');
    }

    try {
      return await getAuth(app).verifyIdToken(normalized, true);
    } catch (error: any) {
      this.logger.warn(
        `Firebase ID token verification failed for project ${app.options.projectId}: ${error?.code ?? error}`,
      );
      throw error;
    }
  }
}
