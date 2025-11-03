import type { Table } from "@tanstack/react-table";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
	Select,
	SelectContent,
	SelectItem,
	SelectTrigger,
	SelectValue,
} from "@/components/ui/select";

interface Props<TData> {
	table: Table<TData>;
}

export function TablePagination<TData>({ table }: Props<TData>) {
	// パフォーマンス最適化: 一度だけ呼び出して変数に格納
	const tableState = table.getState();

	const { pageIndex, pageSize } = tableState.pagination;
	const totalPages = table.getPageCount();

	return (
		<div className="flex items-center justify-between px-2">
			{/* 左側：行/ページ選択と表示範囲 */}
			<div className="flex items-center gap-4">
				<div className="flex items-center gap-2">
					<span className="text-sm text-muted-foreground whitespace-nowrap">
						行/ページ
					</span>
					<Select
						value={pageSize.toString()}
						onValueChange={(value) => {
							table.setPageSize(Number(value));
						}}
					>
						<SelectTrigger className="w-[70px]" size="sm">
							<SelectValue />
						</SelectTrigger>
						<SelectContent>
							<SelectItem value="5">5</SelectItem>
							<SelectItem value="10">10</SelectItem>
						</SelectContent>
					</Select>
				</div>
				<div className="text-sm text-muted-foreground">
					Page {pageIndex + 1} of {totalPages}
				</div>
			</div>

			{/* 右側：ナビゲーションボタン */}
			<div className="flex items-center gap-2">
				<Button
					variant="outline"
					size="sm"
					onClick={() => table.previousPage()}
					disabled={!table.getCanPreviousPage()}
				>
					<ChevronLeft className="h-4 w-4" />
				</Button>
				<Button
					variant="outline"
					size="sm"
					onClick={() => table.nextPage()}
					disabled={!table.getCanNextPage()}
				>
					<ChevronRight className="h-4 w-4" />
				</Button>
			</div>
		</div>
	);
}
