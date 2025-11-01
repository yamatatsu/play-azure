# Azure Container Apps アーキテクチャ設計書

## 1. 概要

本ドキュメントは、Azure Container Appsを中心としたアーキテクチャの設計を記載します。
Azure Container Appsで複数のコンテナアプリケーションを立ち上げ、PostgreSQL Flexible Serverをデータストアとして使用します。

### 主な特徴
- **コンテナネイティブ**: 全てのアプリケーションコンポーネントをコンテナ化
- **マネージドサービス活用**: インフラ管理の負荷を最小化
- **スケーラブル**: 負荷に応じた自動スケーリング
- **セキュア**: VNet統合による多層防御
- **IaCによる管理**: Bicepによる宣言的なインフラ管理

## 2. アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓
              ┌──────────────────────┐
              │  Azure Load Balancer │ (Container Apps組み込み)
              │   + TLS Termination  │
              └──────────┬───────────┘
                         │
┌────────────────────────┼────────────────────────────────┐
│ VNet (10.0.0.0/16)     │                                │
│                        ↓                                │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Container Apps Subnet (10.0.0.0/23)              │   │
│  │ ┌─────────────────────────────────────────────┐  │   │
│  │ │ Container Apps Environment                  │  │   │
│  │ │                                             │  │   │
│  │ │  ┌──────────────────┐  ┌─────────────────┐  │  │   │
│  │ │  │   Web Server     │  │  Queue Worker   │  │  │   │
│  │ │  │  (External)      │  │  (Internal)     │  │  │   │
│  │ │  │  Min: 0, Max: 10 │  │  Min: 0, Max: 10│  │  │   │
│  │ │  └────────┬─────────┘  └────────┬────────┘  │  │   │
│  │ │           │                     │           │  │   │
│  │ └───────────┼─────────────────────┼───────────┘  │   │
│  └─────────────┼─────────────────────┼──────────────┘   │
│                │                     │                  │
│                │  ┌──────────────────┘                  │
│                │  │                                     │
│                ↓  ↓                                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │ PostgreSQL Subnet (10.0.2.0/24)                  │   │
│  │ ┌──────────────────────────────────────────────┐ │   │
│  │ │  PostgreSQL Flexible Server                  │ │   │
│  │ │  - Zone-Redundant HA                         │ │   │
│  │ │  - VNet Integration                          │ │   │
│  │ └──────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │ NAT Gateway Subnet                               │   │
│  │ ┌──────────────────────────────────────────────┐ │   │
│  │ │  NAT Gateway (Fixed Public IP)               │ │   │
│  │ │  - Container Apps Outbound                   │ │   │
│  │ └──────────────────────────────────────────────┘ │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│               Monitoring and Log                        │
│  ┌──────────────────┐     ┌────────────────────────┐    │
│  │ Log Analytics    │ ←── │ Application Insights   │    │
│  │  Workspace       │     │                        │    │
│  └──────────────────┘     └────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## 3. 技術スタック

### インフラストラクチャ

| カテゴリ | 技術 | 用途 |
|---------|------|------|
| **IaC** | Bicep | インフラ定義・管理 |
| **ネットワーク** | Azure VNet | プライベートネットワーク |
| **NSG** | Network Security Group | ネットワークセキュリティ |
| **NAT** | NAT Gateway | 固定送信元IP |
| **コンピュート** | Azure Container Apps (Consumption) | アプリケーションホスティング |
| **データベース** | PostgreSQL Flexible Server | リレーショナルデータベース |
| **監視** | Log Analytics + Application Insights | ログ集約・APM |
| **CI/CD** | GitHub Actions | デプロイメント自動化 |

### アプリケーション

- **Webサーバー**: HTTPリクエストを処理するフロントエンド/API
- **キュー処理ワーカー**: 非同期タスクを処理するバックグラウンドワーカー

## 4. コンポーネント詳細

### 4.1 VNet (Virtual Network)

```
VNet: 10.0.0.0/16

サブネット構成:
├─ Container Apps Subnet: 10.0.0.0/23 (512 IPs)
│  └─ 委任: Microsoft.App/environments
├─ PostgreSQL Subnet: 10.0.2.0/24 (256 IPs)
│  └─ 委任: Microsoft.DBforPostgreSQL/flexibleServers
└─ (将来の拡張用): 10.0.3.0/24以降
```

**設計ポイント:**
- Container Apps Subnetは最低/23（512アドレス）が必要
- 各サブネットにNSGを適用してセキュリティ制御
- VNet Peering、VPN Gateway等の将来的な拡張に備えた十分なアドレス空間

### 4.2 NAT Gateway

```
Public IP: 固定IP (Standard SKU)
用途: Container Appsのアウトバウンド通信
```

**必要な理由:**
- 外部API呼び出し時の送信元IPを固定
- 外部サービスのIP許可リスト対応
- SNAT枯渇の防止（64,000ポート/IP確保）
- ログ追跡・監査要件への対応

**接続:**
- Container Apps Subnetに紐付け
- 全てのアウトバウンド通信がこのIPから送信される

### 4.3 PostgreSQL Flexible Server

```
構成:
- SKU: General Purpose (本番) / Burstable (開発)
- バージョン: PostgreSQL 15
- HA: Zone-Redundant (本番環境)
- ネットワーク: VNet統合（Private Access）
- バックアップ: 未検討（要件に応じて設定）
```

**特徴:**
- VNet統合によりプライベートアクセスのみ
- 自動フェイルオーバー（Zone-Redundant HA）
- Container AppsからVNet内部で直接接続
- Private DNS Zoneによる名前解決

**接続文字列:**
```
postgresql://{username}:{password}@{server-name}.postgres.database.azure.com:5432/{database}?sslmode=require
```

### 4.4 Container Apps - Web Server

```
構成:
- Ingress: External (インターネット公開)
- Port: 8080 (または80/443)
- スケール:
  - Min Replicas: 0 (トラフィックなし時は停止)
  - Max Replicas: 10
  - Scale Rule: HTTP Concurrent Requests
- リソース:
  - CPU: 0.5 vCPU
  - Memory: 1Gi
```

**特徴:**
- HTTPリクエスト数に応じた自動スケール
- 0スケール対応（コスト最適化）
- Azure Load BalancerによるTLS終端
- ヘルスチェック自動設定

### 4.5 Container Apps - Queue Worker

```
構成:
- Ingress: Internal (VNet内部のみ、またはIngress無効)
- スケール:
  - Min Replicas: 0
  - Max Replicas: 10
  - Scale Rule: Queue Length (例: 5メッセージ/コンテナ)
- リソース:
  - CPU: 0.5 vCPU
  - Memory: 1Gi
```

**特徴:**
- キューの深さに応じた自動スケール（KEDA統合）
- HTTPエンドポイント不要（プロセスのみ実行）
- 処理がない時は0スケールでコスト削減
- PostgreSQLへはVNet内部で接続

**対応キューサービス（例）:**
- Azure Storage Queue
- Azure Service Bus
- Kafka
- Redis
- その他KEDA対応サービス

### 4.6 Container Apps Environment

```
構成:
- VNet統合: Container Apps Subnetに配置
- Internal Load Balancer Environment: No (Webサーバーは外部公開)
- ワークロードプロファイル: Consumption
```

**環境内の構成:**
- 複数のContainer Apps（Web、Worker）を管理
- 共有のネットワーク・スケーリング基盤
- Log Analyticsへのログ統合
- Application Insightsへのメトリクス送信

### 4.7 監視・ログ基盤

#### Log Analytics Workspace
```
用途:
- Container Appsのコンテナログ
- PostgreSQLのクエリログ・監視ログ
- NSGフローログ（オプション）
- システムログの集約
```

#### Application Insights
```
用途:
- アプリケーションパフォーマンス監視（APM）
- リクエスト追跡・分散トレーシング
- 例外・エラー追跡
- カスタムメトリクス
```

**統合:**
- Container Appsから自動的にテレメトリ送信
- Log Analyticsと連携してクエリ可能
- ダッシュボードでの可視化

**アラート設定:**
- 未検討（要件定義後に設定）
- 例: エラー率、レスポンスタイム、可用性など

## 5. 技術選定理由

### 5.1 なぜBicepか

```
✓ Microsoftの長期サポート保証
✓ VSCodeでのリアルタイム型チェック
✓ IntelliSenseによる強力な補完
✓ 定義へのジャンプ機能
✓ サンプルコードが豊富
```

**Terraformとの比較:**
- Terraform: ブラウザでドキュメント確認が必要、型チェックが弱い
- Bicep: エディタ内で完結、リアルタイムエラー検出

**選択しなかった理由:**
- **Terraform**: マルチクラウド不要。DXがBicepに劣る
- **ARM Template (JSON)**: 冗長で可読性が低い。Bicepが上位互換

### 5.2 なぜContainer Appsか（App Serviceではない）

#### コンテナネイティブ
```
App Service:
- Webアプリケーション前提の設計
- コンテナ対応は後付け
- HTTPエンドポイントが必須

Container Apps:
✓ コンテナ実行に最適化
✓ 非Webサーバーもネイティブサポート
✓ HTTPエンドポイント不要なワークロード対応
```

#### キュー処理ワーカーへの対応
```
App Service:
- WebJobsで対応可能だがレガシー
- コンテナベースではない

Container Apps:
✓ KEDAによるキューベーススケーリング組み込み
✓ コンテナで統一的に実装
✓ Storage Queue, Service Bus等に標準対応
```

### 5.3 なぜConsumptionプランか

#### リソース要件の確認
```
想定ワークロード:
- 1コンテナあたり: 0.5-1 vCPU, 1-2GB メモリ
- Consumption上限: 4 vCPU, 8GB

判断:
✓ Consumption上限内で十分
✓ 水平スケールで対応可能
```

#### 運用のシンプルさ
```
Consumption:
✓ 完全マネージド
✓ ノード管理不要
✓ 自動スケーリングが簡単

Workload Profiles:
- ノードプール管理が必要
- より複雑な設定
```

**Workload Profilesが必要になるケース:**
```
以下の場合は移行を検討:
- 単一プロセスで8GB超のメモリ必要
- 常時高負荷でConsumptionより割高
- より予測可能なパフォーマンスが必須
```

**現時点の判断:**
- Consumptionで開始
- 必要に応じてWorkload Profilesへ移行可能
- 同一環境内でConsumptionとWorkload Profiles混在も可能

## 6. セキュリティ考慮事項

### 6.1 ネットワークセキュリティ

#### 多層防御
```
レイヤー1: Azure Load Balancer
- DDoS Protection Basic
- TLS終端

レイヤー2: NSG (Network Security Group)
- サブネットレベルでトラフィック制御
- 最小権限の原則

レイヤー3: Container Apps Platform
- IP制限（ipSecurityRestrictions）
- Easy Auth（必要に応じて）

レイヤー4: アプリケーション
- 認証・認可ロジック
```

#### NSG設定例

**Container Apps Subnet:**
```
Inbound:
- Allow HTTPS (443) from Internet
- Allow HTTP (80) from Internet (HTTPSリダイレクト用)
- Allow Azure Load Balancer
- Deny All Other

Outbound:
- Allow All (VNet内、インターネット経由NAT Gateway)
```

**PostgreSQL Subnet:**
```
Inbound:
- Allow PostgreSQL (5432) from Container Apps Subnet
- Deny All Other

Outbound:
- Allow All (バックアップ、レプリケーション用）
```

### 6.2 データ保護

#### 転送中の暗号化
```
✓ Container Apps: HTTPS/TLS 1.2+必須
✓ PostgreSQL: SSL/TLS接続必須 (sslmode=require)
✓ VNet内通信: プライベートネットワーク
```

#### 保管中の暗号化
```
✓ PostgreSQL: 自動的にディスク暗号化
✓ Container Apps: エフェメラルストレージ（永続化非推奨）
✓ Secrets: Container Apps Secretsとして暗号化保存
```

#### シークレット管理
```
推奨:
- Azure Key Vault統合（本番環境）
- Container Apps Secrets（開発環境）

避けるべき:
✗ 環境変数への平文保存
✗ ソースコードへのハードコード
✗ パラメータファイルへの平文記載
```

### 6.3 アクセス制御

#### Azure RBAC
```
最小権限の原則:
- 開発者: Contributor (リソースグループスコープ)
- CI/CD: 専用のService Principal
- 監視: Reader
```

#### Container Apps Managed Identity
```
✓ システム割り当てマネージドID
✓ PostgreSQLへの認証（AAD統合）
✓ Key Vaultアクセス
✓ Azure Container Registryへのpull
```

### 6.4 コンプライアンス

#### ログ・監査
```
✓ すべてのログをLog Analyticsに集約
✓ 90日以上の保持（要件に応じて）
✓ 変更履歴の追跡（Bicepデプロイログ）
✓ アクセスログの記録
```

## 7. スケーラビリティ・可用性

### 7.1 Container Apps スケーリング

#### Webサーバー
```
スケーリングルール:
1. HTTP Concurrent Requests
   - 10リクエスト/コンテナで新規レプリカ起動
   
2. CPU使用率
   - 70%超過で追加レプリカ

制限:
- Min: 0 (コスト最適化)
- Max: 10 (初期設定、調整可能)
```

#### キュー処理ワーカー
```
スケーリングルール:
1. Queue Length (KEDA)
   - 10メッセージ/コンテナ
   - キュー深さに応じて自動スケール

制限:
- Min: 0 (処理なし時は停止)
- Max: 10 (バースト対応)
```

#### スケーリング挙動
```
スケールアウト: 30-60秒
スケールイン: 数分（安定化後）
コールドスタート: 数秒（0→1レプリカ）
```

### 7.2 PostgreSQL 可用性

#### Zone-Redundant HA
```
構成:
- プライマリ: Zone 1
- スタンバイ: Zone 2（異なるAZ）

特徴:
✓ 自動フェイルオーバー（60-120秒）
✓ データ同期レプリケーション
✓ ゼロデータロス
✓ AZ障害に対応
```

#### バックアップ
```
未検討（要件定義後に設定）

推奨設定:
- 保持期間: 7-35日
- ポイントインタイムリストア
- Geo-Redundant バックアップ（DRが必要な場合）
```

### 7.3 リージョン冗長化

**現状:** 単一リージョン（Japan East）

### 7.4 障害復旧

#### RTO/RPO（要検討）
```
現在の構成での想定:
- RTO: 数分（自動フェイルオーバー）
- RPO: ほぼ0（同期レプリケーション）
```

#### 障害シナリオ

**Container Appsインスタンス障害:**
```
影響: 単一レプリカのみ
対応: 自動的に新規レプリカ起動
ダウンタイム: なし（複数レプリカ稼働時）
```

**PostgreSQL障害:**
```
影響: データベース接続不可
対応: Zone-Redundant HAによる自動フェイルオーバー
ダウンタイム: 60-120秒
```

**AZ障害:**
```
Container Apps: 自動的に他のAZでレプリカ起動
PostgreSQL: スタンバイへフェイルオーバー
ダウンタイム: 数分以内
```

## 8. デプロイメント戦略

### 8.1 環境構成

```
環境:
├─ Development (dev)
│  - リソースグループ: yamatatsu-lab
│  - 最小構成（コスト最適化）
│  - PostgreSQL: Burstable tier
│  - Container Apps: Min 0, Max 3
│
├─ Staging (staging)
│  - 未定
│
└─ Production (prod)
   - 未定
```

### 8.2 Bicep構成

```
ディレクトリ構造:

├── main.bicep
├── modules/
│   ├── network.bicep
│   ├── nat-gateway.bicep
│   ├── postgresql.bicep
│   ├── container-app-environment.bicep
│   ├── container-app.bicep
│   └── monitoring.bicep
└── params/
    ├── dev.bicepparam
    ├── staging.bicepparam
    └── prod.bicepparam
```

### 8.3 CD ワークフロー

- GitHub Actionsを使用
- OIDC認証でAzureログイン

#### Bicep デプロイ
例:
```yaml
name: Deploy Infrastructure

on:
  push:
    branches:
      - main
    paths:
      - 'apps/iac/**'
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - dev
          - staging
          - prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Deploy Bicep
        uses: azure/arm-deploy@v1
        with:
          scope: resourcegroup
          resourceGroupName: yamatatsu-lab-v1-${{ github.event.inputs.environment }}-rg
          template: ./apps/iac/main.bicep
          parameters: ./apps/iac/params/${{ github.event.inputs.environment }}.bicepparam
```

#### アプリケーションデプロイ
例:
```yaml
name: Deploy Application

on:
  push:
    branches:
      - main
    paths:
      - 'src/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Push Docker Image
        run: |
          docker build -t myregistry.azurecr.io/app:${{ github.sha }} .
          docker push myregistry.azurecr.io/app:${{ github.sha }}
      
      - name: Update Container App
        run: |
          az containerapp update \
            --name yamatatsu-lab-v1-web \
            --resource-group yamatatsu-lab \
            --image myregistry.azurecr.io/app:${{ github.sha }}
```

### 8.4 デプロイ戦略

#### Blue/Green デプロイ
```
Container Appsのリビジョン機能を使用:
1. 新リビジョンをデプロイ（トラフィック0%）
2. ヘルスチェック確認
3. トラフィックを段階的に移行（10% → 50% → 100%）
4. 旧リビジョンを削除
```

#### カナリアリリース
本サービスでは以下の理由によりカナリアリリースは採用しない。

- アクティブユーザーが常に1人以上存在することは想定されない。
- リリースは数分から数十分程度で完了し、長時間にわたるリリースは不要。

### 8.5 ロールバック

```bash
# 前のリビジョンに即座に切り替え
az containerapp revision set-mode \
  --name yamatatsu-lab-v1-web \
  --resource-group yamatatsu-lab \
  --mode single

az containerapp revision activate \
  --name yamatatsu-lab-v1--rev-previous \
  --resource-group yamatatsu-lab
```

## 9. 運用・監視

### 9.1 ログ収集

#### Container Apps
```
収集内容:
- コンテナ標準出力/エラー出力
- システムログ
- HTTPアクセスログ（Ingress有効時）
- スケーリングイベント

保存先:
- Log Analytics Workspace
- Application Insights（トレース統合）
```

#### PostgreSQL
```
収集内容:
- 接続ログ
- パフォーマンスメトリクス
- エラーログ

保存先:
- Log Analytics Workspace
```

クエリログはBicepにて有効化方法を示しつつ、明示的に無効化する。

### 9.2 メトリクス監視

#### Container Apps
```
主要メトリクス:
- CPU使用率
- メモリ使用率
- レプリカ数
- HTTPリクエスト数
- レスポンスタイム
- エラー率
```

#### PostgreSQL
```
主要メトリクス:
- CPU使用率
- メモリ使用率
- 接続数
- ストレージ使用率
- レプリケーションラグ（HA時）
- クエリパフォーマンス
```

### 9.3 Application Insights

```
機能:
- 分散トレーシング
- 依存関係マップ
- パフォーマンス分析
- 例外追跡
- カスタムイベント

統合:
- Container Appsから自動収集
- アプリケーションSDK統合（推奨）
```

### 9.4 アラート設定

**未検討（今後設定予定）**

推奨アラート例:
```
- Container Apps CPU > 80%（5分継続）
- Container Apps エラー率 > 5%
- PostgreSQL CPU > 80%
- PostgreSQL 接続数 > 閾値の80%
- PostgreSQL ストレージ > 80%
- スケーリング失敗
```

### 9.5 ダッシュボード

```
推奨構成:
- Azure ダッシュボードで全体概観
- Application Insights Live Metricsで リアルタイム監視
- Log Analyticsで詳細分析・トラブルシューティング
```

## 10. 今後の拡張性

### 10.1 Application Gateway + WAF 追加

**現状:** Container Apps組み込みのIngressを使用

**将来的な拡張（WAFが必要な場合）:**

```
アーキテクチャ変更:
Internet
    ↓
Application Gateway + WAF
    ↓ (VNet内)
Container Apps (Internal Ingressに変更)
```

#### 追加されるメリット
```
✓ Web Application Firewall (OWASP対応)
✓ より高度なルーティングルール
✓ カスタムエラーページ
✓ SSL/TLSポリシーの細かい制御
✓ 複雑なパスベースルーティング
```

#### 追加コスト
```
Application Gateway WAF_v2:
- 固定費: ~$300/月
- データ処理: ~$0.008/GB

判断:
- セキュリティ要件が厳しい場合に追加検討
- コンプライアンス要件（金融、医療等）
- 現時点では不要と判断
```

### 10.2 その他の拡張候補

#### Azure Front Door
```
用途:
- グローバル負荷分散
- CDN機能
- マルチリージョン対応

タイミング:
- グローバル展開時
- レイテンシ最適化が必要な場合
```

#### Azure Cache for Redis
```
用途:
- セッション管理
- キャッシュ層
- レート制限

タイミング:
- パフォーマンス要求の高まり
- データベース負荷軽減
```

#### Azure API Management
```
用途:
- API統合管理
- レート制限・クォータ
- APIバージョン管理

タイミング:
- 外部API公開
- パートナー連携
```

#### Azure Service Bus
```
用途:
- より高度なメッセージング
- トピック/サブスクリプション
- Dead Letter Queue

タイミング:
- キュー処理の高度化
- メッセージ保証が必要
```

## 11. 付録

### 11.1 主要コマンド

#### デプロイ
```bash
# 開発環境
az deployment group what-if --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam
az deployment group create --resource-group yamatatsu-lab --template-file main.bicep --parameters params/dev.bicepparam

# 本番環境
az deployment group what-if --resource-group yamatatsu-lab --template-file main.bicep --parameters params/prod.bicepparam
az deployment group create --resource-group yamatatsu-lab --template-file main.bicep --parameters params/prod.bicepparam
```

#### ログ確認
```bash
# Container Appsログ
az containerapp logs show --name yamatatsu-lab-v1-web --resource-group yamatatsu-lab --follow

# PostgreSQLログ（Log Analytics経由）
az monitor log-analytics query --workspace {workspace-id} --analytics-query "AzureDiagnostics | where ResourceType == 'POSTGRESQL' | take 100"
```

### 11.2 参考リソース

- [Azure Container Apps Documentation](https://learn.microsoft.com/azure/container-apps/)
- [Azure PostgreSQL Flexible Server Documentation](https://learn.microsoft.com/azure/postgresql/flexible-server/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [KEDA Scalers](https://keda.sh/docs/scalers/)
- [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview)

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-18  
**Author:** わーい。わーい。やまたつだよー。