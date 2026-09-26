import { defineConfig, env } from "prisma/config"

export default defineConfig({
  schema: "prisma",
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    // 빌드 타임(Docker Build)에 DIRECT_URL이 없어도 멈추지 않도록 안전한 폴백(Fallback) 처리
    url: process.env.DIRECT_URL || env("DIRECT_URL") || "postgresql://postgres:dummy@localhost:5432/postgres",
  },
})