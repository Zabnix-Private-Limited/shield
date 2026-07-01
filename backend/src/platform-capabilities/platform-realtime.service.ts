import { Injectable } from '@nestjs/common';
import { Observable, Subject, merge, of } from 'rxjs';
import { filter, map } from 'rxjs/operators';

export type PlatformRealtimeEvent = {
  id: string;
  type: string;
  category: string;
  title: string;
  description: string;
  workspace: string;
  customerId?: string;
  appointmentId?: string;
  reportId?: string;
  templateId?: string;
  timestamp: string;
  metadata?: Record<string, unknown>;
};

@Injectable()
export class PlatformRealtimeService {
  private readonly eventBus = new Subject<PlatformRealtimeEvent>();

  publish(event: Omit<PlatformRealtimeEvent, 'timestamp'> & { timestamp?: string }) {
    const normalized: PlatformRealtimeEvent = {
      ...event,
      timestamp: event.timestamp ?? new Date().toISOString(),
    };
    this.eventBus.next(normalized);
    return normalized;
  }

  stream(workspace: string, customerId?: string): Observable<{ data: PlatformRealtimeEvent }> {
    const normalizedWorkspace = workspace.trim().toLowerCase();
    const initial = of({
      data: {
        id: `connected:${normalizedWorkspace}`,
        type: 'STREAM_CONNECTED',
        category: 'system',
        title: 'Realtime stream connected',
        description: `Realtime stream is active for ${normalizedWorkspace}.`,
        workspace: normalizedWorkspace,
        customerId,
        timestamp: new Date().toISOString(),
        metadata: { state: 'connected' },
      } satisfies PlatformRealtimeEvent,
    });

    const events = this.eventBus.asObservable().pipe(
      filter((event) => {
        if (event.workspace !== normalizedWorkspace && event.workspace !== 'all') {
          return false;
        }
        if (customerId && event.customerId && event.customerId !== customerId) {
          return false;
        }
        return true;
      }),
      map((event) => ({ data: event })),
    );

    return merge(initial, events).pipe(filter(Boolean));
  }
}
