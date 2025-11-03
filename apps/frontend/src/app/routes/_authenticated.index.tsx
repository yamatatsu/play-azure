import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/_authenticated/")({
	component: Component,
});

function Component() {
	return <div>テスト</div>;
}
