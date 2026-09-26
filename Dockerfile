# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# pnpm 공식 환경 변수 및 전역 경로 설정
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# Corepack 활성화 및 pnpm 환경 강제 주입
RUN corepack enable && corepack prepare pnpm@12.6.0 --activate

# 패키지 명세 파일 및 설정 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# 의존성 설치 (pnpm 경로가 PATH에 확실히 잡힌 상태에서 실행)
RUN pnpm install --frozen-lockfile

# 소스 코드 복사
COPY src ./src

# Prisma 커스텀 클라이언트 빌드 실행
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