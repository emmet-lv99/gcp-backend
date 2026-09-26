import { HttpException } from "./http-exception.js";

export class ForbiddenException extends HttpException {
  constructor(description = "FORBIDDEN") {
    super(403, description);
  }
}