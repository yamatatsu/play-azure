import {
	useQueryClient,
	useQueryErrorResetBoundary,
} from "@tanstack/react-query";
import type React from "react";
import { ErrorBoundary } from "react-error-boundary";
import { SystemErrorScreen } from "@/features/error/components/system-error-screen";

export default function MyErrorBoundary(props: { children: React.ReactNode }) {
	const { reset } = useQueryErrorResetBoundary();
	const queryClient = useQueryClient();

	return (
		<ErrorBoundary
			onReset={() => {
				queryClient.clear();
				reset();
			}}
			fallbackRender={({ resetErrorBoundary, error }) => {
				return (
					<SystemErrorScreen
						message={error?.message}
						onReload={resetErrorBoundary}
					/>
				);
			}}
		>
			{props.children}
		</ErrorBoundary>
	);
}
