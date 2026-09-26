import { HttpException } from "./http-exception.js";

export class NotFoundException extends HttpException {
  constructor(description = "NOT_FOUND") {
    super(404, description);
  }
}