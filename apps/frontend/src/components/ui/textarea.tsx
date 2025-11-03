import type * as React from "react";

import { cn } from "@/lib/utils";

export interface TextareaProps
	extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {}

function Textarea({ className, ...props }: TextareaProps) {
	return (
		<textarea
			className={cn(
				// レイアウト
				"flex min-h-[80px] w-full",
				// スペーシング
				"rounded-md border border-input bg-background px-3 py-2",
				// タイポグラフィ
				"text-sm ring-offset-background",
				// プレースホルダー
				"placeholder:text-muted-foreground",
				// フォーカス状態
				"focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
				// 無効状態
				"disabled:cursor-not-allowed disabled:opacity-50",
				// リサイズ
				"resize-vertical",
				className,
			)}
			{...props}
		/>
	);
}

export { Textarea };
