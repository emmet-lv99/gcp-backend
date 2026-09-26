# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# pnpm 전역 경로 및 PATH 환경 변수 사전 고정 (Corepack 캐시 꼬임 방지)
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@12.6.0 --activate

# 패키지 명세 및 설정 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# pnpm 전용 의존성 설치 (postinstall 스크립트에 의해 prisma generate 자동 수행)
RUN pnpm install --frozen-lockfile

# 소스 코드 복사
COPY src ./src

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 이미지)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

RUN mkdir -p /app && chown -R node:node /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN corepack enable && corepack prepare pnpm@12.6.0 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# Builder에서 생성된 소스코드 및 Prisma 클라이언트 결과물 복사
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 의존성만 설치
RUN pnpm install --prod --frozen-lockfile

USER node

ENV PORT=5001
EXPOSE 5001

CMD ["node", "src/server.js"]