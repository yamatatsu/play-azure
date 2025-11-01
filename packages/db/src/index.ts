import logger from "@packages/logger";
import { PrismaPg } from "@prisma/adapter-pg";
import { Prisma, PrismaClient } from "./generated/prisma/client";

export { Prisma };

export * as fabbrica from "./generated/fabbrica";

const { DB_USERNAME, DB_PASSWORD, DB_HOST, DB_DBNAME } = process.env;
const connectionString = `postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_DBNAME}?schema=public`;

const adapter = new PrismaPg({ connectionString });

const prisma = new PrismaClient({
	adapter,
	log: [
		{ level: "query", emit: "event" },
		{ level: "info", emit: "event" },
		{ level: "warn", emit: "event" },
		{ level: "error", emit: "event" },
	],
});

prisma.$on("query", (event) => {
	logger.debug({ event }, "Prisma Query");
});
prisma.$on("info", (event) => {
	logger.info({ event }, "Prisma Info");
});
prisma.$on("warn", (event) => {
	logger.warn({ event }, "Prisma Warn");
});
prisma.$on("error", (event) => {
	logger.error({ event }, "Prisma Error");
});

export const getPrisma = () => prisma;
