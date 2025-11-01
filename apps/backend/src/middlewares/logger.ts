import { randomUUID } from "node:crypto";
import { runWithRequestId } from "@packages/logger";
import { createMiddleware } from "hono/factory";

export const logger = createMiddleware(async (_, next) => {
	await runWithRequestId(randomUUID(), next);
});
