import { createRootRoute, Outlet } from "@tanstack/react-router";
import ErrorBoundary from "../error-boundary";

export const Route = createRootRoute({
	component: () => (
		<ErrorBoundary>
			<Outlet />
		</ErrorBoundary>
	),
});
