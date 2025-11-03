import {
	InteractionRequiredAuthError,
	InteractionType,
	PublicClientApplication,
	type RedirectRequest,
	type SilentRequest,
} from "@azure/msal-browser";
import {
	type MsalAuthenticationResult,
	MsalAuthenticationTemplate,
	MsalProvider,
} from "@azure/msal-react";

const SCOPES = [
	"openid",
	"profile",
	"email",
	/**
	 * スコープはAzureポータルで設定できます。
	 * @see https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-configure-app-expose-web-apis#add-a-scope
	 * TODO: "All.All"の代わりに、より細かい粒度のスコープを使用する必要があります。
	 */
	"api://694b37ed-46b7-422a-aacb-c3ce12277475/All.All",
];

/**
 * singleton
 */
const pca = new PublicClientApplication({
	auth: {
		clientId: import.meta.env.VITE_ENTRA_CLIENT_ID,
		authority: `https://${import.meta.env.VITE_ENTRA_TENANT_NAME}.ciamlogin.com/${import.meta.env.VITE_ENTRA_TENANT_ID}`,
		redirectUri: "http://localhost:5173",
		knownAuthorities: [
			`${import.meta.env.VITE_ENTRA_TENANT_NAME}.ciamlogin.com`,
		],
	},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
	return <MsalProvider instance={pca}>{children}</MsalProvider>;
}

export function AuthenticationTemplate({
	children,
}: {
	children: React.ReactNode;
}) {
	return (
		<MsalAuthenticationTemplate
			interactionType={InteractionType.Redirect}
			authenticationRequest={{
				scopes: SCOPES,
			}}
			errorComponent={ErrorComponent}
			loadingComponent={LoadingComponent}
		>
			{children}
		</MsalAuthenticationTemplate>
	);
}
function ErrorComponent({ error }: MsalAuthenticationResult) {
	return <p>An Error Occurred: {error?.errorMessage}</p>;
}
function LoadingComponent() {
	return <p>Authentication in progress...</p>;
}

export const logout = async () => {
	await pca.logoutRedirect({
		postLogoutRedirectUri: "http://localhost:5173",
	});
};

/**
 * @see https://github.com/AzureAD/microsoft-authentication-library-for-js/blob/0dae241844c3f0f984b4569da21face7ca76cca7/lib/msal-browser/docs/acquire-token.md#redirect
 */
export const acquireToken = async (): Promise<string> => {
	const accounts = pca.getAllAccounts();
	const request = {
		scopes: SCOPES,
		account: accounts[0],
	} satisfies Pick<
		SilentRequest,
		Extract<keyof SilentRequest, keyof RedirectRequest>
	>;

	try {
		const res = await pca.acquireTokenSilent(request);
		return res.accessToken;
	} catch (error) {
		if (error instanceof InteractionRequiredAuthError) {
			// token取得に失敗した場合はEntraの画面にredirectする
			await pca.acquireTokenRedirect(request);
		}
		throw error;
	}
};
