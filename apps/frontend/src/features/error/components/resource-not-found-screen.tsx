import { useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import {
	Card,
	CardContent,
	CardFooter,
	CardHeader,
	CardTitle,
} from "@/components/ui/card";

interface Props {
	/**
	 * 見つからなかったリソースの物理名
	 */
	resourceName: string | null;
}

/**
 * リソース未検出画面コンポーネント
 *
 * 指定されたリソースが削除されているか見つからない場合に表示する画面です。
 * ユーザーにデータの再取得を促します。
 */
export function ResourceNotFoundScreen({ resourceName }: Props) {
	const queryClient = useQueryClient();
	const navigate = useNavigate();

	const navigateToHome = async () => {
		queryClient.clear();
		await navigate({ to: "/" });
	};

	return (
		<div className="flex items-center justify-center min-h-screen p-4">
			<Card className="w-full max-w-md">
				<CardHeader>
					<CardTitle className="text-destructive">
						リソースが見つかりません
					</CardTitle>
				</CardHeader>
				<CardContent>
					<p className="text-muted-foreground">
						{resourceName}
						は削除されました。データを取得し直しますので再度お試しください。
					</p>
				</CardContent>
				<CardFooter>
					<Button onClick={navigateToHome} className="w-full">
						ホーム画面へ戻る
					</Button>
				</CardFooter>
			</Card>
		</div>
	);
}
