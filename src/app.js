// src/app.js
import express from "express";
import { errorHandler } from "./middlewares/error-handler.middleware.js";
import { HttpException } from "./errors/http-exception.js";

const app = express();

app.use(express.json());

// 1. 루트 경로(/) 접속 시 응답할 Welcome 라우터 추가
app.get("/", (req, res) => {
  res.status(200).json({
    success: true,
    message: "🚀 GCP Backend API Server is running successfully!",
  });
});

// 2. 인프라 상태 확인용 헬스체크 라우터
app.get("/health", (req, res) => {
  res.status(200).json({
    success: true,
    data: new Date().toISOString(),
    message: "헬스체크 정상",
  });
});

// 추후 도메인별 라우터가 추가될 공간입니다.
// app.use("/api/v1", routes);

// 3. [핵심] 등록되지 않은 모든 API 경로에 대한 404 Not Found 처리
app.use((req, res, next) => {
  // Express의 기본 "Cannot GET /..." 텍스트 응답 대신 커스텀 예외를 발생시킵니다.
  next(new HttpException(404, `존재하지 않는 API 경로입니다: ${req.method} ${req.originalUrl}`, "ROUTE_NOT_FOUND"));
});

// 4. 전역 에러 핸들러 (반드시 가장 마지막에 위치해야 합니다)
app.use(errorHandler);

export default app;