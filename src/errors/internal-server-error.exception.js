import { HttpException } from './http-exception.js';

export class InternalServerErrorException extends HttpException {
  constructor(description = 'SERVER_ERROR') {
    super(500, description);
  }
}
