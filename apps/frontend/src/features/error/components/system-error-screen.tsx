import { Button } from "@/components/ui/button";
import {
	Card,
	CardContent,
	CardFooter,
	CardHeader,
	CardTitle,
} from "@/components/ui/card";

interface Props {
	message?: string;

	/**
	 * 戻るボタンクリック時のハンドラー
	 * 指定しない場合はブラウザの戻る機能を使用
	 */
	onReload: () => void;
}

/**
 * システムエラー画面コンポーネント
 *
 * システムで予期しないエラーが発生した際に表示する画面です。
 * ユーザーに時間をおいて再試行するよう促します。
 */
export function SystemErrorScreen({ message, onReload }: Props) {
	const errorTime = new Date();

	return (
		<div className="flex items-center justify-center min-h-screen p-4">
			<Card className="w-full max-w-md">
				<CardHeader>
					<CardTitle className="text-destructive">
						<div>
							<p>予期せぬエラーが発生しました</p>
							<p>管理者にお問い合わせください</p>
						</div>
					</CardTitle>
				</CardHeader>
				<CardContent className="space-y-4">
					<div>
						<p>{message}</p>
					</div>
					<div className="text-sm text-muted-foreground">
						<span className="font-medium">発生時刻: </span>
						<time dateTime={errorTime.toISOString()}>
							{errorTime.toLocaleString("ja-JP")}
						</time>
					</div>
				</CardContent>
				<CardFooter>
					<Button onClick={onReload} className="w-full">
						再読み込み
					</Button>
				</CardFooter>
			</Card>
		</div>
	);
}
