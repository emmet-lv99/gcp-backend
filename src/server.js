import app from "./app.js"
import { config } from "./config/config.js"

const PORT = config.PORT

const server = app.listen(PORT, () => {
  console.log(`🚀 백엔드 서버가 포트 ${PORT}에서 실행 중입니다.`)
})

process.on("SIGTERM", () => {
  console.log("SIGTERM 신호 수신: 서버를 안전하게 종료합니다.")
  server.close(() => {
    console.log("HTTP 서버 프로세스가 성공적으로 종료되었습니다.")
    process.exit(0)
  })
})
