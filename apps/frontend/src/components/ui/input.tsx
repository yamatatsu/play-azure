import type * as React from "react";

import { cn } from "@/lib/utils";

export interface InputProps
	extends React.InputHTMLAttributes<HTMLInputElement> {}

function Input({ className, type, ...props }: InputProps) {
	return (
		<input
			type={type}
			className={cn(
				// レイアウト
				"flex h-10 w-full",
				// スペーシング
				"rounded-md border border-input bg-background px-3 py-2",
				// タイポグラフィ
				"text-sm ring-offset-background",
				// プレースホルダー
				"file:border-0 file:bg-transparent file:text-sm file:font-medium",
				// フォーカス状態
				"placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
				// 無効状態
				"disabled:cursor-not-allowed disabled:opacity-50",
				className,
			)}
			{...props}
		/>
	);
}

export { Input };
