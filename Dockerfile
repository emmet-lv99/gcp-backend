# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# Corepack을 사용하지 않고 pnpm 독립형 정적 바이너리를 시스템에 직접 다운로드 및 권한 부여
RUN wget -qO /usr/local/bin/pnpm https://github.com/pnpm/pnpm/releases/download/v12.6.0/pnpm-linux-static-x64 \
    && chmod +x /usr/local/bin/pnpm

# 패키지 명세 파일 및 설정 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
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

# Runner 스테이지에도 동일한 pnpm 정적 바이너리 장착
RUN wget -qO /usr/local/bin/pnpm https://github.com/pnpm/pnpm/releases/download/v12.6.0/pnpm-linux-static-x64 \
    && chmod +x /usr/local/bin/pnpm

# 패키지 명세 파일 복사
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml prisma.config.js ./
COPY prisma ./prisma

# 1단계 Builder에서 생성된 소스코드 및 Prisma 클라이언트 결과물 복사
COPY --from=builder /app/src ./src
COPY --from=builder /app/src/generated ./src/generated

# 오직 프로덕션(dependencies) 페이로드만 재설치하여 이미지 용량 최적화
RUN pnpm install --prod --frozen-lockfile

# 보안 강화: 루트 권한 대신 알파인 기본 'node' 유저로 실행
USER node

# GCP Cloud Run 기본 포트 환경변수 명시 (기본값 5001 호환)
ENV PORT=5001
EXPOSE 5001

# 서버 구동 명령어 (Node.js 네이티브 런타임 실행)
CMD ["node", "src/server.js"]