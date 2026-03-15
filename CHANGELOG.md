# Changelog — Исправления workflow

## Версия 2 (Fixed) — 2026-03-15

### 🐛 Исправленные критические проблемы

#### 1. Доступ к sessionData после Execute Workflow

**Проблема:**
В ноде `Format Success Response` использовался неверный доступ к данным сессии:
```javascript
// ❌ НЕВЕРНО: $input.all()[1] не работает после Execute Workflow
const sessionData = $input.all()[1]?.json ?? {};
```

**Решение:**
Добавлена нода `Store Session Context` (Set node) перед вызовом worker, которая сохраняет `session_id`, `intent`, `user_id` в отдельные переменные. После Execute Workflow данные доступны через `$input.all()[1]`.

**Файлы:**
- `basic/workflow_orchestrator.json` — добавлена нода `orch-store-context`
- `ai-enhanced/workflow_orchestrator_ai.json` — добавлена нода `orch-store-context`

---

#### 2. Обновление статуса сессии в БД

**Проблема:**
Нода `Update Session State` только формировала данные, но не выполняла UPDATE в базе данных. Статус сессии оставался `'processing'` навсегда.

**Решение:**
Добавлена новая нода `Update Session State (DB)` (PostgreSQL) после `Update Session State`, которая выполняет SQL запрос:
```sql
UPDATE session_state SET status = $1, updated_at = NOW() WHERE session_id = $2;
```

**Файлы:**
- `basic/workflow_orchestrator.json` — добавлена нода `orch-update-session-db`
- `ai-enhanced/workflow_orchestrator_ai.json` — добавлена нода `orch-update-session-db`

---

#### 3. Process AI Response — доступ к данным (AI-версия)

**Проблема:**
В ноде `Process AI Response` был неверный доступ к данным от webhook:
```javascript
// ❌ НЕВЕРНО: $input.all()[0] после OpenAI ноды
const message = $input.all()[0]?.json?.message || '';
```

**Решение:**
Исправлен доступ к данным:
```javascript
// ✅ ВЕРНО: используем $input.all()[0] для webhook данных
const openAiResponse = $input.first()?.json ?? {};
const webhookData = $input.all()[0]?.json ?? {};
const message = webhookData.message || '';
```

**Файлы:**
- `ai-enhanced/workflow_orchestrator_ai.json` — исправлена нода `orch-process-ai-response`

---

#### 4. searchParams теряется в worker

**Проблема:**
В ноде `Format Response` (worker) параметры поиска терялись после PostgreSQL ноды:
```javascript
// ❌ НЕВЕРНО: searchParams не доступен
const searchParams = $input.all()[0]?.json ?? {};
```

**Решение:**
Исправлен доступ к параметрам через `$input.all()[0]` (данные до PostgreSQL ноды):
```javascript
// ✅ ВЕРНО: используем previousData для search_params
const dbResults = $input.first()?.json ?? {};
const previousData = $input.all()[0]?.json ?? {};

return {
  search_params: {
    date: previousData.date,
    time: previousData.time,
    guests: previousData.guests,
    location: previousData.location
  },
  ...
};
```

**Файлы:**
- `basic/workflow_search_worker.json` — исправлена нода `worker-format-response`
- `ai-enhanced/workflow_search_worker.json` — исправлена нода `worker-format-response`

---

#### 5. Error Handler без контекста (worker)

**Проблема:**
При ошибке БД в логах не было контекста (какие параметры передавались).

**Решение:**
Добавлен контекст в ответ об ошибке:
```javascript
return {
  status: 'error',
  error_type: 'database_error',
  message: error.message,
  context: {
    date: previousData.date,
    time: previousData.time,
    location: previousData.location
  },
  timestamp: new Date().toISOString()
};
```

**Файлы:**
- `basic/workflow_search_worker.json` — исправлена нода `worker-error-handler`
- `ai-enhanced/workflow_search_worker.json` — исправлена нода `worker-error-handler`

---

### 📋 Изменения в структуре workflow

#### Orchestrator (оба варианта)

**Добавлено:**
1. Нода `Store Session Context` (Set) — сохранение session_id, intent, user_id
2. Нода `Update Session State (DB)` (PostgreSQL) — UPDATE статуса в БД

**Поток данных:**
```
Webhook → Extract → Validate → [if valid] → Save Session → Store Context → Call Worker → Format Success → Update Session → Update Session (DB) → Respond
```

#### Worker

**Изменено:**
1. Нода `Format Response` — исправлен доступ к searchParams
2. Нода `Error Handler` — добавлен контекст в ошибку

---

### 🔧 Технические детали

#### Версии нод

| Нода | Тип | Версия |
|------|-----|--------|
| Webhook Trigger | n8n-nodes-base.webhook | 1.1 |
| Code | n8n-nodes-base.code | 2 |
| Set | n8n-nodes-base.set | 3.3 |
| If | n8n-nodes-base.if | 1 |
| PostgreSQL | n8n-nodes-base.postgres | 2.5 |
| Execute Workflow | n8n-nodes-base.executeWorkflow | 1 |
| Respond to Webhook | n8n-nodes-base.respondToWebhook | 1.1 |
| Error Trigger | n8n-nodes-base.errorTrigger | 1 |
| OpenAI (AI-версия) | @n8n/n8n-nodes-langchain.openAi | 1.3 |

#### Retry политика

| Нода | Max Retries | Interval (ms) |
|------|-------------|---------------|
| Save Session State | 3 | 1000 |
| Call Search Worker | 3 | 2000 |
| Update Session State (DB) | 2 | 1000 |
| Query Options Catalog (worker) | 3 | 1000 |
| Extract Parameters (OpenAI) | 2 | 1000 |

---

### ✅ Тестирование

Проверьте следующие сценарии:

1. **Success:** Все параметры присутствуют → статус сессии обновляется на `'completed'`
2. **Missing Data:** Нет параметров → возвращается `{status: 'missing_data'}`
3. **Error:** Ошибка БД → статус сессии обновляется на `'error'`

**Проверка в БД:**
```sql
-- Проверка обновления статуса
SELECT session_id, status, updated_at 
FROM session_state 
ORDER BY created_at DESC 
LIMIT 10;
```

---

## Версия 1 (Initial) — 2026-03-15

Первоначальная версия с известными проблемами:
- ❌ Не обновлялся статус сессии в БД
- ❌ Терялись session_id и intent в ответе
- ❌ Не было контекста в ошибках worker
- ❌ Неверный доступ к данным в AI-версии
