import * as SelectPrimitive from "@radix-ui/react-select";
import { CheckIcon, ChevronDownIcon, ChevronUpIcon } from "lucide-react";
import type * as React from "react";

import { cn } from "@/lib/utils";

function Select({
	...props
}: React.ComponentProps<typeof SelectPrimitive.Root>) {
	return <SelectPrimitive.Root data-slot="select" {...props} />;
}

function SelectGroup({
	...props
}: React.ComponentProps<typeof SelectPrimitive.Group>) {
	return <SelectPrimitive.Group data-slot="select-group" {...props} />;
}

function SelectValue({
	...props
}: React.ComponentProps<typeof SelectPrimitive.Value>) {
	return <SelectPrimitive.Value data-slot="select-value" {...props} />;
}

function SelectTrigger({
	className,
	size = "default",
	children,
	...props
}: React.ComponentProps<typeof SelectPrimitive.Trigger> & {
	size?: "sm" | "default";
}) {
	return (
		<SelectPrimitive.Trigger
			data-slot="select-trigger"
			data-size={size}
			className={cn(
				// レイアウト
				"flex w-fit items-center justify-between",
				// スペーシング
				"gap-2 px-3 py-2",
				// サイズ
				"data-[size=default]:h-9 data-[size=sm]:h-8",
				// タイポグラフィ
				"text-sm whitespace-nowrap",
				// カラー
				"bg-transparent",
				// ボーダー
				"border border-input rounded-md",
				// エフェクト
				"shadow-xs",
				// トランジション
				"transition-[color,box-shadow]",
				// フォーカス状態
				"outline-none focus-visible:ring-[3px] focus-visible:border-ring focus-visible:ring-ring/50",
				// 無効状態
				"disabled:cursor-not-allowed disabled:opacity-50",
				// エラー状態
				"aria-invalid:border-destructive aria-invalid:ring-destructive/20",
				// ダークモード
				"dark:bg-input/30 dark:hover:bg-input/50 dark:aria-invalid:ring-destructive/40",
				// プレースホルダー
				"data-[placeholder]:text-muted-foreground",
				// SVGスタイル
				"[&_svg:not([class*='text-'])]:text-muted-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
				// 子要素スタイル
				"*:data-[slot=select-value]:line-clamp-1 *:data-[slot=select-value]:flex *:data-[slot=select-value]:items-center *:data-[slot=select-value]:gap-2",
				className,
			)}
			{...props}
		>
			{children}
			<SelectPrimitive.Icon asChild>
				<ChevronDownIcon className="size-4 opacity-50" />
			</SelectPrimitive.Icon>
		</SelectPrimitive.Trigger>
	);
}

function SelectContent({
	className,
	children,
	position = "popper",
	align = "center",
	...props
}: React.ComponentProps<typeof SelectPrimitive.Content>) {
	return (
		<SelectPrimitive.Portal>
			<SelectPrimitive.Content
				data-slot="select-content"
				className={cn(
					// レイアウト
					"relative z-50",
					// サイズ
					"max-h-(--radix-select-content-available-height) min-w-[8rem]",
					// カラー
					"bg-popover text-popover-foreground",
					// ボーダー
					"rounded-md border",
					// エフェクト
					"shadow-md",
					// オーバーフロー
					"overflow-x-hidden overflow-y-auto",
					// アニメーション
					"data-[state=open]:animate-in data-[state=closed]:animate-out",
					// フェードアニメーション
					"data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
					// ズームアニメーション
					"data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
					// スライドアニメーション
					"data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
					// トランスフォーム
					"origin-(--radix-select-content-transform-origin)",
					// ポッパー位置調整
					position === "popper" &&
						"data-[side=bottom]:translate-y-1 data-[side=left]:-translate-x-1 data-[side=right]:translate-x-1 data-[side=top]:-translate-y-1",
					className,
				)}
				position={position}
				align={align}
				{...props}
			>
				<SelectScrollUpButton />
				<SelectPrimitive.Viewport
					className={cn(
						// スペーシング
						"p-1",
						// ポッパーサイズ
						position === "popper" &&
							"h-[var(--radix-select-trigger-height)] w-full min-w-[var(--radix-select-trigger-width)] scroll-my-1",
					)}
				>
					{children}
				</SelectPrimitive.Viewport>
				<SelectScrollDownButton />
			</SelectPrimitive.Content>
		</SelectPrimitive.Portal>
	);
}

function SelectLabel({
	className,
	...props
}: React.ComponentProps<typeof SelectPrimitive.Label>) {
	return (
		<SelectPrimitive.Label
			data-slot="select-label"
			className={cn(
				// タイポグラフィ
				"text-xs",
				// カラー
				"text-muted-foreground",
				// スペーシング
				"px-2 py-1.5",
				className,
			)}
			{...props}
		/>
	);
}

function SelectItem({
	className,
	children,
	...props
}: React.ComponentProps<typeof SelectPrimitive.Item>) {
	return (
		<SelectPrimitive.Item
			data-slot="select-item"
			className={cn(
				// レイアウト
				"relative flex w-full items-center",
				// スペーシング
				"gap-2 py-1.5 pr-8 pl-2",
				// タイポグラフィ
				"text-sm",
				// インタラクション
				"cursor-default select-none",
				// ボーダー
				"rounded-sm",
				// フォーカス状態
				"focus:bg-accent focus:text-accent-foreground outline-hidden",
				// 無効状態
				"data-[disabled]:pointer-events-none data-[disabled]:opacity-50",
				// SVGスタイル
				"[&_svg:not([class*='text-'])]:text-muted-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4",
				// 子要素スタイル
				"*:[span]:last:flex *:[span]:last:items-center *:[span]:last:gap-2",
				className,
			)}
			{...props}
		>
			<span
				className={cn(
					// ポジション
					"absolute right-2",
					// レイアウト
					"flex items-center justify-center",
					// サイズ
					"size-3.5",
				)}
			>
				<SelectPrimitive.ItemIndicator>
					<CheckIcon className="size-4" />
				</SelectPrimitive.ItemIndicator>
			</span>
			<SelectPrimitive.ItemText>{children}</SelectPrimitive.ItemText>
		</SelectPrimitive.Item>
	);
}

function SelectSeparator({
	className,
	...props
}: React.ComponentProps<typeof SelectPrimitive.Separator>) {
	return (
		<SelectPrimitive.Separator
			data-slot="select-separator"
			className={cn(
				// サイズ
				"h-px",
				// カラー
				"bg-border",
				// スペーシング
				"-mx-1 my-1",
				// インタラクション
				"pointer-events-none",
				className,
			)}
			{...props}
		/>
	);
}

function SelectScrollUpButton({
	className,
	...props
}: React.ComponentProps<typeof SelectPrimitive.ScrollUpButton>) {
	return (
		<SelectPrimitive.ScrollUpButton
			data-slot="select-scroll-up-button"
			className={cn(
				// レイアウト
				"flex items-center justify-center",
				// スペーシング
				"py-1",
				// インタラクション
				"cursor-default",
				className,
			)}
			{...props}
		>
			<ChevronUpIcon className="size-4" />
		</SelectPrimitive.ScrollUpButton>
	);
}

function SelectScrollDownButton({
	className,
	...props
}: React.ComponentProps<typeof SelectPrimitive.ScrollDownButton>) {
	return (
		<SelectPrimitive.ScrollDownButton
			data-slot="select-scroll-down-button"
			className={cn(
				// レイアウト
				"flex items-center justify-center",
				// スペーシング
				"py-1",
				// インタラクション
				"cursor-default",
				className,
			)}
			{...props}
		>
			<ChevronDownIcon className="size-4" />
		</SelectPrimitive.ScrollDownButton>
	);
}

export {
	Select,
	SelectContent,
	SelectGroup,
	SelectItem,
	SelectLabel,
	SelectScrollDownButton,
	SelectScrollUpButton,
	SelectSeparator,
	SelectTrigger,
	SelectValue,
};
