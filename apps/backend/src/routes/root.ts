import { Hono } from "hono";

export default new Hono().get("/", async (c) => {
	return c.text("ok", 200);
});
