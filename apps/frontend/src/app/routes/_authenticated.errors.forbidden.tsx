import { createFileRoute } from "@tanstack/react-router";
import { ForbiddenScreen } from "@/features/error/components/forbidden-screen";

export const Route = createFileRoute("/_authenticated/errors/forbidden")({
	component: Component,
});

function Component() {
	return <ForbiddenScreen />;
}
