/**
 * Input Validation Middleware
 * Uses express-validator for request validation
 */
import { validationResult } from 'express-validator';
import { ApiError } from './errorHandler.js';

/**
 * Middleware to check validation results
 * Place after express-validator check chains
 */
export function validate(req, res, next) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    const messages = errors.array().map(e => `${e.path}: ${e.msg}`);
    throw ApiError.badRequest('Validation failed', messages);
  }
  next();
}
