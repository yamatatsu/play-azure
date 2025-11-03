import { useQueryClient } from "@tanstack/react-query";
import { useNavigate } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";
import { Card, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";

/**
 * アクセス権限エラー画面コンポーネント
 */
export function ForbiddenScreen() {
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
						アクセス権限がありません
					</CardTitle>
				</CardHeader>
				<CardFooter>
					<Button onClick={navigateToHome} className="w-full">
						ホーム画面へ戻る
					</Button>
				</CardFooter>
			</Card>
		</div>
	);
}
