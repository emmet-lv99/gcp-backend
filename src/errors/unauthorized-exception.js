import { HttpException } from './http-exception.js';

export class UnauthorizedException extends HttpException {
  constructor(description = 'unauthorized') {
    super(401, description);
  }
}
