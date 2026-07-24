export class AppError extends Error {
  status: number;
  code: string;
  constructor(status: number, code: string, message: string) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

export const errors = {
  badRequest: (m = "Bad request") => new AppError(400, "BAD_REQUEST", m),
  unauthorized: (m = "Unauthorized") => new AppError(401, "UNAUTHORIZED", m),
  forbidden: (m = "Forbidden") => new AppError(403, "FORBIDDEN", m),
  notFound: (m = "Not found") => new AppError(404, "NOT_FOUND", m),
  conflict: (m = "Conflict") => new AppError(409, "CONFLICT", m),
  tooLarge: (m = "Payload too large") => new AppError(413, "TOO_LARGE", m),
};
