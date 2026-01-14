# 自己進化型開発ループ

## 技術ドキュメント v2.0

> 継続的な学習と適応を通じて、実行戦略を動的に生成、検証、進化させるメタ自動化システム。

---

## 目次

1. [はじめに](#はじめに)
2. [理論的基盤](#理論的基盤)
3. [アーキテクチャ概要](#アーキテクチャ概要)
4. [フェーズ詳細](#フェーズ詳細)
5. [メモリシステム](#メモリシステム)
6. [安全アーキテクチャ](#安全アーキテクチャ)
7. [コンテキスト管理](#コンテキスト管理)
8. [実装詳細](#実装詳細)
9. [使用ガイド](#使用ガイド)
10. [トラブルシューティング](#トラブルシューティング)
11. [学術参考文献](#学術参考文献)

---

## はじめに

### 自己進化ループとは？

自己進化型開発ループは、従来の開発自動化を超える**メタ認知自動化システム**です。CI/CDパイプラインのような従来のツールが固定された事前定義のステップに従うのに対し、自己進化ループは：

1. 要件分析に基づいてタスク固有のツール（スキル）を**動的に生成**
2. パターンと根本原因を抽出して**失敗から学習**
3. 学習した洞察に基づいて生成されたツールを改善し**戦略を進化**
4. 分離と永続化メカニズムを通じて**コンテキストを効率的に管理**

### 主な差別化要因

| 側面 | 従来の自動化 | 自己進化ループ |
|------|-------------|---------------|
| 戦略 | 固定ステップ | 動的生成 |
| ツール | 事前定義 | タスクごとに生成 |
| 失敗処理 | リトライ/中止 | 学習して進化 |
| メモリ | ステートレス | セッション間学習 |
| 適応性 | なし | 継続的改善 |

### 設計思想

システムは3つのコア原則を体現します：

1. **メタエンジニアリング**：ツールを生成するツールを生成
2. **実践による学習**：実行結果からパターンを抽出
3. **コンテキスト効率**：能力を最大化しながらトークン消費を最小化

---

## 理論的基盤

### 1. メタ認知アーキテクチャ

自己進化ループは、人間の問題解決からインスピレーションを得た**メタ認知アーキテクチャ**を実装しています：

```
┌─────────────────────────────────────────────────────────────────────┐
│                     メタ認知レイヤー                                  │
├─────────────────────────────────────────────────────────────────────┤
│  レイヤー3：メタ学習                                                  │
│  ├── セッション間パターン認識                                         │
│  ├── 戦略最適化                                                       │
│  └── ツール進化決定                                                   │
├─────────────────────────────────────────────────────────────────────┤
│  レイヤー2：計画と制御                                                │
│  ├── フェーズオーケストレーション                                     │
│  ├── 意思決定（SHIP/FIX/EVOLVE/ABORT）                               │
│  └── リソース配分                                                     │
├─────────────────────────────────────────────────────────────────────┤
│  レイヤー1：実行                                                      │
│  ├── TDD実装（Red-Green-Refactor）                                   │
│  ├── コード生成                                                       │
│  └── 検証                                                             │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. 強化学習の原則

進化メカニズムは強化学習の概念に従います：

- **状態**：現在のチェックポイント、生成されたスキル、コードベースの状態
- **行動**：SHIP、FIX、EVOLVE、またはABORTの決定
- **報酬**：検証スコア、受け入れ基準の完了
- **ポリシー**：経験を通じて洗練された決定ルール

```
R(状態, 行動) = w1 * 機能正確性 +
                w2 * コード品質 +
                w3 * テストカバレッジ +
                w4 * セキュリティスコア

ここで：w1=0.4, w2=0.25, w3=0.25, w4=0.1
```

### 3. 遺伝的アルゴリズムのインスピレーション

スキル進化は遺伝的アルゴリズムの原則に従います：

1. **選択**：成功率が最も高いスキルを選択
2. **突然変異**：学習した洞察を適用してスキルを修正
3. **交差**：スキル間で成功パターンを組み合わせ
4. **適応度関数**：検証スコア + 実行効率

### 4. 知識グラフメモリ

メモリシステムは簡略化された知識グラフを実装します：

```
エンティティ：
├── タスク（タイプ分類付き）
├── ツール（エージェント、スキル）
├── パターン（成功/失敗パターン）
└── 結果（実行結果）

関係：
├── タスク HAS_TYPE パターン
├── ツール USED_FOR タスク
├── パターン CORRELATES_WITH 結果
└── ツール CO_OCCURS_WITH ツール
```

---

## アーキテクチャ概要

### システムアーキテクチャ

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         自己進化ループ v2.0                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────┐                                                      │
│  │   ユーザーリクエスト │                                                      │
│  │  "/evolving-loop"  │                                                      │
│  └─────────┬─────────┘                                                      │
│            │                                                                 │
│            ▼                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                オーケストレーター（Forkコンテキスト）                   │    │
│  │  ┌─────────────────────────────────────────────────────────────┐     │    │
│  │  │ プリフェーズ                                                  │     │    │
│  │  │ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │     │    │
│  │  │ │フェーズ -2    │  │フェーズ -1A   │  │フェーズ -1C   │       │     │    │
│  │  │ │コンテキスト   │─▶│パターン検索   │  │進化更新       │       │     │    │
│  │  │ │チェック       │  │（メモリ読取） │  │（SHIP時）     │       │     │    │
│  │  │ └──────────────┘  └──────────────┘  └──────────────┘       │     │    │
│  │  └─────────────────────────────────────────────────────────────┘     │    │
│  │                                                                       │    │
│  │  ┌─────────────────────────────────────────────────────────────┐     │    │
│  │  │ メインループ（各フェーズはforkコンテキストで）                  │     │    │
│  │  │                                                               │     │    │
│  │  │  ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐          │     │    │
│  │  │  │ 分析   │──▶│ 生成   │──▶│ 実行   │──▶│ 検証   │          │     │    │
│  │  │  │Phase 1 │   │Phase 2 │   │Phase 3 │   │Phase 4 │          │     │    │
│  │  │  └────────┘   └────────┘   └────────┘   └───┬────┘          │     │    │
│  │  │       ▲                                     │                │     │    │
│  │  │       │       ┌────────┐   ┌────────┐   ┌──▼─────┐          │     │    │
│  │  │       │       │ 進化   │◀──│ 学習   │◀──│ 決定   │          │     │    │
│  │  │       └───────│Phase 7 │   │Phase 6 │   │Phase 5 │          │     │    │
│  │  │               └────────┘   └────────┘   └────────┘          │     │    │
│  │  │                                              │                │     │    │
│  │  │                                    SHIP ─────┼──▶ Phase 8     │     │    │
│  │  └─────────────────────────────────────────────────────────────┘     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                       永続化レイヤー                                  │    │
│  │  ┌───────────────────┐        ┌───────────────────┐                  │    │
│  │  │ セッション状態     │        │ 永続メモリ         │                  │    │
│  │  │ .self-evolving-   │        │ .claude/memory/    │                  │    │
│  │  │  loop/            │        │  meta-engineering/ │                  │    │
│  │  │ ├── state/        │        │ ├── patterns.json  │                  │    │
│  │  │ ├── reports/      │        │ ├── tool-usage.json│                  │    │
│  │  │ ├── generated-    │        │ ├── evolution.json │                  │    │
│  │  │ │   skills/       │        │ └── feedback.json  │                  │    │
│  │  │ └── history/      │        │                    │                  │    │
│  │  └───────────────────┘        └───────────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### コンテキストフロー

```
メインコンテキスト（ユーザー会話）
     │
     │ 委譲（サマリーのみ返却）
     ▼
オーケストレーターコンテキスト（Fork）
     │
     │ 生成（各使い捨て）
     ├─────────────────────────────────────┐
     ▼                                     ▼
フェーズコンテキスト（Fork）        メモリシステム（永続）
├── 分析 → analysis.json           ├── patterns.json
├── 生成 → skills/*.md             ├── tool-usage.json
├── 実行 → コードベース             ├── evolution.json
├── 検証 → validation.json         └── feedback.json
├── 決定 → decision.json
├── 学習 → learning.json
└── 進化 → 進化したスキル
```

### データフロー

```
リクエスト → 分析 → 分析レポート
                     ↓
             生成 → エグゼキューター、バリデーター、フィクサースキル
                     ↓
             実行 → コード変更 + テスト結果
                     ↓
             検証 → 検証スコア（0-100）
                     ↓
             決定 → 決定：SHIP | FIX | EVOLVE | ABORT
                     ↓
        ┌────────────┼────────────┐
        ↓            ↓            ↓
      SHIP       FIX/EVOLVE    ABORT
   （完了）         ↓          （停止）
                  学習
                   ↓
                  進化
                   ↓
              （ループバック）
```

---

## フェーズ詳細

### プリフェーズ -2：コンテキストチェック

**目的**：コンテキスト圧力を監視し、トークンオーバーフローを防止。

**実装**：
```python
def context_check():
    tool_usage = read_json("patterns.json")

    # アクティブなツールに基づいて圧力を推定
    pressure = len(active_tools) * 0.05

    # アイドル状態のタスクスコープツールを自動アンロード（30分以上アイドル）
    if pressure > 0.8:
        for tool in idle_tools:
            if tool.lifecycle == "task-scoped":
                unload(tool)

    return {"pressure": pressure, "recommendation": "ok" if pressure < 0.8 else "unload"}
```

### プリフェーズ -1A：パターン検索

**目的**：スキル生成をガイドするために履歴パターンをロード。

**実装**：
```python
def pattern_lookup(task_type):
    patterns = read_json("patterns.json")
    evolution = read_json("evolution.json")

    # 学習したパターンから推奨を取得
    recommendations = {
        "agents": patterns[task_type].recommended_agents,
        "skills": patterns[task_type].recommended_skills,
        "predicted_tools": evolution.predicted_tools,
        "template_improvements": evolution.template_improvements
    }

    return recommendations
```

### フェーズ1：分析

**エージェント**：`requirement-analyzer`

**目的**：実行可能な実行計画を作成するためのユーザー要件の深い分析。

**出力**：
```json
{
  "parsed_goal": "ユーザー認証システムの実装",
  "acceptance_criteria": [
    {"id": 1, "description": "ログインエンドポイント", "priority": "P0"},
    {"id": 2, "description": "JWT生成", "priority": "P0"},
    {"id": 3, "description": "トークン検証", "priority": "P1"}
  ],
  "complexity": 7,
  "estimated_iterations": 5,
  "codebase_context": {
    "tech_stack": ["Node.js", "Express"],
    "existing_patterns": ["REST API", "MongoDB"],
    "relevant_files": ["src/routes/", "src/middleware/"]
  },
  "strategy": {
    "approach": "インクリメンタルTDD",
    "order": ["認証ルート", "JWTサービス", "ミドルウェア"],
    "risks": [{"risk": "トークン有効期限", "mitigation": "リフレッシュフローを追加"}]
  }
}
```

### フェーズ2：生成

**エージェント**：`skill-synthesizer`

**目的**：分析に基づいてタスク固有のスキルを生成。

**生成されるスキル**：

1. **エグゼキュータースキル**：TDDステップを含む実装ガイド
2. **バリデータースキル**：品質チェックとスコアリングルーブリック
3. **フィクサースキル**：自動修正ルールとパターン

**スキルライフサイクル**：
```yaml
---
name: executor-v1
description: 認証タスク用の自動生成エグゼキューター
lifecycle: task-scoped  # または persistent
context: fork
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---
```

### フェーズ3：実行

**目的**：TDDメソドロジーに従ってタスクを実装。

**TDDサイクル**：
```
┌─────────────────────────────────────────────┐
│                TDDイテレーション               │
├─────────────────────────────────────────────┤
│  RED    │ 失敗するテストを書く               │
│         │ → assert login()がトークンを返す  │
├─────────┼───────────────────────────────────┤
│  GREEN  │ 最小限の合格コードを書く           │
│         │ → 基本的なlogin()を実装           │
├─────────┼───────────────────────────────────┤
│ REFACTOR│ 動作を変えずに改善                │
│         │ → JWTサービスを抽出               │
└─────────┴───────────────────────────────────┘
```

**ツール使用追跡**：
- どのエージェント/スキルが呼び出されたかを記録
- パターン学習のための依存関係グラフを構築
- 将来の最適化を可能に

### フェーズ4：検証

**目的**：スコアリングルーブリックを使用して実装品質を評価。

**スコアリングルーブリック**：
```
合計スコア =
    機能正確性（40%）
  + コード品質（25%）
  + テストカバレッジ（25%）
  + セキュリティ（10%）

スコア範囲：
  90-100: SHIP（優秀）
  70-89:  FIX（軽微な問題）
  50-69:  EVOLVE（改善が必要）
  <50:    ABORT（根本的な問題）
```

### フェーズ5：決定

**エージェント**：`completion-judge`

**目的**：検証結果に基づいて次のアクションを決定。

**決定ツリー**：
```
IF すべてのAC完了 AND スコア >= 90:
    → SHIP
ELIF スコア >= 70:
    → FIX（フィクサーを適用、リトライ）
ELIF スコア >= 50 AND イテレーション < 最大:
    → EVOLVE（学習、スキルを改善）
ELSE:
    → ABORT
```

### フェーズ6：学習

**エージェント**：`experience-extractor`

**目的**：実行結果からパターンと洞察を抽出。

**学習出力**：
```json
{
  "failure_patterns": [
    {
      "pattern": "エラーハンドリングの欠如",
      "occurrences": 3,
      "root_cause": "エグゼキューターテンプレートにエラーハンドリングセクションがない",
      "suggestion": "エグゼキューターに明示的なエラーハンドリングステップを追加"
    }
  ],
  "tool_dependencies": {
    "test-runner+code-reviewer": {
      "co_usage_count": 5,
      "correlation": "strong"
    }
  },
  "skill_improvements": [
    {
      "skill": "executor",
      "section": "実装ステップ",
      "change": "各AC実装後にエラーハンドリングを追加"
    }
  ]
}
```

### フェーズ7：進化

**エージェント**：`skill-evolver`

**目的**：学習した洞察を適用してスキルを改善。

**進化プロセス**：
1. 改善提案のためにlearning.jsonを読み取り
2. スキルテンプレートに修正を適用
3. 新しいスキルバージョンを生成（v1 → v2）
4. ライフサイクルアップグレード条件をチェック

**ライフサイクルアップグレード**：
```python
# task-scopedからpersistentにアップグレード
if usage_count >= 5 and success_rate >= 0.80:
    skill.lifecycle = "persistent"
    record_upgrade(skill, evolution.json)
```

### ポストフェーズ -1C：進化更新（SHIP時）

**目的**：セッション結果でメモリシステムを更新。

**更新内容**：
1. **patterns.json**：タスクパターン成功率を更新
2. **tool-usage.json**：ツール使用統計を記録
3. **evolution.json**：バージョンをインクリメント、学習を記録

---

## メモリシステム

### メモリアーキテクチャ

```
.claude/memory/meta-engineering/
├── patterns.json       # タスクパターンと推奨
├── tool-usage.json     # ツール使用統計
├── evolution.json      # 進化履歴と予測
└── feedback.json       # ユーザーフィードバック収集
```

### patterns.json構造

```json
{
  "task_patterns": {
    "auth": {
      "keywords": ["ログイン", "認証", "JWT", "OAuth"],
      "recommended_agents": ["security-checker"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.82,
      "sample_count": 12
    },
    "api": {
      "keywords": ["API", "エンドポイント", "REST", "ルート"],
      "recommended_agents": ["code-reviewer"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.78,
      "sample_count": 8
    }
  },
  "tool_dependencies": {
    "test-runner+code-reviewer": {
      "tools": ["test-runner", "code-reviewer"],
      "co_usage_count": 15,
      "first_seen": "2024-01-01T00:00:00Z",
      "last_seen": "2024-01-15T12:00:00Z"
    }
  }
}
```

### tool-usage.json構造

```json
{
  "tools": [
    {
      "name": "test-runner",
      "lifecycle": "persistent",
      "usage_count": 25,
      "success_count": 22,
      "success_rate": 0.88,
      "last_used": "2024-01-15T12:00:00Z"
    }
  ],
  "last_updated": "2024-01-15T12:00:00Z"
}
```

### evolution.json構造

```json
{
  "version": 5,
  "last_evolution": "2024-01-15T12:00:00Z",
  "template_improvements": [
    {
      "template": "executor",
      "improvement": "エラーハンドリングセクションを追加",
      "applied_version": 3
    }
  ],
  "learned_rules": [
    {
      "condition": "task_type == 'auth'",
      "action": "セキュリティ検証ステップを含める",
      "confidence": 0.85
    }
  ],
  "lifecycle_upgrades": [
    {
      "skill": "test-runner",
      "from": "task-scoped",
      "to": "persistent",
      "timestamp": "2024-01-10T00:00:00Z"
    }
  ]
}
```

---

## 安全アーキテクチャ

### 1. 実行前レビューゲート

実行フェーズの前に必須の検証：

```bash
# 実行されるチェック：
1. 分析ファイルが存在し有効なJSONである
2. 生成されたスキルに必要なフロントマターがある
3. 危険なコマンドパターンがない（rm -rf /、sudo、eval）
4. 受け入れ基準の数 > 0
```

### 2. 実行後検証

実行後、実際の作業が行われたことを確認：

```bash
# 検証チェック：
1. テスト出力ファイルが存在しコンテンツがある
2. テスト出力にパス/フェイルインジケータがある
3. Git diffが実際の変更を示す
4. 整合性のために出力ハッシュを記録
```

### 3. チェックポイント検証

フェーズ移行前：

```bash
# 必須フィールドのチェック：
- version
- current_phase
- current_iteration
- status
- max_iterations

# 境界チェック：
- iteration <= max_iterations
```

### 4. ロールバックメカニズム

```
リスクのある操作前：
1. checkpoint.jsonをバックアップ
2. 生成されたスキルをアーカイブ
3. git stashを作成

失敗時：
1. チェックポイントを復元
2. スキルを復元
3. git stashをポップ
```

### 5. レート制限

```
保護：
- サイクル間最低30秒
- 1時間あたり最大20サイクル
- コンテキストサイズガード（チェックポイント制限10KB）
```

---

## コンテキスト管理

### コンテキスト問題

従来のアプローチはコンテキスト膨張を引き起こす：

```
ユーザー → "分析" → 2000トークン返却
ユーザー → "生成" → 3000トークン返却
ユーザー → "実行" → 5000トークン返却
...
合計：15000+トークン → COMPACTトリガー → 情報損失
```

### ソリューション：コンテキスト分離

```
ユーザー → /evolving-loop "タスク"
     → オーケストレーター（fork）がすべてを処理
     → 返却："完了！3イテレーション、8ファイル"

合計：~200トークン → 圧縮不要
```

### コンテキスト予算割り当て

| コンポーネント | トークン予算 | 目的 |
|---------------|-------------|------|
| メインコンテキスト | ~500 | ステータス行のみ |
| オーケストレーター | ~2000 | 調整 |
| 各フェーズ | フル | 分離、使い捨て |
| メモリファイル | 無制限 | ディスクに永続化 |

### 出力トリミングルール

```python
MAX_PHASE_OUTPUT_CHARS = 500
MAX_CONTEXT_ITEMS = 10

# メインコンテキストに返却しない：
- 完全な分析レポート
- 完全なスキルコンテンツ
- 詳細な検証結果
- 生のメモリファイルコンテンツ

# 常に返却：
- 単一行ステータス更新
- 数値とスコアのみ
- 決定結果
```

---

## 実装詳細

### 状態ファイル

```
.self-evolving-loop/
├── state/
│   ├── checkpoint.json      # メイン状態（必須のみ）
│   ├── stop                  # 停止シグナルファイル
│   └── last_cycle.txt        # レート制限
├── reports/
│   ├── context.json          # コンテキストチェック結果
│   ├── patterns.json         # パターン検索結果
│   ├── analysis.json         # 完全な分析
│   ├── validation.json       # 完全な検証
│   ├── decision.json         # 決定詳細
│   ├── learning.json         # 学習洞察
│   ├── pre-execute-review.json
│   └── post-execute-verify.json
├── generated-skills/
│   ├── executor-v1.md
│   ├── validator-v1.md
│   └── fixer-v1.md
├── history/
│   ├── events.jsonl
│   └── skill-evolution.jsonl
├── backups/
│   └── backup-iter-N-TIMESTAMP/
└── templates/
    ├── executor-template.md
    ├── validator-template.md
    └── fixer-template.md
```

### チェックポイントスキーマ

```json
{
  "version": "2.0.0",
  "request": "ユーザー認証の実装",
  "task_type": "auth",
  "pattern_matched": "auth",
  "current_phase": "EXECUTE",
  "current_iteration": 2,
  "max_iterations": 50,
  "status": "in_progress",
  "started_at": "2024-01-15T10:00:00Z",
  "ac_total": 5,
  "ac_completed": 3,
  "skill_versions": {
    "executor": 1,
    "validator": 1,
    "fixer": 1
  },
  "skill_lifecycle": {
    "executor": "task-scoped",
    "validator": "task-scoped",
    "fixer": "task-scoped"
  },
  "last_score": 85,
  "tools_used": ["code-reviewer", "test-runner"],
  "feedback_collected": []
}
```

### イベントログフォーマット

```json
{"timestamp": "2024-01-15T10:00:00Z", "type": "phase_start", "phase": "ANALYZE", "iteration": 1}
{"timestamp": "2024-01-15T10:01:00Z", "type": "phase_complete", "phase": "ANALYZE", "duration": 60}
{"timestamp": "2024-01-15T10:01:05Z", "type": "skill_generated", "skill": "executor", "version": 1}
{"timestamp": "2024-01-15T10:05:00Z", "type": "validation", "score": 72, "ac_complete": 3}
{"timestamp": "2024-01-15T10:05:10Z", "type": "decision", "action": "FIX", "reason": "軽微な問題"}
```

---

## 使用ガイド

### 基本的な使用方法

```bash
# 新しいセッションを開始
/evolving-loop "ユーザー認証の実装

受け入れ基準：
- [ ] メール/パスワードでのログインエンドポイント
- [ ] JWTトークン生成
- [ ] トークン検証ミドルウェア
- [ ] エラーハンドリング
"

# ステータスを確認
/evolving-status

# 中断されたセッションを再開
/evolving-loop --resume

# 強制再起動
/evolving-loop --force "新しいタスク"

# メモリシステムを確認
/evolving-loop --memory

# 手動進化をトリガー
/evolving-loop --evolve
```

### 良い受け入れ基準の書き方

**良い例**：
```markdown
- [ ] GET /usersがid、name、emailフィールドを含むJSON配列を返す
- [ ] 有効なデータでのPOST /usersが201と作成されたユーザーを返す
- [ ] 無効なメールでのPOST /usersが400とエラーメッセージを返す
- [ ] 認証ミドルウェアが有効なJWTなしのリクエストを拒否する
```

**悪い例**：
```markdown
- [ ] APIは速くあるべき（測定不可）
- [ ] エラーを処理する（曖昧すぎる）
- [ ] 動くようにする（具体的でない）
```

### 使用するタイミング

| シナリオ | evolving-loopを使用 | auto-loopを使用 |
|---------|-------------------|----------------|
| 複雑な機能 | はい | いいえ |
| 複数の相互依存する部分 | はい | いいえ |
| 以前の試行が失敗 | はい | いいえ |
| シンプルで明確に定義されたタスク | いいえ | はい |
| 標準TDDで十分 | いいえ | はい |

---

## トラブルシューティング

### 一般的な問題

#### セッションがスタック

```bash
# ステータスを確認
/evolving-status --detailed

# 最近のイベントを確認
tail -20 .self-evolving-loop/history/events.jsonl | jq

# 必要に応じて強制再起動
/evolving-loop --force "タスク"
```

#### スキルが改善しない

```bash
# 進化履歴を確認
cat .self-evolving-loop/history/skill-evolution.jsonl | jq

# 学習レポートを確認
cat .self-evolving-loop/reports/learning.json | jq
```

#### 最大イテレーション到達

```bash
# 達成内容を確認
/evolving-status --detailed

# より高い制限で再開始
/evolving-loop --force "タスク" --max-iterations 100
```

#### 状態ファイルの破損

```bash
# チェックポイントをリセット
cat > .self-evolving-loop/state/checkpoint.json << 'EOF'
{
  "version": "2.0.0",
  "request": null,
  "current_phase": null,
  "current_iteration": 0,
  "max_iterations": 50,
  "status": "idle"
}
EOF
```

### 完全リセット

```bash
# すべての状態を削除
rm -rf .self-evolving-loop/state/*
rm -rf .self-evolving-loop/reports/*
rm -rf .self-evolving-loop/generated-skills/*
rm -rf .self-evolving-loop/history/*

# テンプレートとフックは保持
# ディレクトリを再作成
mkdir -p .self-evolving-loop/{state,reports,generated-skills,history}
```

---

## 学術参考文献

### 関連研究分野

1. **メタ学習**：「学ぶことを学ぶ」- 学習アルゴリズムを改善するシステム
2. **遺伝的プログラミング**：進化を通じた自動プログラム合成
3. **強化学習**：報酬最適化による意思決定
4. **知識グラフ**：ドメイン知識の構造化表現
5. **自律コンピューティング**：自己管理型コンピュータシステム

### 概念的基盤

- **リフレクション**：自身の動作について推論するシステムの能力
- **適応**：環境フィードバックに基づいて動作を修正
- **創発**：単純なルールから生じる複雑な動作
- **恒常性**：自己調整を通じて安定性を維持

### デザインパターンの影響

- **ストラテジーパターン**：動的アルゴリズム選択
- **オブザーバーパターン**：フェーズ完了通知
- **ステートパターン**：フェーズベースの動作変化
- **テンプレートメソッド**：カスタマイズ可能な実行フレームワーク

---

## 結論

自己進化型開発ループは、AI支援開発自動化における重要な進歩を表しています。以下を組み合わせることにより：

- 特定のタスクに合わせた**動的スキル生成**
- 実行結果からの**継続的学習**
- 分離による**効率的なコンテキスト管理**
- 信頼性の高い操作のための**堅牢な安全メカニズム**

システムは、各イテレーションで改善する自律的、適応的、効率的なソフトウェア開発を実現します。

---

## 関連項目

- [DIRECTOR-MODE-CONCEPTS.md](DIRECTOR-MODE-CONCEPTS.md) - コアメソドロジー
- [CLAUDE-TEMPLATE.md](CLAUDE-TEMPLATE.md) - プロジェクト設定
- [FAQ.md](FAQ.md) - よくある質問

---

*ドキュメントバージョン：2.0.0*
*最終更新：2026-01-14*
*[Director Mode Lite](https://github.com/claude-world/director-mode-lite)の一部*
