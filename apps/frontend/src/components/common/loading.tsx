import { cn } from "@/lib/utils";

interface LoadingProps {
	message?: string;
	className?: string;
}

export function Loading({
	message = "読み込み中...",
	className,
}: LoadingProps) {
	return (
		<div
			className={cn(
				"flex flex-col items-center justify-center min-h-full p-8",
				className,
			)}
		>
			<div className="text-lg">{message}</div>
		</div>
	);
}
