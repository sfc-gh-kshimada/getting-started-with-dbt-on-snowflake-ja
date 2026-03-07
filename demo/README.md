# Snowpark & Cortex Code デモ手順書（5分）

このドキュメントは、dbt Projects on Snowflakeを題材に、SnowparkとCortex Codeの開発支援機能をデモするための手順書です。

## 事前準備チェックリスト

- [ ] Snowsight上でCortex Code (in Snowsight) が有効化済み
- [ ] `tasty_bytes_setup.sql`が実行済みでデータが存在
- [ ] Snowflake上でGit Integrationが設定済み
- [ ] デモをやり直す場合は `demo_reset.sql` を実行済み

```sql
-- データ確認
SELECT COUNT(*) FROM tasty_bytes_dbt_db.raw.order_header;
```

### デモのリセット（やり直す場合）

デモを最初からやり直す場合は、以下のスクリプトを実行してください。

**スクリプト**: `tasty_bytes_dbt_demo/setup/demo_reset.sql`

| リセットレベル | 実行するセクション | 用途 |
|----------------|-------------------|------|
| 軽量 | セクション1のみ | martsだけ消してdbt runからやり直し |
| 標準 | セクション1 + 3 | **推奨**: marts削除 + dbt project削除 |
| 完全 | セクション1 + 2 + 3 | staging含めて完全リセット |

---

## デモの流れ（5分）

| 時間 | ステップ | 内容 | 優先度 |
|------|----------|------|--------|
| 0:00-0:30 | 1-2 | Git pull → プロジェクト理解 | 高 |
| 0:30-1:15 | 3-5 | コンパイル → 実行（説明含む） | 高 |
| 1:15-2:15 | 6-7 | データ探索 → dbtモデル生成 | 高 |
| 2:15-3:15 | 8-9 | Snowpark拡張 | 高 |
| 3:15-3:45 | 10 | デプロイ | 中 |
| 3:45-4:30 | 11 | 再実行・結果確認 | 高 |
| 4:30-5:00 | 12 | まとめ | 高 |

※ 時間が押した場合、**テスト（ステップ4）**はスキップ可能
※ **重要**: ファイル編集（ステップ7-9）の後にデプロイ（ステップ10）を行う

---

## ステップ1: Git Pull（0:00-0:15）

### 操作
Snowsight Workspacesで：
1. **Workspace** ドロップダウン → **Create Workspace From Git Repository**
2. Repository URL: `https://github.com/Snowflake-Labs/getting-started-with-dbt-on-snowflake`

### 話すこと
「GitHubからdbtプロジェクトをSnowflakeのWorkspacesに取り込みます。」

---

## ステップ2: プロジェクト理解（0:15-0:30）

### 入力プロンプト（Cortex Code）
```
このdbt Projectの内容を教えて
```

### 期待される出力
- プロジェクト構造の説明（staging → marts の流れ）
- 主要なモデルの説明
- 使用しているデータソースの説明

### 追加操作（推奨）
**DAGを表示**してモデル間の依存関係を視覚的に確認
→ dbtツールバーから「DAG」をクリック

### 話すこと
「Cortex Codeにプロジェクトの全体像を聞いてみます。DAGを見ると、staging層からmarts層への依存関係がわかります。」

---

## ステップ3: コンパイル（0:30-0:45）

### 操作
dbtツールバーから **compile** を選択して実行

### 話すこと
「まずコンパイルして、SQLが正しく生成されるか確認します。」

### 確認ポイント
- 個別モデルから「View Compiled SQL」で実際のSQLを確認可能

---

## ステップ4: テスト（0:45-1:00）※スキップ可

### 操作
dbtツールバーから **test** を選択して実行

### 話すこと
「テストを実行して、データ品質を確認します。not_null、unique、relationshipsなどのテストが定義されています。」

---

## ステップ5: 実行（0:55-1:15）

### 操作
dbtツールバーから **run** を選択して実行

### 実行中の説明ポイント

#### profiles.yml による dev/prod 切り替え
```yaml
tasty_bytes:
  target: dev      # デフォルトはdev
  outputs:
    dev:
      schema: dev
    prod:
      schema: prod
```
「profiles.ymlでdev/prodを切り替えて実行できます。本番とテスト環境を分離できます。」

#### タスクによる自動実行
```sql
CREATE TASK dbt_run_task
  WAREHOUSE = TASTY_BYTES_DBT_WH
  SCHEDULE = '60 MINUTES'
  AS EXECUTE DBT PROJECT "TASTY_BYTES_DBT_DB"."RAW"."DBT_PROJECT" 
     args='run --target dev';
```
「デプロイ後は、Snowflakeのタスクでスケジュール実行できます。」

---

## ステップ6: データ探索（1:15-1:45）

### 入力プロンプト（Cortex Code）
```
Tasty Bytesの売上データを見せて。月別の売上合計と、どのブランドが人気かを知りたい。
```

### 期待される出力
- SQLを自動生成・実行
- 月別売上や人気ブランドの結果が表示される

### 話すこと
「自然言語でデータを探索できます。SQLを書かずに、質問するだけでデータを確認できます。」

---

## ステップ7: dbtモデル生成（1:45-2:15）【ファイル編集】

### 入力プロンプト（Cortex Code）
```
ブランド別の月次売上サマリーを計算するdbtモデルを作成して。models/martsディレクトリに配置して、既存のstagingモデルをref()で参照するようにして。
```

### 期待される出力
- `models/marts/sales_by_brand_monthly.sql` が生成される
- 既存の `ref('raw_pos_order_header')` などを適切に参照

### 操作
**Modify をチェック**して、生成されたコードを確認・適用

### 話すこと
「この分析を定常的に使いたい場合、dbtモデルとして定義します。プロジェクト構造を理解した上で、適切なコードが生成されます。」

---

## ステップ8-9: Snowpark拡張（2:15-3:15）【ファイル編集】

### 話すこと（先に説明）
「既存のSnowpark Pythonモデルを拡張します。このプロジェクトには`sales_metrics_by_location.py`というPythonモデルがあり、Snowpark DataFrameを使っています。

**なぜPythonモデルを使うのか？**
- SQLでは複雑になるウィンドウ関数のチェーン
- MLライブラリ（scikit-learn等）との連携
- 処理のモジュール化・再利用」

### 入力プロンプト（Cortex Code）
```
models/marts/sales_metrics_by_location.py を見て、各ロケーションを売上でランク付けする機能を追加して。Snowparkのwindow関数を使って、TOTAL_SALESの降順でRANKを計算して。
```

### 期待される出力
```python
from snowflake.snowpark.window import Window
from snowflake.snowpark.functions import rank

window_spec = Window.order_by(col("TOTAL_SALES").desc())
final_with_rank = final_with_desc.withColumn("SALES_RANK", rank().over(window_spec))
```

### 操作
**Modify をチェック**して、修正を確認・適用

### Snowpark DataFrameのメリット（話すポイント）

| メリット | 説明 |
|----------|------|
| **複雑なロジックを簡潔に** | ウィンドウ関数のチェーンなど、SQLでは冗長になる処理を読みやすく記述 |
| **モジュール化・再利用** | 処理を関数に分割し、テストや再利用が容易 |
| **ML/外部ライブラリ連携** | pandas, scikit-learn, XGBoostなどとシームレスに統合 |
| **パフォーマンス** | SQL直接実行とほぼ同等（差は5-10%以内）、Lazy Evaluationで最適化 |

### 強調ポイント
「SQLでは複数のCTEやサブクエリになる処理も、DataFrame APIならメソッドチェーンで直感的に書けます。しかもSnowflake上で実行されるので、データ移動は不要です。」

---

## ステップ10: デプロイ（3:15-3:45）

> **重要**: ファイル編集後にデプロイすることで、編集内容が反映されます

### 操作
1. Workspacesの右上にある **Deploy** をクリック
2. ロール: `accountadmin`、データベース: `tasty_bytes_dbt_db`、スキーマ: `raw`
3. 名前: `dbt_project` → **Deploy**

### 確認
**Catalog > Database Explorer > TASTY_BYTES_DBT_DB > RAW > dbt Projects** でプロジェクトを確認

### 話すこと
「編集したファイルをデプロイします。デプロイすると、dbtプロジェクトがSnowflakeオブジェクトとして管理され、タスクでスケジュール実行できるようになります。」

---

## ステップ11: 再実行・結果確認（3:45-4:30）

### 操作
dbtツールバーから **run** を再実行

### 話すこと
「デプロイしたプロジェクトを実行して、編集内容が反映されているか確認します。」

### 注意: 更新したファイルが実行されない場合

**原因**: dbtのインクリメンタル処理やキャッシュが影響している可能性

**対処法**:
```bash
# 方法1: フルリフレッシュ
dbt run --full-refresh

# 方法2: 特定モデルのみ再実行
dbt run --select sales_metrics_by_location

# 方法3: Snowflakeでテーブルを直接DROP
DROP TABLE IF EXISTS tasty_bytes_dbt_db.marts.sales_metrics_by_location;
```

---

## ステップ12: まとめ（4:30-5:00）

### 話すこと
「以上、dbt Projects on SnowflakeとCortex Codeを使った開発支援のデモでした。

**今日のポイント**:

1. **dbt Projects on Snowflake**: Snowflake内でdbtプロジェクトを完結
   - 開発、テスト、デプロイ、スケジュール実行まで一元管理
   - 外部インフラ不要

2. **Snowpark DataFrame**: SQLの限界を超えた高度な処理
   - 複雑なロジック、ML、外部ライブラリをSnowflake上で実現
   - データ移動不要でセキュア

3. **Cortex Code**: 自然言語でSnowflake開発を加速
   - プロジェクト理解、データ探索、コード生成を対話的に実行

**今日見せたことは全てSnowflake上で完結しています。外部ツールは不要です。**」

---

## トラブルシューティング

### Cortex Code (in Snowsight) が表示されない
- アカウントでCortex Codeが有効化されているか確認
- 対象のロールに権限が付与されているか確認

### Git Integrationエラー
```sql
-- Git Integrationの確認
SHOW GIT INTEGRATIONS;

-- 必要に応じて作成
CREATE OR REPLACE API INTEGRATION git_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;
```

### データが存在しない
```sql
-- Snowflake Worksheetで実行
SELECT COUNT(*) FROM tasty_bytes_dbt_db.raw.order_header;
-- 0の場合、setup/tasty_bytes_setup.sqlを実行
```

### 更新したファイルが実行されない
```bash
# 方法1: フルリフレッシュ
dbt run --full-refresh

# 方法2: 特定モデルのみ再実行
dbt run --select sales_metrics_by_location
```

### デモが遅い場合
- 簡略版として、ステップ4（テスト）とステップ7（デプロイ）をスキップ
- 事前にウォームアップとして同様のクエリを実行しておく

---

## 参考リンク

- [Cortex Code ドキュメント](https://docs.snowflake.com/en/user-guide/cortex-code)
- [Snowpark Python ドキュメント](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)
- [dbt Projects on Snowflake](https://docs.snowflake.com/user-guide/data-engineering/dbt-projects-on-snowflake)
