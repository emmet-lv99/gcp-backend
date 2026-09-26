import app from "./app.js";
import { config } from "#src/config/config.js";

const PORT = config.PORT;

const server = app.listen(PORT, () => {
  console.log(`🚀 백엔드 서버가 포트 ${PORT}에서 실행 중입니다. (${config.NODE_ENV} 모드)`);
  
  // 런타임에 진짜 DB 주소가 주입되었는지 마스킹하여 로그 출력
  const maskedDbUrl = config.DATABASE_URL.replace(/:[^:@]+@/, ":****@");
  console.log(`🔗 [DB Connection Check] 바인딩된 DB 주소: ${maskedDbUrl}`);
});

process.on("SIGTERM", () => {
  console.log("SIGTERM 신호 수신: 서버를 안전하게 종료합니다.");
  server.close(() => {
    process.exit(0);
  });
});