# ==========================================
# Stage 1: Builder (의존성 설치)
# ==========================================
FROM node:24.2-alpine AS builder

WORKDIR /app

# 패키지 명세 및 설정 파일 복사
COPY package.json prisma.config.js ./
COPY prisma ./prisma

# 스크립트 자동 실행을 차단하여 빌드 타임 환경 변수 에러 원천 차단
RUN npm install --ignore-scripts

# 전체 소스 코드 복사
COPY . .

# ==========================================
# Stage 2: Runner (실제 프로덕션 실행 이미지)
# ==========================================
FROM node:24.2-alpine AS runner

WORKDIR /app

# 보안을 위한 논루트(non-root) node 유저 권한 세팅
RUN mkdir -p /app && chown -R node:node /app

# 프로덕션 필수 파일 및 소스 코드 복사
COPY package.json prisma.config.js ./
COPY prisma ./prisma
COPY src ./src

# 프로덕션 전용 의존성만 설치 (--ignore-scripts 적용)
RUN npm install --omit=dev --ignore-scripts

# 보안 강화: node 유저로 프로세스 실행
USER node

ENV PORT=5001
EXPOSE 5001

CMD ["npm", "start"]