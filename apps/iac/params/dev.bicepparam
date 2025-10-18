using '../main.bicep'

param environment = 'dev'

// PostgreSQL administrator password
// 本番環境では Azure Key Vault または環境変数から取得することを推奨
// デプロイ時にコマンドラインで指定する場合:
// az deployment group create ... --parameters postgresAdminPassword='YourSecurePassword123!'
//
// パスワード要件:
// - 8文字以上
// - 大文字、小文字、数字、特殊文字を含む
param postgresAdminPassword = ''
