import { isDevelopment } from "#src/config/config.js"
import { HttpException } from "#src/errors/http-exception.js"

export const errorHandler = (error, _req, res, _next) => {
  console.error("error", error)

  if (error instanceof SyntaxError && error.status === 400) {
    return res.status(400).json({
      success: false,
      message: "요청 본문이 올바른 JSON 형식이 아닙니다.",
    })
  }

  if (error instanceof HttpException) {
    // TODO: isDevelopment 일 때 에러 메시지 자세히
    return res.status(error.statusCode).json({
      success: false,
      message: error.message,
    })
  }

  const result = {
    success: false,
    message: "Internal Server Error",
  }

  if (isDevelopment) {
    result.details = {
      name: error.name,
      message: error.message,
      stack: error.stack,
    }
  }

  return res.status(500).json(result)
}
