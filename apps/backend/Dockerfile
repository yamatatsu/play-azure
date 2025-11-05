ARG BUN_VERSION=1.3.0

####################
# Builder

FROM oven/bun:${BUN_VERSION}-debian AS builder
WORKDIR /app

COPY bun.lock ./
COPY package.json ./
COPY packages/db/package.json ./packages/db/
COPY packages/logger/package.json ./packages/logger/
COPY apps/backend/package.json ./apps/backend/
COPY apps/frontend/package.json ./apps/frontend/
COPY apps/iac/package.json ./apps/iac/

RUN bun install --frozen-lockfile

COPY . .

RUN bun build ./apps/backend/src/index.ts \
    --outfile ./server.js \
    --target bun

####################
# Runner

FROM oven/bun:${BUN_VERSION}-alpine AS runner
WORKDIR /app

COPY --from=builder /app/server.js ./

CMD ["bun", "run", "./server.js"]
