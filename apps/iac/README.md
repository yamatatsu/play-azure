# Azure Container Apps Infrastructure

このディレクトリには、Azure Container Appsを中心としたインフラストラクチャのBicepコードが含まれています。

## ドキュメント

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - アーキテクチャ設計書（アーキテクチャ図、技術選定理由、セキュリティ設計など）
- **[task-list.md](./task-list.md)** - 実装タスクリスト（実装進捗の確認）

## 前提条件

- Azure CLI がインストールされていること
- Azureにログイン済みであること (`az login`)
- リソースグループが作成済みであること
- Docker がインストールされていること（イメージビルド用）

## ディレクトリ構造

```
apps/iac/
├── main.bicep                      # メインテンプレート（実行可能なドキュメント）
├── modules/                        # Bicepモジュール
│   ├── network.bicep               # VNet, Subnets
│   ├── nsg.bicep                   # Network Security Groups
│   ├── nat-gateway.bicep           # NAT Gateway
│   ├── monitoring.bicep            # Log Analytics, App Insights
│   ├── postgresql.bicep            # PostgreSQL Flexible Server
│   ├── container-registry.bicep    # Azure Container Registry
│   ├── container-app-environment.bicep  # Container Apps Environment
│   └── container-app-web.bicep     # Container App (Web Server)
├── params/
│   └── dev.bicepparam              # 開発環境パラメータ
├── ARCHITECTURE.md                 # アーキテクチャ設計書
├── task-list.md                    # 実装タスクリスト
└── README.md                       # このファイル
```

## クイックスタート

### 1. Key Vaultの作成（初回のみ）

PostgreSQLのパスワードなど、機密情報を格納するKey Vaultを作成します。

```bash
# Key Vaultリソースプロバイダーの登録確認
az provider show --namespace Microsoft.KeyVault --query "registrationState"

# 未登録の場合は登録
az provider register --namespace Microsoft.KeyVault

# Key Vaultの作成（開発環境の例）
az keyvault create --name yamatatsu-lab-v1-dev-kv --resource-group yamatatsu-lab --location japaneast --enable-rbac-authorization false --enabled-for-template-deployment true

# PostgreSQL管理者パスワードの格納（staging/prod環境で使用）
az keyvault secret set --vault-name yamatatsu-lab-v1-dev-kv --name "postgres-admin-password" --value "<strong-password>"
```

### 2. Bicepファイルの検証

```bash
cd /workspace/main/apps/iac

# 構文チェック
az bicep build --file main.bicep

# What-If実行（実際のデプロイ前に変更内容を確認）
az deployment group what-if --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam
```

### 3. インフラストラクチャのデプロイ

```bash
# デプロイ実行
az deployment group create --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam
```

デプロイには10-15分程度かかります。

### 4. デプロイ結果の確認

```bash
# 出力値の取得
az deployment group show --resource-group yamatatsu-lab --name main --query properties.outputs

# Container Registry名の取得
ACR_NAME=$(az deployment group show --resource-group yamatatsu-lab --name main --query properties.outputs.containerRegistryName.value -o tsv)

echo "Container Registry Name: $ACR_NAME"

# Web Server FQDNの取得
WEB_FQDN=$(az deployment group show --resource-group yamatatsu-lab --name main --query properties.outputs.webServerFqdn.value -o tsv)

echo "Web Server URL: https://$WEB_FQDN"
```

## アプリケーションのデプロイ

インフラストラクチャのデプロイ後、コンテナイメージをビルドしてデプロイします。

### 1. Dockerイメージのビルドとプッシュ

```bash
# Container Registryにログイン
az acr login --name $ACR_NAME

# イメージのビルド（リポジトリルートから実行）
cd /workspace/main
docker build --platform linux/amd64 -f apps/backend/Dockerfile -t $ACR_NAME.azurecr.io/backend:latest .

# イメージのプッシュ
docker push $ACR_NAME.azurecr.io/backend:latest
```

### 2. Container Appの更新（イメージの反映）

```bash
# Container App名の取得
WEBAPP_NAME=$(az deployment group show --resource-group yamatatsu-lab --name main --query properties.outputs.webServerAppName.value -o tsv)

# Container Appを更新してイメージを反映
az containerapp update --name $WEBAPP_NAME --resource-group yamatatsu-lab --image $ACR_NAME.azurecr.io/backend:latest
```

### 3. 動作確認

```bash
# アプリケーションにアクセス
curl https://$WEB_FQDN

# ログの確認
az containerapp logs show --name $WEBAPP_NAME --resource-group yamatatsu-lab --follow
```

## デプロイされるリソース

### 開発環境（dev）

- **VNet**: 10.0.0.0/16
  - Container Apps Subnet: 10.0.0.0/23
  - PostgreSQL Subnet: 10.0.2.0/24（未使用）
- **NSG**: Container Apps用、PostgreSQL用
- **NAT Gateway**: なし（コスト削減）
- **Log Analytics Workspace**: ログ集約
- **Application Insights**: APM
- **Azure Container Registry**: Standard SKU
- **Container Apps Environment**: Consumption
- **Container App - Web Server**: 0-10レプリカ、0.5 vCPU、1Gi
- **PostgreSQL**: なし（コスト削減）

### 本番環境（prod、将来）

- 上記に加えて:
  - **NAT Gateway**: 固定送信元IP
  - **PostgreSQL Flexible Server**: Zone-Redundant HA、General Purpose tier

## 主要なコマンド

### Bicep関連

```bash
# 構文チェック
az bicep build --file main.bicep

# What-If（変更内容の確認）
az deployment group what-if --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam

# デプロイ
az deployment group create --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam
```

### Container Apps操作

```bash
# Container Appの一覧
az containerapp list --resource-group yamatatsu-lab -o table

# Container Appの詳細
az containerapp show --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab

# ログの確認
az containerapp logs show --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --follow

# リビジョンの一覧
az containerapp revision list --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab -o table

# Container Appの再起動
az containerapp revision restart --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --revision <revision-name>
```

### Azure Container Registry操作

```bash
# ACRにログイン
az acr login --name <acr-name>

# リポジトリ一覧
az acr repository list --name <acr-name>

# タグ一覧
az acr repository show-tags --name <acr-name> --repository backend

# イメージの削除
az acr repository delete --name <acr-name> --image backend:old-tag
```

### 監視・ログ

```bash
# Log Analyticsクエリ
az monitor log-analytics query --workspace <workspace-id> --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'yamatatsu-lab-v1-dev-web' | take 100"

# Application Insightsメトリクス確認
az monitor app-insights metrics show --app <app-insights-name> --resource-group yamatatsu-lab --metric requests/count
```

## トラブルシューティング

### Container Appが起動しない

```bash
# リビジョンの状態確認
az containerapp revision list --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --query "[].{Name:name, Active:properties.active, Health:properties.healthState}" -o table

# ログの確認
az containerapp logs show --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --tail 100
```

**よくある原因:**
- イメージのpullに失敗（ACRの認証問題）
- コンテナの起動に失敗（アプリケーションエラー）
- ヘルスチェックの失敗（ポート3000でリッスンしていない）

### ACRからイメージをPullできない

Managed IdentityにAcrPullロールが付与されているか確認:

```bash
# Container AppのManaged Identity確認
az containerapp show --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --query identity

# ロール割り当ての確認
az role assignment list --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/yamatatsu-lab --query "[?principalType=='ServicePrincipal'].{Role:roleDefinitionName, Principal:principalName}" -o table
```

### デプロイが失敗する

```bash
# デプロイログの確認
az deployment group show --resource-group yamatatsu-lab --name main --query properties.error

# 特定のリソースのエラー確認
az deployment operation group list --resource-group yamatatsu-lab --name main --query "[?properties.provisioningState=='Failed'].{Resource:properties.targetResource.resourceName, Error:properties.statusMessage.error.message}"
```

## 環境の削除

```bash
# リソースグループごと削除（全リソースが削除されます）
az group delete --name yamatatsu-lab --yes

# 特定のリソースのみ削除
az containerapp delete --name yamatatsu-lab-v1-dev-web --resource-group yamatatsu-lab --yes
az acr delete --name yamatatsuv1devacr --resource-group yamatatsu-lab --yes
```

## CI/CD統合

GitHub Actionsでの自動デプロイ例:

```yaml
# .github/workflows/deploy-backend.yml
name: Deploy Backend to Container Apps

on:
  push:
    branches:
      - main
    paths:
      - 'apps/backend/**'

env:
  ACR_NAME: yamatatsuv1devacr
  WEBAPP_NAME: yamatatsu-lab-v1-dev-web
  RESOURCE_GROUP: yamatatsu-lab

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Build and push image
        run: |
          az acr login --name ${{ env.ACR_NAME }}
          docker build -f apps/backend/Dockerfile -t ${{ env.ACR_NAME }}.azurecr.io/backend:${{ github.sha }} .
          docker push ${{ env.ACR_NAME }}.azurecr.io/backend:${{ github.sha }}

      - name: Deploy to Container App
        run: |
          az containerapp update \
            --name ${{ env.WEBAPP_NAME }} \
            --resource-group ${{ env.RESOURCE_GROUP }} \
            --image ${{ env.ACR_NAME }}.azurecr.io/backend:${{ github.sha }}
```

## よくある質問

### Q: 開発環境にPostgreSQLが含まれていないのはなぜですか？

A: コスト削減のためです。開発環境では、ローカルのPostgreSQLやDocker Composeを使用することを想定しています。staging/prod環境では自動的にPostgreSQLがデプロイされます。

### Q: NAT Gatewayが開発環境にないのはなぜですか？

A: コスト削減のためです（約¥5,000/月）。外部APIのIP許可リストが必要な場合は、`main.bicep`の条件を変更してください:

```bicep
module natGateway 'modules/nat-gateway.bicep' = if (environment != 'dev') {
  // ↓ 開発環境でも有効にする場合
module natGateway 'modules/nat-gateway.bicep' = {
```

### Q: HTTPSでアクセスできますか？

A: はい、Container AppsはデフォルトでHTTPSエンドポイントを公開します。TLS証明書はAzureが自動管理します。HTTPでアクセスした場合は自動的にHTTPSへリダイレクトされます。

### Q: カスタムドメインを使用できますか？

A: はい、Container AppsのIngress設定で`customDomains`を追加することで可能です。独自のTLS証明書が必要です。

### Q: Container Appが0レプリカの時、リクエストが来たらどうなりますか？

A: 自動的にレプリカが起動します（コールドスタート）。起動には数秒かかりますが、その間リクエストは待機します。

### Q: 複数の環境（dev, staging, prod）を同時にデプロイできますか？

A: はい、環境ごとに異なるリソースグループを使用してデプロイしてください。パラメータファイル（`params/staging.bicepparam`、`params/prod.bicepparam`）を追加する必要があります。

## 参考リンク

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure Container Registry Documentation](https://learn.microsoft.com/azure/container-registry/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [アーキテクチャ設計書](./ARCHITECTURE.md)
