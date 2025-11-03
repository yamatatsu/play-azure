import { useAccount } from "@azure/msal-react";
import { Link } from "@tanstack/react-router";
import { Menu } from "lucide-react";
import { logout } from "@/app/auth";
import { Button } from "@/components/ui/button";
import {
	Sheet,
	SheetContent,
	SheetHeader,
	SheetTitle,
	SheetTrigger,
} from "@/components/ui/sheet";

export default function AuthenticatedHeader() {
	const account = useAccount();

	return (
		<header className="sticky top-0 z-50 border-b bg-background">
			<div className="flex items-center justify-between p-4">
				<Link to="/">
					<h1 className="text-xl font-bold">Play with Azure</h1>
				</Link>
				<Sheet>
					<SheetTrigger asChild>
						<Button
							variant="ghost"
							className="gap-2"
							aria-label="メニューを開く"
						>
							{account?.name}
							<Menu />
						</Button>
					</SheetTrigger>
					<SheetContent>
						<SheetHeader>
							<SheetTitle>メニュー</SheetTitle>
						</SheetHeader>
						<div className="mt-4">
							<Button variant="outline" className="w-full" onClick={logout}>
								ログアウト
							</Button>
						</div>
					</SheetContent>
				</Sheet>
			</div>
		</header>
	);
}
