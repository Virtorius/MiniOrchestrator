# Архитектурные решения

## 1. Разделение ответственности между workflow

### Orchestrator (`orchestrator_test`)
**Ответственность:**
- Приём входящего запроса (Webhook)
- Извлечение параметров из естественного языка (NLP)
- Валидация входных данных
- Сохранение состояния сессии в БД
- Координация вызова worker
- Формирование финального ответа клиенту

**Почему так:**
Orchestrator выступает как "фасад" системы — скрывает внутреннюю сложность от клиента, управляет потоком выполнения, обрабатывает ошибки на высоком уровне.

### Worker (`search_worker_test`)
**Ответственность:**
- Приём параметров от orchestrator
- Выполнение поиска в каталоге
- Возврат результатов в стандартизированном формате

**Почему так:**
Worker — это "рабочая лошадка", выполняющая одну конкретную задачу. Такая изоляция позволяет:
- Переиспользовать worker в других сценариях
- Тестировать worker независимо
- Масштабировать horizontally (несколько инстансов для нагрузки)

---

## 2. Организация Session State

### Структура хранения
```
session_state (PostgreSQL)
├── id              — первичный ключ
├── user_id         — идентификатор пользователя
├── session_id      — уникальный ID сессии (sess_XXX)
├── intent          — намерение (search_options)
├── data            — JSONB со всеми данными сессии
├── status          — статус (pending/processing/completed/error)
├── created_at      — время создания
└── updated_at      — время обновления
```

### Почему PostgreSQL, а не in-memory/Redis:
| Критерий | PostgreSQL | Redis | Решение |
|----------|------------|-------|---------|
| Персистентность | ✅ Да | ❌ Нет (по умолчанию) | PostgreSQL |
| Аудит/история | ✅ Да | ⚠️ Ограничено | PostgreSQL |
| Сложные запросы | ✅ Да | ⚠️ Ограничено | PostgreSQL |
| Скорость | ⚠️ Средняя | ✅ Высокая | Достаточно для MVP |
| Интеграция с n8n | ✅ Native node | ⚠️ Требуется HTTP | PostgreSQL |

### Lifecycle сессии:
```
1. POST /webhook/search-request
           ↓
2. Extract Parameters → session_id = sess_XXX
           ↓
3. INSERT INTO session_state (status='pending')
           ↓
4. Validate → если OK: UPDATE status='processing'
           ↓
5. Call Worker → UPDATE status='completed' | 'error'
```

---

## 3. Error Handling Strategy

### Уровни обработки ошибок

**Уровень 1: Retry на нодах с внешними зависимостями**
```
Query Options Catalog (PostgreSQL)
├── Max Retries: 3
├── Retry Interval: 1000ms
└── Причина: временные блокировки БД, таймауты

Call Search Worker (Execute Workflow)
├── Max Retries: 3
├── Retry Interval: 2000ms
└── Причина: worker может быть временно недоступен
```

**Уровень 2: Error Trigger в каждом workflow**
```
Error Trigger (onError: continueErrorOutput)
    ↓
Error Handler (Code Node)
    ↓
Форматирование ошибки в едином контракте
```

**Уровень 3: Глобальная обработка в orchestrator**
- Перехват ошибок от worker
- Логирование в session_state
- Возврат клиенту в формате `{status: 'error', ...}`

### Типы ошибок и обработка

| Тип ошибки | Где обрабатывается | Результат |
|------------|-------------------|-----------|
| Missing data | Validate Data node | `{status: 'missing_data'}` |
| DB connection error | Worker Error Trigger | `{status: 'error', error_type: 'database_error'}` |
| Worker timeout | Orchestrator Retry → Error Handler | `{status: 'error', error_type: 'orchestrator_error'}` |
| Invalid JSON | Parse Input (throw) | `{status: 'error', message: '...'}` |

---

## 4. JSON Contracts Design

### Принципы проектирования контрактов

1. **Единый формат ответа**
   - Всегда присутствует `status` (success/missing_data/error)
   - Всегда присутствует `timestamp`
   - Всегда присутствует `session_id` (кроме случаев полной неудачи)

2. **Явная структура**
   ```typescript
   // Хорошо — явные поля
   {status, intent, session_id, results, message}
   
   // Плохо — неявные вложенности
   {data: {response: {body: {...}}}}
   ```

3. **Самодокументируемость**
   - Понятные имена полей (`results_count`, не `count`)
   - Последовательная нотация (snake_case для JSON)

### Контракт между workflow

```
Orchestrator → Worker:
{
  date: string (YYYY-MM-DD),
  time: string (HH:MM),
  guests: number,
  location: string
}

Worker → Orchestrator:
{
  status: 'success' | 'error',
  search_params: {...},
  results_count: number,
  results: [...],
  message: string (для error),
  timestamp: ISO8601
}
```

**Почему так:**
- Минимальная достаточность — только нужные поля
- Расширяемость — можно добавить поля без breaking changes
- Валидируемость — легко проверить наличие обязательных полей

---

## 5. Naming Convention

### Workflow
- `orchestrator_test` — главный workflow координатор
- `search_worker_test` — worker для поиска вариантов

### Таблицы
- `session_state` — состояние сессий
- `options_catalog` — каталог вариантов

### Ноды (паттерн)
```
<orch|worker>-<action>-<target>

Примеры:
- orch-webhook
- orch-extract-params
- orch-validate
- orch-save-session
- orch-call-worker
- worker-trigger
- worker-parse-input
- worker-db-query
```

**Почему так:**
- Префикс указывает на принадлежность к workflow
- Легко искать в большом проекте
- Понятно из контекста что делает нода

---

## 6. Масштабируемость архитектуры

### Горизонтальное масштабирование workers

```
                    ┌──────────────┐
                    │  Orchestrator│
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           ↓               ↓               ↓
    ┌────────────┐ ┌────────────┐ ┌────────────┐
    │   Search   │ │  Booking   │ │ Notification│
    │   Worker   │ │   Worker   │ │    Worker   │
    └────────────┘ └────────────┘ └────────────┘
```

### Добавление нового intent

1. Создать новый worker workflow (`booking_worker_test`)
2. В orchestrator добавить роутинг по intent:
   ```
   Switch Node:
   ├── search_options → search_worker_test
   ├── booking_request → booking_worker_test
   └── cancel_request → cancel_worker_test
   ```

### Переход на реальную AI-ноду

Заменить Code Node `Extract Parameters (NLP)` на:
- **OpenAI Node** — для извлечения сущностей через GPT
- **LangChain Node** — для сложных цепочек рассуждений

**Преимущество текущей архитектуры:**
- NLP изолирован в одной ноде
- Контракт на выходе не изменится
- Worker'ы не требуют модификации

---

## 7. Logging и Observability

### Что логируется в session_state

| Событие | Что записывается |
|---------|------------------|
| Начало обработки | `status='pending'`, raw input |
| После извлечения | `intent`, `extracted_data` |
| Перед вызовом worker | `status='processing'` |
| После worker | `status='completed'`, результаты |
| При ошибке | `status='error'`, сообщение ошибки |

### Отладка

1. **Execution Log в n8n** — пошаговое выполнение workflow
2. **session_state таблица** — история всех сессий
3. **Error Trigger** — перехват и логирование ошибок

---

## 8. Решения для n8n v2.4.8

### Совместимость

| Нода | Версия | Примечание |
|------|--------|------------|
| Webhook | 1.1 | Стандартная |
| Code | 2 | Поддержка JS |
| PostgreSQL | 2.5 | Поддержка query replacement |
| Execute Workflow | 1 | Вызов подпроцессов |
| Error Trigger | 1 | Глобальная обработка |
| Respond to Webhook | 1.1 | Возврат ответа |

### Особенности v2.4.8

- ✅ Поддержка `retry` на нодах
- ✅ Поддержка `onError: continueErrorOutput`
- ✅ Поддержка `Execute Workflow` с передачей параметров
- ✅ Поддержка JSONB в PostgreSQL

---

## Итог

**Ключевые принципы:**
1. **Separation of Concerns** — разделение orchestration и worker
2. **Single Responsibility** — каждая нода делает одну вещь
3. **Explicit Contracts** — ясные JSON контракты между компонентами
4. **Fail Fast** — ранняя валидация, явная обработка ошибок
5. **Auditability** — полное логирование в БД
6. **Scalability** — архитектура готова к добавлению новых workers
