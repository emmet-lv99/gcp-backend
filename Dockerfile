# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# package.json 및 Prisma 설정 파일 복사
COPY package.json prisma.config.js ./
COPY prisma ./prisma

# 샌드박스 제약이 없는 npm을 통해 의존성 및 Prisma 엔진 완벽 설치
RUN npm install

# 전체 소스 코드 복사
COPY src ./src

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 이미지)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

# 보안을 위한 논루트(non-root) node 유저 권한 세팅
RUN mkdir -p /app && chown -R node:node /app

# 프로덕션 필수 파일 및 빌드 결과물 복사
COPY package.json prisma.config.js ./
COPY prisma ./prisma
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 전용 의존성만 가볍게 재설치
RUN npm install --omit=dev

# 보안 강화: node 유저로 프로세스 실행
USER node

ENV PORT=5001
EXPOSE 5001

CMD ["npm", "start"]