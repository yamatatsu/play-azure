import { useCanGoBack, useRouter } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";

interface TitleSectionProps {
	title: string;
	noBack?: boolean;
}

/**
 * 戻るボタン付きのタイトルセクション
 * @see https://tanstack.com/router/latest/docs/framework/react/api/router/useCanGoBack
 */
export function TitleSection({ title, noBack = false }: TitleSectionProps) {
	return (
		<div className="flex items-center justify-between mb-6">
			<div className="w-1/4">{!noBack && <BackButton />}</div>
			<h1 className="text-3xl font-bold">{title}</h1>
			<div className="w-1/4"></div>
		</div>
	);
}

function BackButton() {
	const router = useRouter();
	const canGoBack = useCanGoBack();

	const handleBack = () => {
		router.history.back();
	};

	return (
		<Button variant="outline" onClick={handleBack} disabled={!canGoBack}>
			戻る
		</Button>
	);
}
