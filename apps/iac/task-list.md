# Bicep実装タスクリスト

## 概要
Azure Container Apps環境をBicepで段階的に実装します。各フェーズごとにデプロイ・検証を行いながら進めます。

---

## Phase 1: 基本ネットワーク構築 🔵

### 1-1. リソースグループとVNet
- [x] リソースグループの作成（パラメータ化）
- [x] VNet作成 (10.0.0.0/16)
- [x] Container Apps Subnet (10.0.0.0/23) の作成
- [x] PostgreSQL Subnet (10.0.2.0/24) の作成
- [x] サブネットの委任設定
- [x] デプロイ・検証

**デプロイコマンド例:**
```bash
az deployment group create \
  --resource-group myapp-dev-rg \
  --template-file main.bicep \
  --parameters params/dev.bicepparam
```

**検証項目:**
- [x] VNetが作成されている
- [x] サブネットが正しく作成されている
- [x] サブネット委任が正しく設定されている

---

## Phase 2: NSG (Network Security Group) 🔵

### 2-1. NSGの作成と適用
- [x] Container Apps用NSG作成
  - Inbound: HTTPS (443), HTTP (80), Azure LB
  - Outbound: Allow All
- [x] PostgreSQL用NSG作成
  - Inbound: PostgreSQL (5432) from Container Apps Subnet
  - Outbound: Allow All
- [x] NSGをサブネットに関連付け
- [x] デプロイ・検証

**検証項目:**
- [x] NSGが作成されている
- [x] NSGルールが正しく設定されている
- [x] NSGがサブネットに関連付けられている

---

## Phase 3: NAT Gateway 🔵

### 3-1. NAT GatewayとパブリックIP
- [x] パブリックIP作成 (Standard SKU)
- [x] NAT Gateway作成
- [x] NAT GatewayをContainer Apps Subnetに関連付け
- [x] デプロイ・検証

**検証項目:**
- [x] パブリックIPが作成されている
- [x] NAT Gatewayが作成されている
- [x] NAT GatewayがSubnetに関連付けられている

---

## Phase 4: 監視基盤 🔵

### 4-1. Log AnalyticsとApplication Insights
- [x] Log Analytics Workspace作成
- [x] Application Insights作成
- [x] Log Analyticsとの連携設定
- [x] デプロイ・検証

**検証項目:**
- [x] Log Analytics Workspaceが作成されている
- [x] Application Insightsが作成されている
- [x] 正しく連携されている

---

## Phase 5: PostgreSQL Flexible Server 🔵

### 5-1. PostgreSQL作成
- [ ] PostgreSQL Flexible Server作成
  - VNet統合
  - Private DNS Zone設定
  - Zone-Redundant HA (本番のみ)
  - Burstable tier (開発), General Purpose (本番)
- [ ] PostgreSQL管理者パスワードの設定（Key Vault統合）
- [ ] データベース作成
- [ ] デプロイ・検証

**検証項目:**
- [ ] PostgreSQLが作成されている
- [ ] VNet統合されている
- [ ] Private DNS Zoneが設定されている
- [ ] 接続テスト成功

**接続テストコマンド例:**
```bash
# Container Appsからテスト（後のフェーズ）
psql "postgresql://{username}:{password}@{server-name}.postgres.database.azure.com:5432/{database}?sslmode=require"
```

---

## Phase 6: Container Apps Environment 🔵

### 6-1. Container Apps Environment作成
- [ ] Container Apps Environment作成
  - VNet統合 (Container Apps Subnet)
  - Consumption プラン
  - Log Analytics統合
- [ ] デプロイ・検証

**検証項目:**
- [ ] Container Apps Environmentが作成されている
- [ ] VNet統合されている
- [ ] Log Analyticsに接続されている

---

## Phase 7: Container Apps - Web Server 🔵

### 7-1. Webサーバー用Container App作成
- [ ] Container App (Web Server) 作成
  - External Ingress
  - スケーリングルール設定 (Min: 0, Max: 10)
  - リソース設定 (0.5 vCPU, 1Gi)
  - 環境変数設定（PostgreSQL接続情報）
- [ ] Managed Identity設定
- [ ] Application Insights統合
- [ ] デプロイ・検証

**検証項目:**
- [ ] Container Appが作成されている
- [ ] External Ingressが動作している
- [ ] HTTPSアクセス可能
- [ ] スケーリング動作確認
- [ ] PostgreSQL接続確認

**テストコマンド例:**
```bash
# Container App URLの取得
az containerapp show \
  --name myapp-web \
  --resource-group myapp-dev-rg \
  --query properties.configuration.ingress.fqdn

# HTTPSアクセステスト
curl https://<fqdn>/
```

---

## Phase 8: Container Apps - Queue Worker 🔵

### 8-1. キュー処理ワーカー用Container App作成
- [ ] Container App (Queue Worker) 作成
  - Internal Ingress or No Ingress
  - KEDAスケーリングルール設定 (Queue Length)
  - Min: 0, Max: 10
  - リソース設定 (0.5 vCPU, 1Gi)
  - 環境変数設定
- [ ] Managed Identity設定
- [ ] デプロイ・検証

**検証項目:**
- [ ] Container Appが作成されている
- [ ] KEDAスケーリングが動作している
- [ ] キュー処理が正常に動作
- [ ] PostgreSQL接続確認

---

## Phase 9: セキュリティ強化 🟡

### 9-1. Key Vault統合
- [ ] Azure Key Vault作成
- [ ] PostgreSQL接続文字列をKey Vaultに保存
- [ ] Container AppsからKey Vault参照
- [ ] Managed Identityでアクセス権限設定
- [ ] デプロイ・検証

**検証項目:**
- [ ] Key Vaultが作成されている
- [ ] Secretsが保存されている
- [ ] Container AppsからSecrets取得可能

---

## Phase 10: アラート設定 🟡

### 10-1. Azure Monitor アラート
- [ ] Container Apps CPU使用率アラート
- [ ] Container Apps エラー率アラート
- [ ] PostgreSQL CPU使用率アラート
- [ ] PostgreSQL 接続数アラート
- [ ] PostgreSQL ストレージ使用率アラート
- [ ] アクショングループ設定（メール通知等）
- [ ] デプロイ・検証

**検証項目:**
- [ ] アラートルールが作成されている
- [ ] テストアラートが正常に動作

---

## Phase 11: 本番環境パラメータ 🟡

### 11-1. 本番環境用パラメータファイル作成
- [ ] prod.bicepparamファイル作成
- [ ] 本番環境固有の設定
  - Zone-Redundant HA有効化
  - General Purpose tier
  - より高いスケール上限
- [ ] デプロイ・検証

---

## Phase 12: CI/CDパイプライン 🟢

### 12-1. GitHub Actions ワークフロー
- [ ] Bicepデプロイ用ワークフロー作成
- [ ] OIDC認証設定
- [ ] 環境別デプロイ
- [ ] What-If確認ステップ
- [ ] デプロイ・検証

**検証項目:**
- [ ] GitHub Actionsが正常に動作
- [ ] 各環境へのデプロイ成功

---

## ディレクトリ構造（最終形）

```
apps/iac/
├── main.bicep                      # メインテンプレート
├── modules/
│   ├── network.bicep               # VNet, Subnets
│   ├── nsg.bicep                   # Network Security Groups
│   ├── nat-gateway.bicep           # NAT Gateway
│   ├── monitoring.bicep            # Log Analytics, App Insights
│   ├── postgresql.bicep            # PostgreSQL Flexible Server
│   ├── container-app-environment.bicep
│   ├── container-app.bicep         # Container App (汎用)
│   └── keyvault.bicep              # Key Vault (Phase 9)
├── params/
│   ├── dev.bicepparam              # 開発環境パラメータ
│   ├── staging.bicepparam          # ステージング環境（将来）
│   └── prod.bicepparam             # 本番環境（Phase 11）
├── README.md                       # アーキテクチャ設計書
└── task-list.md                    # このファイル

.github/
└── workflows/
    ├── deploy-infrastructure.yml   # Bicepデプロイ
    └── deploy-app.yml              # アプリケーションデプロイ
```

---

## 凡例

- 🔵 Phase 1-8: 必須実装（基本アーキテクチャ）
- 🟡 Phase 9-11: 推奨実装（セキュリティ・運用強化）
- 🟢 Phase 12: 自動化

---

## 注意事項

1. **段階的デプロイ**: 各フェーズごとに必ずデプロイ・検証を行う
2. **パラメータ化**: 環境ごとに異なる値は必ずパラメータファイルで管理
3. **シークレット管理**: パスワード等はKey Vault統合（Phase 9以降）またはデプロイ時に指定
4. **コスト管理**: 開発環境はBurstable tier, Min Replicas: 0でコスト最適化
5. **命名規則**: リソース名は`{appName}-{environment}-{resourceType}`形式
6. **タグ付け**: 全リソースに`environment`, `project`タグを付与

---

**作成日:** 2025-01-18
**最終更新:** 2025-01-18
