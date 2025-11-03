import { createFileRoute, Outlet } from "@tanstack/react-router";
import AuthenticatedHeader from "@/components/layouts/authenticated-header";
import { AuthenticationTemplate } from "../auth";

export const Route = createFileRoute("/_authenticated")({
	component: AuthenticatedLayout,
});

function AuthenticatedLayout() {
	return (
		<AuthenticationTemplate>
			<div className="min-h-screen flex flex-col">
				<AuthenticatedHeader />
				<div className="flex-1">
					<Outlet />
				</div>
			</div>
		</AuthenticationTemplate>
	);
}
