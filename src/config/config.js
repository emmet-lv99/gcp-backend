import { flattenError, z } from "zod"

const envSchema = z.object({
  NODE_ENV: z
    .enum(["development", "production", "test"])
    .default("development"),
  PORT: z.coerce.number().int().min(1000).max(65535).default(5001),
  DATABASE_URL: z
    .string({ required_error: "DATABASE_URL은 필수 환경 변수입니다." })
    .regex(
      /^(postgresql|postgres):\/\/.+/,
      "DATABASE_URL은 'postgresql://' 또는 'postgres://' 형식의 올바른 연결 주소여야 합니다.",
    ),
  DIRECT_URL: z
    .string({ required_error: "DIRECT_URL은 필수 환경 변수입니다." })
    .regex(
      /^(postgresql|postgres):\/\/.+/,
      "DIRECT_URL은 'postgresql://' 또는 'postgres://' 형식의 올바른 연결 주소여야 합니다.",
    ),
})

const parseEnvironment = () => {
  try {
    return envSchema.parse({
      NODE_ENV: process.env.NODE_ENV,
      PORT: process.env.PORT,
      DATABASE_URL: process.env.DATABASE_URL,
      DIRECT_URL: process.env.DIRECT_URL,
    })
  } catch (error) {
    if (error instanceof z.ZodError) {
      // Zod 에러를 가독성 높은 객체 형태로 변환하여 출력
      console.error("❌ [Fatal Error] 환경 변수 검증에 실패했습니다:")
      console.error(JSON.stringify(flattenError(error).fieldErrors, null, 2))
    } else {
      console.error("❌ [Fatal Error] 알 수 없는 환경 변수 에러:", error)
    }

    // throw error 대신 Exit Code 1을 넘겨 프로세스를 명시적으로 즉시 종료
    process.exit(1)
  }
}

export const config = parseEnvironment()

export const isDevelopment = config.NODE_ENV === "development"
export const isProduction = config.NODE_ENV === "production"
export const isTest = config.NODE_ENV === "test"
