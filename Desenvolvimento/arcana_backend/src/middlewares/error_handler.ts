import type { Context } from 'hono';
import { ZodError } from 'zod';
import type { Env, HonoVariables } from '../types/env';

export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly code: string,
    message: string,
  ) {
    super(message);
  }
}

/**
 * Handler global de exceções sem vazar stack trace nem detalhes de banco de dados.
 */
export function handleGlobalError(
  err: unknown,
  c: Context<{ Bindings: Env; Variables: HonoVariables }>,
): Response {
  if (err instanceof AppError) {
    return c.json(
      {
        ok: false,
        error: err.code,
        message: err.message,
      },
      err.statusCode as 400 | 401 | 403 | 404 | 409 | 423 | 429 | 500,
    );
  }

  if (err instanceof ZodError) {
    return c.json(
      {
        ok: false,
        error: 'VALIDATION_ERROR',
        message: 'Dados de entrada invalidos.',
        details: err.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      },
      400,
    );
  }

  return c.json(
    {
      ok: false,
      error: 'INTERNAL_SERVER_ERROR',
      message: 'Falha interna ao processar operacao.',
    },
    500,
  );
}

