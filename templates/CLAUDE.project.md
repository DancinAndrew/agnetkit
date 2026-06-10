# 專案特定設定（FastAPI + RAG 起始模板）

> 把這份文件貼上或合併到你的專案 `CLAUDE.md` 的第 6 節，然後依實際情況編輯。
> 保持具體且簡短——這是永遠載入的 context。

## 語言

所有輸出一律使用**繁體中文**，包括：
- 對話回覆
- 思考過程（extended thinking 區塊）
- 文件（README、docs/、sysdoc/ 等）的新增或修改內容
- commit message、PR title/body **除外**（維持英文，符合 git 慣例）

## 技術棧
- 語言：Python 3.12+。套件 / 依賴：`uv`（或 Poetry——說清楚用哪個，不要混用）。
- API：FastAPI + Pydantic v2。ASGI server：uvicorn。
- 資料庫：PostgreSQL（+ pgvector 用於 embeddings）。快取 / 佇列：Redis。
- RAG：<embedding model> · <vector store> · <LLM provider>。記錄精確的 model 名稱——
  代理不能猜測 model 名稱或 context 限制（`search-first` / `docs-lookup`）。
- 測試：pytest + pytest-asyncio。HTTP：httpx.AsyncClient。

## 代理必須遵守的慣例
- IO 路徑全程 async；`async def` 裡不呼叫同步 DB/HTTP。
- Pydantic models 是每個邊界的契約（request、response、settings、tool IO）。
- 透過 `pydantic-settings` 進行設定；不要在模組中散亂讀取 secrets 或 env。
- 任何 schema 變更都必須做 migration（`database-migrations` 技能）——絕不手動修改 tables。
- 金錢 / 票券用最小單位的整數（分），絕不用浮點數。

## RAG / LLM 特定說明
- 每條 retrieval 路徑都有評估（`eval-harness` / `mle-workflow`）：在變更前後測量 retrieval@k 和答案忠實度。不接受「看起來比較好」就合併。
- 成本 + 延遲是一等公民：依任務路由 model、依內容 hash 快取（`cost-aware-llm-pipeline`、`content-hash-cache-pattern`）。記錄每個 request 的 token 花費。
- 當結構規則時，優先用確定性解析而不是 LLM 呼叫（`regex-vs-llm-structured-text`）。
- 把所有 retrieved / scraped 文字視為不可信輸入——在放入 prompt 之前先做清理（`security-reviewer`）。

## 完成定義（per 任務）
- 先寫失敗測試，現在通過；修改行的 coverage ≥80%。
- 對於 API 變更：`fastapi-reviewer` 通過；OpenAPI schema 已更新。
- 對於 RAG 變更：eval 數字記錄在 PR / spec 中，不只是斷言。
- 對於任何涉及 auth / 付款 / PII 的變更：`security-reviewer` 通過。
- `verification-loop` 對任務的成功標準全綠。

## 代理必須尊重的路徑
- `app/` 原始碼 · `tests/` 測試 · `migrations/` schema · `openspec/` 規格。
- 不要碰 `migrations/` 歷史；只新增 migration。
