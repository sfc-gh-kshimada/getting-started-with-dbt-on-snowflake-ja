# Snowflakeでdbt Projectsを始める

## 概要

このリポジトリは、Snowflake上でdbt Projectsを始めるためのサンプルプロジェクトです。

dbt Coreはオープンソースのデータ変換ツールで、SQLによるデータ変換の定義、テスト、デプロイを行うことができます。Snowflake上のdbt Projectsでは、Snowflakeの機能を使用してdbt Coreプロジェクトの作成、編集、テスト、実行、管理を行うことができます。

## 前提条件

- dbtの基本概念への理解
- Snowflakeアカウント

## 学べること

- Workspaces（Snowflakeのファイルベースの統合開発環境）の使い方
- リモートdbtプロジェクトをWorkspacesに取り込む方法
- Snowflake内でdbt Projectsを実行、編集、デプロイする方法
- Snowflake内からdbt Projectsのデプロイとオーケストレーションを行う方法

## セットアップ

このラボではTasty Bytesのデータを使用します。以下のスクリプトを実行して、必要なオブジェクトとデータを構築してください。

**セットアップスクリプト**: `tasty_bytes_dbt_demo/setup/tasty_bytes_setup.sql`

### 実行方法

1. Snowsightの**Worksheets**で新しいワークシートを作成
2. セットアップスクリプトの内容をコピーして実行
3. または**Workspaces**で新しいSQLファイルとして実行

## Workspacesの紹介

Workspacesは、Snowflake内でdbtプロジェクトを編集、テスト、デプロイできる開発環境です。パーソナルワークスペースでは、ファイルの作成や編集を行うことができます。

**アクセス方法**: Snowsightで **Projects > Workspaces** に移動

### データの確認

ラボで使用するデータを確認するには:

1. Workspaceで新しいSQLファイル `data_profile.sql` を作成
2. 以下のクエリを実行してデータを確認

```sql
USE WAREHOUSE tasty_bytes_dbt_wh;
USE ROLE accountadmin; 

-- どのテーブルが存在するか確認
SHOW TABLES IN SCHEMA tasty_bytes_dbt_db.raw;

-- データの規模を確認
SELECT COUNT(*) FROM tasty_bytes_dbt_db.raw.order_header;

-- マートで使用されるクエリの例 - 顧客別の売上集計
SELECT 
    cl.customer_id,
    cl.city,
    cl.country,
    cl.first_name,
    cl.last_name,
    cl.phone_number,
    cl.e_mail,
    SUM(oh.order_total) AS total_sales,
    ARRAY_AGG(DISTINCT oh.location_id) AS visited_location_ids_array
FROM tasty_bytes_dbt_db.raw.customer_loyalty cl
JOIN tasty_bytes_dbt_db.raw.order_header oh
ON cl.customer_id = oh.customer_id
GROUP BY cl.customer_id, cl.city, cl.country, cl.first_name,
cl.last_name, cl.phone_number, cl.e_mail;
```

### GitHubからdbtプロジェクトを作成

1. **Workspace**ドロップダウン > **Create Workspace From Git Repository** をクリック
2. 以下の情報を入力:
   - **Repository URL**: `https://github.com/sfc-gh-kshimada/getting-started-with-dbt-on-snowflake-ja`
   - **Workspace Name**: `Example-dbt-Project`
   - **API Integration**: `GIT_INTEGRATION`
   - **Public Repository** を選択
3. **Create** をクリック

## dbt Projectsの操作

### サンプルプロジェクト

このラボではTasty Bytesのデータを使用します。rawデータには売上データ、トラックのメタデータ、顧客情報が含まれています。これらはdbtで変換され、Snowflakeにテーブルとして保存されます。

### 新しいモデルの追加

`tasty_bytes_dbt_demo/models/marts/sales_data_by_truck.sql` を作成し、以下のコードをコピー:

```sql
with order_details as (
    select 
        od.order_id,
        od.menu_item_id,
        od.quantity,
        od.price,
        oh.truck_id,
        oh.order_ts,
        m.menu_type,
        m.truck_brand_name,
        m.item_category
    from {{ ref('raw_pos_order_detail') }} od
    inner join {{ ref('raw_pos_order_header') }} oh on od.order_id = oh.order_id
    inner join {{ ref('raw_pos_menu') }} m on od.menu_item_id = m.menu_item_id
)

select
    truck_brand_name,
    menu_type,
    item_category,
    date_trunc('month', order_ts) as sales_month,
    sum(quantity) as total_items_sold,
    sum(price) as total_revenue,
    count(distinct order_id) as total_orders
from order_details
where truck_brand_name is not null
group by 1, 2, 3, 4
order by 1, 2, 3, 4
```

### profiles.ymlの設定

各dbtプロジェクトフォルダには `profiles.yml` が必要です。このファイルでターゲットとなるwarehouse、database、schema、roleを指定します。

- `type` は `snowflake` に設定
- `account` と `user` は空欄でOK（現在のアカウントとユーザーコンテキストで実行されるため）

### dbt compile

dbtツールバーのドロップダウンから**compile**を選択して実行します。

- **View Compiled SQL**: コンパイル後、個別のモデルから「View Compiled SQL」ボタンをクリックすると、実際に参照するテーブルやビューを確認できます
- **View the DAG**: トップツールバーから「DAG」をクリックしてモデル間の依存関係を確認できます

### dbt run

dbtツールバーから**run**を選択し、再生ボタンをクリックしてプロジェクトを実行します。完了後、martsテーブルにデータが格納されます。

### dbt deps（オプション）

**注意**: `dbt deps` にはExternal Access Integrationが必要です（Snowflakeトライアルアカウントでは非サポート）。

#### External Access Integrationの作成

```sql
USE ROLE accountadmin;

CREATE OR REPLACE NETWORK RULE tasty_bytes_dbt_db.public.dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('hub.getdbt.com', 'codeload.github.com');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_access_integration
  ALLOWED_NETWORK_RULES = (tasty_bytes_dbt_db.public.dbt_network_rule)
  ENABLED = true;
```

#### packages.ymlの設定

`packages.yml` のコメントを解除:

```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.3.0 
  - package: Snowflake-Labs/dbt_semantic_view
    version: 1.0.3
```

dbtツールバーから**deps**を選択し、`dbt_access_integration` を入力して実行します。

### dbt test（オプション）

`dbt deps` の実行後に利用可能です。

`tasty_bytes_dbt_demo/models/staging/__sources.yml` にデータテストが定義されています。219行目の `max_value` を `10000` に修正してテストを通過させます:

```yaml
        - dbt_utils.accepted_range:
            min_value: 0
            max_value: 10000
            inclusive: true
```

### Semantic Viewのビルド（オプション）

`dbt_semantic_view` パッケージを使用してSemantic Viewを構築できます。

`models/semantic_views/order_analytics.sql` を作成:

```sql
{{ config(materialized='semantic_view') }}

TABLES(
  order_header AS {{ ref('raw_pos_order_header') }} PRIMARY KEY (order_id),
  order_detail AS {{ ref('raw_pos_order_detail') }} PRIMARY KEY (order_detail_id),
  menu AS {{ ref('raw_pos_menu') }} PRIMARY KEY (menu_item_id),
  truck AS {{ ref('raw_pos_truck') }} PRIMARY KEY (truck_id),
  location AS {{ ref('raw_pos_location') }} PRIMARY KEY (location_id)
)
RELATIONSHIPS (
  OrderToDetail AS order_detail(order_id) REFERENCES order_header(order_id),
  DetailToMenu AS order_detail(menu_item_id) REFERENCES menu(menu_item_id),
  OrderToTruck AS order_header(truck_id) REFERENCES truck(truck_id),
  OrderToLocation AS order_header(location_id) REFERENCES location(location_id)
)
FACTS (
  order_detail.quantity AS quantity,
  order_detail.price AS price,
  order_header.order_amount AS order_amount,
  order_header.order_total AS order_total
)
DIMENSIONS (
  order_header.order_ts AS order_ts,
  order_header.order_channel AS order_channel,
  menu.menu_item_name AS menu_item_name,
  menu.item_category AS item_category,
  menu.truck_brand_name AS truck_brand_name,
  truck.primary_city AS primary_city,
  truck.country AS country,
  truck.ev_flag AS ev_flag,
  location.city AS city,
  location.region AS region
)
METRICS (
  order_detail.total_revenue AS SUM(order_detail.price),
  order_detail.total_quantity AS SUM(order_detail.quantity),
  order_header.avg_order_value AS AVG(order_header.order_total),
  order_header.max_order_total AS MAX(order_header.order_total)
)
COMMENT = 'Semantic view for order analytics'
```

### dbt Projectのデプロイ

1. Workspacesの右上にある **Deploy** をクリック
2. ロールを `accountadmin` に設定
3. データベース `tasty_bytes_dbt_db`、スキーマ `raw` を選択
4. 名前を `dbt_project` に設定
5. **Deploy** をクリック

### Gitの確認

Workspacesは完全にGitバックアップされています。ファイルセレクターから「changes」をクリックして変更を確認し、コミットできます。

## オーケストレーションとモニタリング

### タスクによるオーケストレーション

**Catalog > Database Explorer > TASTY_BYTES_DBT_DB > RAW > dbt Projects > DBT_PROJECT** でプロジェクトの詳細を確認できます。

#### スケジュールタスクの作成

1. **Project Details** タブに移動
2. **Schedules** ドロップダウンから **Create Schedule** をクリック
3. 名前、スケジュール、プロファイルを入力して作成

#### 複雑なタスクとアラート

```sql
USE WAREHOUSE tasty_bytes_dbt_wh;
USE ROLE accountadmin;

CREATE OR REPLACE TASK tasty_bytes_dbt_db.raw.dbt_run_task
    WAREHOUSE=TASTY_BYTES_DBT_WH
    SCHEDULE='60 MINUTES'
    AS EXECUTE DBT PROJECT "TASTY_BYTES_DBT_DB"."RAW"."DBT_PROJECT" args='run --target dev';

CREATE OR REPLACE TASK tasty_bytes_dbt_db.raw.dbt_test_task
    WAREHOUSE=TASTY_BYTES_DBT_WH
    AFTER tasty_bytes_dbt_db.raw.dbt_run_task
    AS EXECUTE DBT PROJECT "TASTY_BYTES_DBT_DB"."RAW"."DBT_PROJECT" args='test --target dev';

ALTER TASK tasty_bytes_dbt_db.raw.dbt_test_task RESUME;
EXECUTE TASK tasty_bytes_dbt_db.raw.dbt_run_task;
```

### dbt Projectsのモニタリング

**Transformation > dbt Projects** でdbt Projectsの全体的なステータスを確認できます。

### トレーシング

dbt ProjectsはSnowflakeのトレーシングとログ機能と統合されています。OpenTelemetry標準に準拠しており、単一プラットフォームでログを管理できます。

**確認方法**: **Monitoring > Traces & Logs** に移動

### コストモニタリング

**Admin > Cost Management > Consumption Tab** で使用状況を確認できます。dbt専用のwarehouseを作成することで、モニタリングが容易になります。

## プロジェクト構造

```
tasty_bytes_dbt_demo/
├── dbt_project.yml          # プロジェクト設定
├── profiles.yml             # 接続設定
├── packages.yml             # 依存パッケージ
├── models/
│   ├── staging/             # ステージングモデル
│   │   ├── __sources.yml    # ソース定義
│   │   └── raw_pos_*.sql    # rawテーブルのステージング
│   └── marts/               # マートモデル
│       ├── customer_loyalty_metrics.sql
│       ├── orders.sql
│       └── sales_metrics_by_location.py
├── macros/
│   └── generate_schema_name.sql
├── tests/
│   └── generic/
└── setup/
    └── tasty_bytes_setup.sql
```

## まとめ

このラボを完了することで、以下を習得できます:

- Workspaces（Snowflakeのファイルベースの統合開発環境）の使い方
- リモートdbtプロジェクトをWorkspacesに取り込む方法
- Snowflake内でdbt Projectsを実行、編集、デプロイする方法
- Snowflake内からdbt Projectsのデプロイとオーケストレーションを行う方法

## 関連リソース

- [dbt Projects on Snowflake ドキュメント](https://docs.snowflake.com/user-guide/data-engineering/dbt-projects-on-snowflake)
- [GitHubリポジトリ: getting-started-with-dbt-on-snowflake-ja](https://github.com/sfc-gh-kshimada/getting-started-with-dbt-on-snowflake-ja)
- [dbt Core ドキュメント](https://docs.getdbt.com/)
- [Semantic View ブログ](https://www.snowflake.com/en/engineering-blog/dbt-semantic-view-package/)
