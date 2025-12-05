import type { ApiResponse } from '../types';

export function success<T>(data: T, status = 200): Response {
  const body: ApiResponse<T> = {
    success: true,
    data,
    meta: {
      request_id: generateRequestId(),
      processing_time_ms: 0, // Would be calculated in middleware
    },
  };

  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function error(code: string, message: string, status = 400, details?: unknown): Response {
  const body: ApiResponse<never> = {
    success: false,
    error: { code, message, details },
    meta: {
      request_id: generateRequestId(),
      processing_time_ms: 0,
    },
  };

  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function notFound(message = 'Resource not found'): Response {
  return error('NOT_FOUND', message, 404);
}

export function badRequest(message: string, details?: unknown): Response {
  return error('VALIDATION_ERROR', message, 400, details);
}

export function serverError(message = 'Internal server error'): Response {
  return error('SERVER_ERROR', message, 500);
}

function generateRequestId(): string {
  return `req_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 9)}`;
}
