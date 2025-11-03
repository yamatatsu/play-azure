import { cn } from "@/lib/utils";

interface ErrorDisplayProps {
	message?: string;
	className?: string;
}

export function ErrorDisplay({
	message = "エラーが発生しました",
	className,
}: ErrorDisplayProps) {
	return (
		<div
			className={cn(
				"flex flex-col items-center justify-center min-h-full p-8",
				className,
			)}
		>
			<div className="text-lg text-red-500">{message}</div>
		</div>
	);
}
