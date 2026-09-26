# ==========================================
# Stage 1: Builder (의존성 설치 및 Prisma Client 생성)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# 패키지 및 스키마 파일 복사
COPY package.json prisma.config.js ./
COPY prisma ./prisma

# 1. 자동 postinstall 실행을 막아 환경 변수 에러 방지
RUN npm install --ignore-scripts

COPY . .

# 2. [핵심] Alpine Linux용 Prisma Client 및 Rust 쿼리 엔진 바이너리 명시적 생성
#    (빌드 타임 검증 통과를 위한 더미 환경 변수 주입)
ENV DIRECT_URL="postgresql://postgres:dummy@localhost:5432/postgres"
ENV DATABASE_URL="postgresql://postgres:dummy@localhost:5432/postgres"
RUN npx prisma generate --schema=./prisma

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 컨테이너)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

# 보안을 위한 non-root node 유저 권한 세팅
RUN mkdir -p /app && chown -R node:node /app

COPY package.json prisma.config.js ./
COPY prisma ./prisma
COPY src ./src

# 3. [핵심] Builder 스테이지에서 생성된 Alpine Linux 전용 Prisma Client 결과물 복사
COPY --from=builder /app/src/generated ./src/generated

# 프로덕션 의존성 설치
RUN npm install --omit=dev --ignore-scripts

USER node

ENV PORT=5001
EXPOSE 5001

CMD ["npm", "start"]