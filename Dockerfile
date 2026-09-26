# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# Corepack 대신 npm을 통한 안정적인 pnpm 글로벌 설치
RUN npm install -g pnpm@12.6.0

# 패키지 명세 파일 복사
COPY package.json pnpm-lock.yaml prisma.config.js ./
COPY prisma ./prisma

# 프로덕션 및 개발 의존성 설치
RUN pnpm install --frozen-lockfile

# 소스 코드 복사
COPY src ./src

# Prisma 커스텀 클라이언트 빌드 실행 (src/generated/prisma 생성)
RUN pnpm prisma:generate

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 이미지)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

# 보안을 위한 비활성 시스템 디렉터리 권한 조정 및 node 유저 전환 준비
RUN mkdir -p /app && chown -R node:node /app

# pnpm 글로벌 설치
RUN npm install -g pnpm@12.6.0

# 1단계 Builder에서 생성된 프로덕션 필수 파일들만 복사
COPY package.json pnpm-lock.yaml prisma.config.js ./
COPY prisma ./prisma
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 의존성만 재설치
RUN pnpm install --prod --frozen-lockfile

# 보안 강화: 루트 권한 대신 알파인 기본 'node' 유저로 실행
USER node

# GCP Cloud Run 기본 포트 환경변수 명시
ENV PORT=5001
EXPOSE 5001

# 서버 구동 명령어
CMD ["node", "src/server.js"]