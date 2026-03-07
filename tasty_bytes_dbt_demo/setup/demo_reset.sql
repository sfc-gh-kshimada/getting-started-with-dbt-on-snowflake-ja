-- =====================================
-- デモリセット用スクリプト
-- =====================================
-- デモを最初からやり直すためのクリーンアップSQL
-- 
-- リセットレベル:
--   軽量: セクション1のみ（martsテーブル削除）
--   標準: セクション1 + 2（stagingビュー含めて削除）
--   完全: セクション1 + 2 + 3（デプロイ済みプロジェクトも削除）
-- =====================================

USE ROLE accountadmin;
USE WAREHOUSE tasty_bytes_dbt_wh;

-- =====================================
-- セクション1: martsテーブルを削除（DEV環境）
-- =====================================
-- dbt runで作成されたテーブルを削除

-- プロジェクト標準のモデル
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.orders;
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.customer_loyalty_metrics;
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.sales_metrics_by_location;

-- デモ/サンプルで作成されるモデル
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.monthly_sales_by_brand;
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.sales_data_by_truck;
DROP TABLE IF EXISTS tasty_bytes_dbt_db.dev.sales_by_brand_monthly;

-- PROD環境も削除する場合（必要に応じて）
-- DROP TABLE IF EXISTS tasty_bytes_dbt_db.prod.orders;
-- DROP TABLE IF EXISTS tasty_bytes_dbt_db.prod.customer_loyalty_metrics;
-- DROP TABLE IF EXISTS tasty_bytes_dbt_db.prod.sales_metrics_by_location;
-- DROP TABLE IF EXISTS tasty_bytes_dbt_db.prod.monthly_sales_by_brand;
-- DROP TABLE IF EXISTS tasty_bytes_dbt_db.prod.sales_data_by_truck;

-- =====================================
-- セクション2: stagingビューを削除（DEV環境）
-- =====================================
-- stagingはビューなので残っていても問題ないが、
-- 完全にやり直す場合は削除

DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_country;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_franchise;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_location;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_menu;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_order_detail;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_order_header;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_pos_truck;
DROP VIEW IF EXISTS tasty_bytes_dbt_db.dev.raw_customer_customer_loyalty;

-- =====================================
-- セクション3: デプロイ済みdbt projectを削除
-- =====================================
-- 再デプロイする場合に実行

DROP DBT PROJECT IF EXISTS tasty_bytes_dbt_db.raw.dbt_project;

-- =====================================
-- セクション4: スキーマごと削除して再作成（完全リセット）
-- =====================================
-- 注意: すべてのオブジェクトが削除されます
-- 必要な場合のみコメントを外して実行

-- DROP SCHEMA IF EXISTS tasty_bytes_dbt_db.dev CASCADE;
-- DROP SCHEMA IF EXISTS tasty_bytes_dbt_db.prod CASCADE;
-- CREATE SCHEMA tasty_bytes_dbt_db.dev;
-- CREATE SCHEMA tasty_bytes_dbt_db.prod;

-- =====================================
-- 確認
-- =====================================

SHOW TABLES IN SCHEMA tasty_bytes_dbt_db.dev;
SHOW VIEWS IN SCHEMA tasty_bytes_dbt_db.dev;
SHOW DBT PROJECTS IN SCHEMA tasty_bytes_dbt_db.raw;
