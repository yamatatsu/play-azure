import { Hono } from "hono";
import { logger } from "./middlewares/logger";
import rootRoutes from "./routes/root";

const app = new Hono()
	// middlewares
	.use("*", logger)
	// health check endpoint
	.route("/", rootRoutes);

export default {
	port: 3000,
	fetch: app.fetch,
};

// for Hono RPC
export type AppType = typeof app;
