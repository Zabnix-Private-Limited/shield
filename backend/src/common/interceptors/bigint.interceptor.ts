import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BigIntInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map((data) => this.serialize(data)));
  }

  private serialize(obj: any): any {
    if (obj === null || obj === undefined) {
      return obj;
    }

    if (typeof obj === 'bigint') {
      return obj.toString();
    }

    if (typeof obj === 'object') {
      if (typeof obj.toJSON === 'function') {
        const json = obj.toJSON();
        return typeof json === 'object' ? this.serialize(json) : json;
      }

      if (Array.isArray(obj)) {
        return obj.map((item) => this.serialize(item));
      }

      const copy: Record<string, any> = {};
      for (const key of Object.keys(obj)) {
        copy[key] = this.serialize(obj[key]);
      }
      return copy;
    }

    return obj;
  }
}
