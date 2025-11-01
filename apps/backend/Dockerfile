ARG BUN_VERSION=1.3.0

####################
# Builder

FROM oven/bun:${BUN_VERSION}-debian AS builder
WORKDIR /app

COPY . .

RUN bun install --frozen-lockfile

RUN bun build ./apps/backend/src/index.ts \
    --outfile ./server.js \
    --target bun

####################
# Runner

FROM oven/bun:${BUN_VERSION}-alpine AS runner
WORKDIR /app

COPY --from=builder /app/server.js ./

CMD ["bun", "run", "./server.js"]
