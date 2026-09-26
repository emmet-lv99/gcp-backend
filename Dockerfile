# ==========================================
# 1. Node.js v24.2 베이스 이미지 사용
# ==========================================
FROM node:24.2-alpine

# 2. 컨테이너 내부 작업 디렉토리 설정
WORKDIR /app

# 3. 패키지 명세 파일 복사 (캐싱 최적화)
COPY package*.json ./

# 4. Prisma 설정 및 스키마 폴더 복사
COPY prisma.config.js ./
COPY prisma ./prisma/

# 5. npm을 통한 의존성 설치 (빌드 스크립트 및 바이너리 자동 승인)
RUN npm install

# 6. 전체 소스 코드 복사 (src, routes, services 등)
COPY . .

# 7. Prisma Client 생성 (src/generated/prisma 빌드)
RUN npm run prisma:generate

# 8. GCP Cloud Run 기본 포트 환경변수 명시 (기본값 5001 호환)
ENV PORT=5001
EXPOSE 5001

# 9. 서버 실행 (package.json의 "start": "node src/server.js")
CMD ["npm", "start"]