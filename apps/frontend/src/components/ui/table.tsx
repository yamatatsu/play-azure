import type * as React from "react";

import { cn } from "@/lib/utils";

function Table({ className, ...props }: React.ComponentProps<"table">) {
	return (
		<div
			data-slot="table-container"
			className={cn(
				// ポジション
				"relative",
				// サイズ
				"w-full",
				// オーバーフロー
				"overflow-x-auto",
			)}
		>
			<table
				data-slot="table"
				className={cn(
					// サイズ
					"w-full",
					// レイアウト
					"caption-bottom",
					className,
				)}
				{...props}
			/>
		</div>
	);
}

function TableHeader({ className, ...props }: React.ComponentProps<"thead">) {
	return (
		<thead
			data-slot="table-header"
			className={cn(
				// 子要素スタイル
				"[&_tr]:border-b",
				className,
			)}
			{...props}
		/>
	);
}

function TableBody({ className, ...props }: React.ComponentProps<"tbody">) {
	return (
		<tbody
			data-slot="table-body"
			className={cn(
				// 子要素スタイル
				"[&_tr:last-child]:border-0",
				className,
			)}
			{...props}
		/>
	);
}

function TableFooter({ className, ...props }: React.ComponentProps<"tfoot">) {
	return (
		<tfoot
			data-slot="table-footer"
			className={cn(
				// カラー
				"bg-muted/50",
				// ボーダー
				"border-t",
				// タイポグラフィ
				"font-medium",
				// 子要素スタイル
				"[&>tr]:last:border-b-0",
				className,
			)}
			{...props}
		/>
	);
}

function TableRow({ className, ...props }: React.ComponentProps<"tr">) {
	return (
		<tr
			data-slot="table-row"
			className={cn(
				// ボーダー
				"border-b",
				// ホバー状態
				"hover:bg-muted/50",
				// 選択状態
				"data-[state=selected]:bg-muted",
				// トランジション
				"transition-colors",
				className,
			)}
			{...props}
		/>
	);
}

function TableHead({ className, ...props }: React.ComponentProps<"th">) {
	return (
		<th
			data-slot="table-head"
			className={cn(
				// サイズ
				"h-10",
				// スペーシング
				"px-2",
				// タイポグラフィ
				"text-foreground text-left font-medium whitespace-nowrap",
				// レイアウト
				"align-middle",
				// ボーダー
				"border-r border-border last:border-r-0",
				// チェックボックススタイル
				"[&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
				className,
			)}
			{...props}
		/>
	);
}

function TableCell({ className, ...props }: React.ComponentProps<"td">) {
	return (
		<td
			data-slot="table-cell"
			className={cn(
				// スペーシング
				"p-2",
				// レイアウト
				"align-middle",
				// タイポグラフィ
				"whitespace-nowrap",
				// ボーダー
				"border-r border-border last:border-r-0",
				// チェックボックススタイル
				"[&:has([role=checkbox])]:pr-0 [&>[role=checkbox]]:translate-y-[2px]",
				className,
			)}
			{...props}
		/>
	);
}

function TableCaption({
	className,
	...props
}: React.ComponentProps<"caption">) {
	return (
		<caption
			data-slot="table-caption"
			className={cn(
				// タイポグラフィ
				"text-sm",
				// カラー
				"text-muted-foreground",
				// スペーシング
				"mt-4",
				className,
			)}
			{...props}
		/>
	);
}

export {
	Table,
	TableHeader,
	TableBody,
	TableFooter,
	TableHead,
	TableRow,
	TableCell,
	TableCaption,
};
