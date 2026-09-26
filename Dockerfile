# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# pnpm 전역 경로 및 시스템 PATH 사전 고정 (모든 RUN 세션에서 공유됨)
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

# 공식 pnpm 설치 스크립트 실행 (다운로드 및 바이너리 링크 자동 구성)
RUN wget -qO- https://get.pnpm.io/install.sh | SHELL="$(which sh)" sh -

# 패키지 명세 파일 및 설정 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# 의존성 설치 (PATH가 고정되어 있으므로 pnpm 명령어가 즉시 인식됨)
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

# 보안을 위한 시스템 유저 권한 설정
RUN mkdir -p /app && chown -R node:node /app

# Runner 스테이지에도 동일한 pnpm 경로 환경변수 장착
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN wget -qO- https://get.pnpm.io/install.sh | SHELL="$(which sh)" sh -

# 패키지 명세 파일 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# 1단계 Builder에서 생성된 소스코드 및 Prisma 클라이언트 결과물 복사
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 의존성만 설치
RUN pnpm install --prod --frozen-lockfile

# 보안 강화: 논루트(non-root) node 유저로 실행
USER node

ENV PORT=5001
EXPOSE 5001

CMD ["node", "src/server.js"]