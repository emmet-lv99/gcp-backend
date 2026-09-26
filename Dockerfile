# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# pnpm 전역 경로 및 PATH 환경 변수 사전 고정
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Corepack 활성화 및 pnpm v12.6.0 지정 활성화
RUN corepack enable && corepack prepare pnpm@12.6.0 --activate

# 패키지 명세 파일 및 pnpm 워크스페이스, 설정 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# pnpm 전용 의존성 설치 (postinstall 스크립트에 의한 prisma generate 자동 수행 포함)
RUN pnpm install --frozen-lockfile

# 소스 코드 복사
COPY src ./src

# Prisma 커스텀 클라이언트 빌드 명시적 실행 (안전장치)
RUN pnpm prisma:generate

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 이미지)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

# 보안을 위한 시스템 유저 권한 설정
RUN mkdir -p /app && chown -R node:node /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@12.6.0 --activate

# 설정 및 소스 결과물 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 의존성만 설치
RUN pnpm install --prod --frozen-lockfile

# 보안 강화: 논루트(non-root) node 유저로 실행
USER node

ENV PORT=5001
EXPOSE 5001

CMD ["node", "src/server.js"]