# 自我進化開發循環

## 技術文件 v2.0

> 一個透過持續學習與適應，動態生成、驗證並進化自身執行策略的元自動化系統。

---

## 目錄

1. [簡介](#簡介)
2. [理論基礎](#理論基礎)
3. [架構概覽](#架構概覽)
4. [階段詳解](#階段詳解)
5. [記憶系統](#記憶系統)
6. [安全架構](#安全架構)
7. [上下文管理](#上下文管理)
8. [實作細節](#實作細節)
9. [使用指南](#使用指南)
10. [疑難排解](#疑難排解)
11. [學術參考](#學術參考)

---

## 簡介

### 什麼是自我進化循環？

自我進化開發循環是一個**元認知自動化系統**，超越傳統開發自動化的範疇。傳統工具如 CI/CD 管道遵循固定、預先定義的步驟，而自我進化循環則：

1. **動態生成**基於需求分析的任務專屬工具（技能）
2. **從失敗中學習**，提取模式與根本原因
3. **進化策略**，根據學習洞察改進生成的工具
4. **高效管理上下文**，透過隔離與持久化機制

### 核心差異

| 面向 | 傳統自動化 | 自我進化循環 |
|------|-----------|-------------|
| 策略 | 固定步驟 | 動態生成 |
| 工具 | 預先定義 | 依任務生成 |
| 失敗處理 | 重試/中止 | 學習並進化 |
| 記憶 | 無狀態 | 跨會話學習 |
| 適應性 | 無 | 持續改進 |

### 設計理念

系統體現三大核心原則：

1. **元工程**：生成工具來生成工具
2. **做中學**：從執行結果中提取模式
3. **上下文效率**：最小化 token 消耗，最大化能力

---

## 理論基礎

### 1. 元認知架構

自我進化循環實作了受人類問題解決啟發的**元認知架構**：

```
┌─────────────────────────────────────────────────────────────────────┐
│                        元認知層次                                    │
├─────────────────────────────────────────────────────────────────────┤
│  第三層：元學習                                                      │
│  ├── 跨會話模式識別                                                  │
│  ├── 策略優化                                                        │
│  └── 工具進化決策                                                    │
├─────────────────────────────────────────────────────────────────────┤
│  第二層：規劃與控制                                                  │
│  ├── 階段編排                                                        │
│  ├── 決策制定（SHIP/FIX/EVOLVE/ABORT）                              │
│  └── 資源分配                                                        │
├─────────────────────────────────────────────────────────────────────┤
│  第一層：執行                                                        │
│  ├── TDD 實作（紅-綠-重構）                                         │
│  ├── 程式碼生成                                                      │
│  └── 驗證                                                            │
└─────────────────────────────────────────────────────────────────────┘
```

### 2. 強化學習原則

進化機制遵循強化學習概念：

- **狀態**：當前檢查點、生成的技能、程式碼庫狀態
- **動作**：SHIP、FIX、EVOLVE 或 ABORT 決策
- **獎勵**：驗證分數、驗收標準完成度
- **策略**：透過經驗精煉的決策規則

```
R(狀態, 動作) = w1 * 功能正確性 +
                w2 * 程式碼品質 +
                w3 * 測試覆蓋率 +
                w4 * 安全分數

其中：w1=0.4, w2=0.25, w3=0.25, w4=0.1
```

### 3. 遺傳演算法啟發

技能進化遵循遺傳演算法原則：

1. **選擇**：選擇成功率最高的技能
2. **突變**：應用學習洞察來修改技能
3. **交叉**：跨技能組合成功模式
4. **適應度函數**：驗證分數 + 執行效率

### 4. 知識圖譜記憶

記憶系統實作了簡化的知識圖譜：

```
實體：
├── 任務（含類型分類）
├── 工具（代理、技能）
├── 模式（成功/失敗模式）
└── 結果（執行結果）

關係：
├── 任務 HAS_TYPE 模式
├── 工具 USED_FOR 任務
├── 模式 CORRELATES_WITH 結果
└── 工具 CO_OCCURS_WITH 工具
```

---

## 架構概覽

### 系統架構

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         自我進化循環 v2.0                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────┐                                                      │
│  │   使用者請求      │                                                      │
│  │  "/evolving-loop" │                                                      │
│  └─────────┬─────────┘                                                      │
│            │                                                                 │
│            ▼                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    編排器（Fork 上下文）                              │    │
│  │  ┌─────────────────────────────────────────────────────────────┐     │    │
│  │  │ 前置階段                                                     │     │    │
│  │  │ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │     │    │
│  │  │ │階段 -2       │  │階段 -1A      │  │階段 -1C      │       │     │    │
│  │  │ │上下文檢查    │─▶│模式查詢      │  │進化更新      │       │     │    │
│  │  │ │（壓力偵測）  │  │（記憶讀取）  │  │（完成時）    │       │     │    │
│  │  │ └──────────────┘  └──────────────┘  └──────────────┘       │     │    │
│  │  └─────────────────────────────────────────────────────────────┘     │    │
│  │                                                                       │    │
│  │  ┌─────────────────────────────────────────────────────────────┐     │    │
│  │  │ 主循環（每階段在 fork 上下文中）                             │     │    │
│  │  │                                                               │     │    │
│  │  │  ┌────────┐   ┌────────┐   ┌────────┐   ┌────────┐          │     │    │
│  │  │  │ 分析   │──▶│ 生成   │──▶│ 執行   │──▶│ 驗證   │          │     │    │
│  │  │  │階段 1  │   │階段 2  │   │階段 3  │   │階段 4  │          │     │    │
│  │  │  └────────┘   └────────┘   └────────┘   └───┬────┘          │     │    │
│  │  │       ▲                                     │                │     │    │
│  │  │       │       ┌────────┐   ┌────────┐   ┌──▼─────┐          │     │    │
│  │  │       │       │ 進化   │◀──│ 學習   │◀──│ 決策   │          │     │    │
│  │  │       └───────│階段 7  │   │階段 6  │   │階段 5  │          │     │    │
│  │  │               └────────┘   └────────┘   └────────┘          │     │    │
│  │  │                                              │                │     │    │
│  │  │                                    SHIP ─────┼──▶ 階段 8      │     │    │
│  │  └─────────────────────────────────────────────────────────────┘     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                       持久化層                                        │    │
│  │  ┌───────────────────┐        ┌───────────────────┐                  │    │
│  │  │ 會話狀態          │        │ 持久記憶          │                  │    │
│  │  │ .self-evolving-   │        │ .claude/memory/   │                  │    │
│  │  │  loop/            │        │  meta-engineering/│                  │    │
│  │  │ ├── state/        │        │ ├── patterns.json │                  │    │
│  │  │ ├── reports/      │        │ ├── tool-usage.json                  │    │
│  │  │ ├── generated-    │        │ ├── evolution.json│                  │    │
│  │  │ │   skills/       │        │ └── feedback.json │                  │    │
│  │  │ └── history/      │        │                   │                  │    │
│  │  └───────────────────┘        └───────────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 上下文流程

```
主上下文（使用者對話）
     │
     │ 委派（只返回摘要）
     ▼
編排器上下文（Fork）
     │
     │ 產生（每個可拋棄）
     ├─────────────────────────────────────┐
     ▼                                     ▼
階段上下文（Fork）               記憶系統（持久）
├── 分析 → analysis.json         ├── patterns.json
├── 生成 → skills/*.md           ├── tool-usage.json
├── 執行 → 程式碼庫               ├── evolution.json
├── 驗證 → validation.json       └── feedback.json
├── 決策 → decision.json
├── 學習 → learning.json
└── 進化 → 進化後的技能
```

### 資料流程

```
請求 → 分析 → 分析報告
                  ↓
          生成 → 執行器、驗證器、修復器技能
                  ↓
          執行 → 程式碼變更 + 測試結果
                  ↓
          驗證 → 驗證分數（0-100）
                  ↓
          決策 → 決策：SHIP | FIX | EVOLVE | ABORT
                  ↓
     ┌────────────┼────────────┐
     ↓            ↓            ↓
   SHIP       FIX/EVOLVE    ABORT
（完成）         ↓          （停止）
               學習
                 ↓
               進化
                 ↓
            （返回循環）
```

---

## 階段詳解

### 前置階段 -2：上下文檢查

**目的**：監控上下文壓力並防止 token 溢出。

**實作**：
```python
def context_check():
    tool_usage = read_json("patterns.json")

    # 基於活動工具估算壓力
    pressure = len(active_tools) * 0.05

    # 自動卸載閒置的任務範圍工具（閒置 > 30 分鐘）
    if pressure > 0.8:
        for tool in idle_tools:
            if tool.lifecycle == "task-scoped":
                unload(tool)

    return {"pressure": pressure, "recommendation": "ok" if pressure < 0.8 else "unload"}
```

### 前置階段 -1A：模式查詢

**目的**：載入歷史模式以指導技能生成。

**實作**：
```python
def pattern_lookup(task_type):
    patterns = read_json("patterns.json")
    evolution = read_json("evolution.json")

    # 從學習的模式中獲取建議
    recommendations = {
        "agents": patterns[task_type].recommended_agents,
        "skills": patterns[task_type].recommended_skills,
        "predicted_tools": evolution.predicted_tools,
        "template_improvements": evolution.template_improvements
    }

    return recommendations
```

### 階段 1：分析

**代理**：`requirement-analyzer`

**目的**：深入分析使用者需求以產生可執行的執行計畫。

**輸出**：
```json
{
  "parsed_goal": "實作使用者認證系統",
  "acceptance_criteria": [
    {"id": 1, "description": "登入端點", "priority": "P0"},
    {"id": 2, "description": "JWT 生成", "priority": "P0"},
    {"id": 3, "description": "Token 驗證", "priority": "P1"}
  ],
  "complexity": 7,
  "estimated_iterations": 5,
  "codebase_context": {
    "tech_stack": ["Node.js", "Express"],
    "existing_patterns": ["REST API", "MongoDB"],
    "relevant_files": ["src/routes/", "src/middleware/"]
  },
  "strategy": {
    "approach": "漸進式 TDD",
    "order": ["認證路由", "JWT 服務", "中間件"],
    "risks": [{"risk": "Token 過期", "mitigation": "新增刷新流程"}]
  }
}
```

### 階段 2：生成

**代理**：`skill-synthesizer`

**目的**：基於分析生成任務專屬技能。

**生成的技能**：

1. **執行器技能**：含 TDD 步驟的實作指南
2. **驗證器技能**：品質檢查與評分標準
3. **修復器技能**：自動更正規則與模式

**技能生命週期**：
```yaml
---
name: executor-v1
description: 為認證任務自動生成的執行器
lifecycle: task-scoped  # 或 persistent
context: fork
allowed-tools: [Read, Write, Edit, Bash, Grep, Glob]
---
```

### 階段 3：執行

**目的**：按照 TDD 方法論實作任務。

**TDD 循環**：
```
┌─────────────────────────────────────────────┐
│                TDD 迭代                      │
├─────────────────────────────────────────────┤
│  紅燈   │ 撰寫失敗測試                      │
│         │ → assert login() 返回 token       │
├─────────┼───────────────────────────────────┤
│  綠燈   │ 撰寫最小通過程式碼                │
│         │ → 實作基本 login()                │
├─────────┼───────────────────────────────────┤
│ 重構    │ 不改變行為下改進                  │
│         │ → 提取 JWT 服務                   │
└─────────┴───────────────────────────────────┘
```

**工具使用追蹤**：
- 記錄哪些代理/技能被調用
- 建立依賴圖以供模式學習
- 啟用未來優化

### 階段 4：驗證

**目的**：使用評分標準評估實作品質。

**評分標準**：
```
總分 =
    功能正確性（40%）
  + 程式碼品質（25%）
  + 測試覆蓋率（25%）
  + 安全性（10%）

分數範圍：
  90-100: SHIP（優秀）
  70-89:  FIX（小問題）
  50-69:  EVOLVE（需改進）
  <50:    ABORT（根本問題）
```

### 階段 5：決策

**代理**：`completion-judge`

**目的**：根據驗證結果決定下一步動作。

**決策樹**：
```
IF 所有 AC 完成 AND 分數 >= 90:
    → SHIP
ELIF 分數 >= 70:
    → FIX（應用修復器，重試）
ELIF 分數 >= 50 AND 迭代次數 < 最大值:
    → EVOLVE（學習，改進技能）
ELSE:
    → ABORT
```

### 階段 6：學習

**代理**：`experience-extractor`

**目的**：從執行結果中提取模式與洞察。

**學習輸出**：
```json
{
  "failure_patterns": [
    {
      "pattern": "缺少錯誤處理",
      "occurrences": 3,
      "root_cause": "執行器模板缺少錯誤處理區段",
      "suggestion": "在執行器中新增明確的錯誤處理步驟"
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
      "section": "實作步驟",
      "change": "在每個 AC 實作後新增錯誤處理"
    }
  ]
}
```

### 階段 7：進化

**代理**：`skill-evolver`

**目的**：應用學習洞察來改進技能。

**進化流程**：
1. 讀取 learning.json 以獲取改進建議
2. 對技能模板應用修改
3. 生成新版本技能（v1 → v2）
4. 檢查生命週期升級條件

**生命週期升級**：
```python
# 從 task-scoped 升級到 persistent
if usage_count >= 5 and success_rate >= 0.80:
    skill.lifecycle = "persistent"
    record_upgrade(skill, evolution.json)
```

### 後置階段 -1C：進化更新（SHIP 時）

**目的**：以會話結果更新記憶系統。

**更新內容**：
1. **patterns.json**：更新任務模式成功率
2. **tool-usage.json**：記錄工具使用統計
3. **evolution.json**：遞增版本，記錄學習成果

---

## 記憶系統

### 記憶架構

```
.claude/memory/meta-engineering/
├── patterns.json       # 任務模式與建議
├── tool-usage.json     # 工具使用統計
├── evolution.json      # 進化歷史與預測
└── feedback.json       # 使用者回饋收集
```

### patterns.json 結構

```json
{
  "task_patterns": {
    "auth": {
      "keywords": ["登入", "認證", "JWT", "OAuth"],
      "recommended_agents": ["security-checker"],
      "recommended_skills": ["test-runner"],
      "success_rate": 0.82,
      "sample_count": 12
    },
    "api": {
      "keywords": ["API", "端點", "REST", "路由"],
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

### tool-usage.json 結構

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

### evolution.json 結構

```json
{
  "version": 5,
  "last_evolution": "2024-01-15T12:00:00Z",
  "template_improvements": [
    {
      "template": "executor",
      "improvement": "新增錯誤處理區段",
      "applied_version": 3
    }
  ],
  "learned_rules": [
    {
      "condition": "task_type == 'auth'",
      "action": "包含安全驗證步驟",
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

## 安全架構

### 1. 執行前審查閘門

在任何執行階段之前，強制驗證：

```bash
# 執行的檢查：
1. 分析檔案存在且為有效 JSON
2. 生成的技能具有必要的前置資料
3. 無危險指令模式（rm -rf /、sudo、eval）
4. 驗收標準數量 > 0
```

### 2. 執行後驗證

執行後，驗證實際工作已完成：

```bash
# 驗證檢查：
1. 測試輸出檔案存在且有內容
2. 測試輸出包含通過/失敗指標
3. Git diff 顯示實際變更
4. 記錄輸出雜湊以確保完整性
```

### 3. 檢查點驗證

階段轉換前：

```bash
# 檢查必要欄位：
- version
- current_phase
- current_iteration
- status
- max_iterations

# 邊界檢查：
- iteration <= max_iterations
```

### 4. 回滾機制

```
風險操作前：
1. 備份 checkpoint.json
2. 封存生成的技能
3. 建立 git stash

失敗時：
1. 還原檢查點
2. 還原技能
3. Pop git stash
```

### 5. 速率限制

```
保護措施：
- 循環間最少 30 秒
- 每小時最多 20 個循環
- 上下文大小保護（檢查點限制 10KB）
```

---

## 上下文管理

### 上下文問題

傳統方法導致上下文膨脹：

```
使用者 → "分析" → 返回 2000 tokens
使用者 → "生成" → 返回 3000 tokens
使用者 → "執行" → 返回 5000 tokens
...
總計：15000+ tokens → 觸發 COMPACT → 資訊遺失
```

### 解決方案：上下文隔離

```
使用者 → /evolving-loop "任務"
     → 編排器（fork）處理一切
     → 返回："完成！3 次迭代，8 個檔案"

總計：~200 tokens → 無需壓縮
```

### 上下文預算分配

| 元件 | Token 預算 | 用途 |
|------|-----------|------|
| 主上下文 | ~500 | 僅狀態行 |
| 編排器 | ~2000 | 協調 |
| 每個階段 | 完整 | 隔離、可拋棄 |
| 記憶檔案 | 無限 | 持久化到磁碟 |

### 輸出修剪規則

```python
MAX_PHASE_OUTPUT_CHARS = 500
MAX_CONTEXT_ITEMS = 10

# 絕不返回到主上下文：
- 完整分析報告
- 完整技能內容
- 詳細驗證結果
- 原始記憶檔案內容

# 總是返回：
- 單行狀態更新
- 僅數字與分數
- 決策結果
```

---

## 實作細節

### 狀態檔案

```
.self-evolving-loop/
├── state/
│   ├── checkpoint.json      # 主狀態（僅必要內容）
│   ├── stop                  # 停止信號檔案
│   └── last_cycle.txt        # 速率限制
├── reports/
│   ├── context.json          # 上下文檢查結果
│   ├── patterns.json         # 模式查詢結果
│   ├── analysis.json         # 完整分析
│   ├── validation.json       # 完整驗證
│   ├── decision.json         # 決策詳情
│   ├── learning.json         # 學習洞察
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

### 檢查點結構

```json
{
  "version": "2.0.0",
  "request": "實作使用者認證",
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

### 事件日誌格式

```json
{"timestamp": "2024-01-15T10:00:00Z", "type": "phase_start", "phase": "ANALYZE", "iteration": 1}
{"timestamp": "2024-01-15T10:01:00Z", "type": "phase_complete", "phase": "ANALYZE", "duration": 60}
{"timestamp": "2024-01-15T10:01:05Z", "type": "skill_generated", "skill": "executor", "version": 1}
{"timestamp": "2024-01-15T10:05:00Z", "type": "validation", "score": 72, "ac_complete": 3}
{"timestamp": "2024-01-15T10:05:10Z", "type": "decision", "action": "FIX", "reason": "小問題"}
```

---

## 使用指南

### 基本使用

```bash
# 開始新會話
/evolving-loop "實作使用者認證

驗收標準：
- [ ] 使用 email/password 的登入端點
- [ ] JWT token 生成
- [ ] Token 驗證中間件
- [ ] 錯誤處理
"

# 檢查狀態
/evolving-status

# 恢復中斷的會話
/evolving-loop --resume

# 強制重啟
/evolving-loop --force "新任務"

# 檢查記憶系統
/evolving-loop --memory

# 觸發手動進化
/evolving-loop --evolve
```

### 撰寫良好的驗收標準

**好的範例**：
```markdown
- [ ] GET /users 返回包含 id、name、email 欄位的 JSON 陣列
- [ ] POST /users 使用有效資料返回 201 和建立的使用者
- [ ] POST /users 使用無效 email 返回 400 和錯誤訊息
- [ ] 認證中間件拒絕沒有有效 JWT 的請求
```

**不好的範例**：
```markdown
- [ ] API 應該要快（無法衡量）
- [ ] 處理錯誤（太模糊）
- [ ] 讓它能用（不夠具體）
```

### 何時使用

| 情境 | 使用 evolving-loop | 使用 auto-loop |
|------|-------------------|----------------|
| 複雜功能 | 是 | 否 |
| 多個相互依賴的部分 | 是 | 否 |
| 先前嘗試失敗 | 是 | 否 |
| 簡單、定義明確的任務 | 否 | 是 |
| 標準 TDD 足夠 | 否 | 是 |

---

## 疑難排解

### 常見問題

#### 會話卡住

```bash
# 檢查狀態
/evolving-status --detailed

# 查看最近事件
tail -20 .self-evolving-loop/history/events.jsonl | jq

# 如需要則強制重啟
/evolving-loop --force "任務"
```

#### 技能沒有改進

```bash
# 檢查進化歷史
cat .self-evolving-loop/history/skill-evolution.jsonl | jq

# 查看學習報告
cat .self-evolving-loop/reports/learning.json | jq
```

#### 達到最大迭代次數

```bash
# 查看完成的內容
/evolving-status --detailed

# 以更高限制重新開始
/evolving-loop --force "任務" --max-iterations 100
```

#### 狀態檔案損壞

```bash
# 重設檢查點
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

### 完整重設

```bash
# 移除所有狀態
rm -rf .self-evolving-loop/state/*
rm -rf .self-evolving-loop/reports/*
rm -rf .self-evolving-loop/generated-skills/*
rm -rf .self-evolving-loop/history/*

# 保留模板和 hooks
# 重新建立目錄
mkdir -p .self-evolving-loop/{state,reports,generated-skills,history}
```

---

## 學術參考

### 相關研究領域

1. **元學習**：「學會學習」- 改進學習演算法的系統
2. **遺傳程式設計**：透過進化自動合成程式
3. **強化學習**：透過獎勵優化進行決策
4. **知識圖譜**：領域知識的結構化表示
5. **自主運算**：自我管理的電腦系統

### 概念基礎

- **反思**：系統推理自身行為的能力
- **適應**：根據環境回饋修改行為
- **湧現**：複雜行為從簡單規則中產生
- **恆定性**：透過自我調節維持穩定

### 設計模式影響

- **策略模式**：動態演算法選擇
- **觀察者模式**：階段完成通知
- **狀態模式**：基於階段的行為變化
- **模板方法**：可自訂的執行框架

---

## 結論

自我進化開發循環代表了 AI 輔助開發自動化的重大進展。透過結合：

- **動態技能生成**針對特定任務量身定制
- **持續學習**從執行結果中提取經驗
- **高效上下文管理**透過隔離機制
- **穩健的安全機制**確保可靠運作

系統實現了自主、適應性強且高效的軟體開發，每次迭代都在改進。

---

## 另請參閱

- [DIRECTOR-MODE-CONCEPTS.md](DIRECTOR-MODE-CONCEPTS.md) - 核心方法論
- [CLAUDE-TEMPLATE.md](CLAUDE-TEMPLATE.md) - 專案配置
- [FAQ.md](FAQ.md) - 常見問題

---

*文件版本：2.0.0*
*最後更新：2026-01-14*
*屬於 [Director Mode Lite](https://github.com/claude-world/director-mode-lite)*
