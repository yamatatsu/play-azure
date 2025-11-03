import { createFileRoute } from "@tanstack/react-router";
import { ResourceNotFoundScreen } from "@/features/error/components/resource-not-found-screen";

export const Route = createFileRoute("/_authenticated/errors/not-found")({
	component: Component,
	validateSearch: (search: Record<string, unknown>) => {
		return {
			resourceName: search.resourceName ? String(search.resourceName) : null,
		};
	},
});

function Component() {
	const { resourceName } = Route.useSearch();
	return <ResourceNotFoundScreen resourceName={resourceName} />;
}
