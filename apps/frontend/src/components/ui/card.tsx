import type * as React from "react";

import { cn } from "@/lib/utils";

function Card({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card"
			className={cn(
				// レイアウト
				"flex flex-col",
				// スペーシング
				"gap-6 py-6",
				// カラー
				"bg-card text-card-foreground",
				// ボーダー
				"rounded-xl border",
				// エフェクト
				"shadow-sm",
				className,
			)}
			{...props}
		/>
	);
}

function CardHeader({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-header"
			className={cn(
				// レイアウト
				"grid items-start",
				// スペーシング
				"gap-2 px-6",
				// グリッド
				"auto-rows-min grid-rows-[auto_auto]",
				// コンテナ
				"@container/card-header",
				// 条件付きスタイル
				"has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-6",
				className,
			)}
			{...props}
		/>
	);
}

function CardTitle({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-title"
			className={cn(
				// タイポグラフィ
				"font-semibold leading-none",
				className,
			)}
			{...props}
		/>
	);
}

function CardDescription({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-description"
			className={cn(
				// タイポグラフィ
				"text-sm",
				// カラー
				"text-muted-foreground",
				className,
			)}
			{...props}
		/>
	);
}

function CardAction({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-action"
			className={cn(
				// グリッド
				"col-start-2 row-span-2 row-start-1",
				// レイアウト
				"self-start justify-self-end",
				className,
			)}
			{...props}
		/>
	);
}

function CardContent({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-content"
			className={cn(
				// スペーシング
				"px-6",
				className,
			)}
			{...props}
		/>
	);
}

function CardFooter({ className, ...props }: React.ComponentProps<"div">) {
	return (
		<div
			data-slot="card-footer"
			className={cn(
				// レイアウト
				"flex items-center",
				// スペーシング
				"px-6",
				// 条件付きスタイル
				"[.border-t]:pt-6",
				className,
			)}
			{...props}
		/>
	);
}

export {
	Card,
	CardHeader,
	CardFooter,
	CardTitle,
	CardAction,
	CardDescription,
	CardContent,
};
