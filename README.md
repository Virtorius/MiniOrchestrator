# n8n Mini Orchestrator + Worker

[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![n8n Version](https://img.shields.io/badge/n8n-2.4.8-ff6d6a.svg)](https://n8n.io)
[![PostgreSQL](https://img.shields.io/badge/database-PostgreSQL-336791.svg)](https://www.postgresql.org/)
[![Tests](https://img.shields.io/badge/tests-3%20cases-green.svg)](tests/README_tests.md)

> **Модульная система для обработки поисковых запросов на базе n8n v2.4.8**  
> Разделение на orchestration и worker логику, AI-извлечение параметров, session state в PostgreSQL

---

## 🚀 Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone https://github.com/YOUR_USERNAME/n8n-mini-orchestrator.git
cd n8n-mini-orchestrator

# 2. Выполнить SQL схему
psql -U postgres -d n8n_automation -f schema.sql

# 3. Настроить переменные окружения
cp .env.example .env
# Отредактировать .env

# 4. Импортировать workflow в n8n
# basic/workflow_orchestrator.json + basic/workflow_search_worker.json
# или AI-версию из ai-enhanced/

# 5. Запустить тесты
cd tests && ./run_all_tests.sh
```

---

## 📋 Содержание

- [Обзор](#обзор)
- [Версии](#версии)
- [Архитектура](#архитектура)
- [Требования](#требования)
- [Установка](#установка)
- [Запуск](#запуск)
- [Тестирование](#тестирование)
- [Контракты](#контракты)
- [Архитектурные решения](#архитектурные-решения)
- [Вклад в проект](#вклад-в-проект)

---

## Обзор

Система состоит из двух отдельных workflow:

| Workflow | Назначение |
|----------|------------|
| `orchestrator_test` | Приём запроса, извлечение параметров, валидация, сохранение сессии, вызов worker |
| `search_worker_test` | Поиск вариантов в каталоге по заданным параметрам |

### Предметная область
Поиск подходящих вариантов (рестораны, места) по параметрам: дата, время, количество гостей, локация.

---

## Версии

Проект включает **две версии** реализации orchestrator workflow:

| Версия | Workflow | Извлечение параметров | Требования | Точность |
|--------|----------|----------------------|------------|----------|
| **Basic** | `basic/workflow_orchestrator.json` | Регулярные выражения (эвристика) | Только PostgreSQL | ~70% |
| **AI-Enhanced** | `ai-enhanced/workflow_orchestrator_ai.json` | OpenAI GPT-4o-mini | PostgreSQL + OpenAI API | ~95% |

### Сравнение версий

| Критерий | Basic | AI-Enhanced |
|----------|-------|-------------|
| **Понимание контекста** | ❌ Только явные упоминания | ✅ Понимает контекст |
| **Форматы дат** | ❌ Только "завтра", "сегодня", DD.MM.YYYY | ✅ Любые формулировки |
| **Мультиязычность** | ❌ Только русский | ✅ Любой язык |
| **Сложные запросы** | ❌ Не поддерживает | ✅ "через 2 дня", "в следующую пятницу" |
| **Зависимости** | ✅ Минимальные | ⚠️ Требуется OpenAI API ключ |
| **Стоимость** | ✅ Бесплатно | ⚠️ ~$0.01 за запрос |

### Когда использовать каждую версию

**Basic:**
- Демонстрация архитектуры без внешних зависимостей
- Тестирование на локальном окружении
- Ограниченный бюджет

**AI-Enhanced:**
- Production-среда
- Разнообразные формулировки пользователей
- Мультиязычная аудитория
- Готовность платить за удобство

### Быстрый старт

```bash
# Basic версия (без внешних API)
Импортировать: basic/workflow_orchestrator.json
Импортировать: basic/workflow_search_worker.json

# AI-версия (требуется OpenAI API ключ)
1. Установить OPENAI_API_KEY в .env
2. Импортировать: ai-enhanced/workflow_orchestrator_ai.json
3. Импортировать: ai-enhanced/workflow_search_worker.json
4. Настроить OpenAI credential в n8n
```

---

## Архитектура

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Client        │────▶│  Orchestrator    │────▶│  Search Worker  │
│   (Webhook)     │     │  Workflow        │     │  Workflow       │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │                        │
                               ▼                        ▼
                        ┌──────────────────┐     ┌─────────────────┐
                        │  PostgreSQL      │     │  options_catalog│
                        │  - session_state │     │  (mock data)    │
                        └──────────────────┘     └─────────────────┘
```

---

## Требования

### Обязательные
- n8n версии **2.4.8**
- PostgreSQL или Supabase
- Node.js 18+ (для локальной разработки)

### Переменные окружения

| Переменная | Описание | Пример |
|------------|----------|--------|
| `POSTGRES_HOST` | Хост БД | `db.example.com` |
| `POSTGRES_PORT` | Порт БД | `5432` |
| `POSTGRES_USER` | Пользователь БД | `postgres` |
| `POSTGRES_PASSWORD` | Пароль БД | `your_password` |
| `POSTGRES_DB` | Имя базы данных | `n8n_automation` |
| `N8N_BASE_URL` | URL n8n инстанса | `https://n8n.example.com` |

---

## Установка

### Шаг 1: Настройка базы данных

```bash
# Выполнить SQL схему
psql -h <host> -U <user> -d <database> -f schema.sql
```

Или через Supabase SQL Editor:
1. Открыть Supabase Dashboard
2. Перейти в SQL Editor
3. Вставить содержимое `schema.sql`
4. Выполнить

### Шаг 2: Настройка credentials в n8n

#### PostgreSQL credentials (для обеих версий)

1. Открыть n8n → Credentials
2. Создать новый credential типа **PostgreSQL**
3. Заполнить параметры подключения:
   - Host: ваш хост
   - Port: 5432
   - Database: имя БД
   - User: пользователь
   - Password: пароль

#### OpenAI credentials (только для AI-версии)

1. Открыть n8n → Credentials
2. Создать новый credential типа **OpenAI API**
3. Вставить API ключ из `.env` (`OPENAI_API_KEY`)
4. Name: `OpenAI API` (важно для работы workflow)

### Шаг 3: Импорт workflow

#### Basic версия

1. Открыть n8n → Workflows
2. Нажать **Import from File**
3. Импортировать `basic/workflow_orchestrator.json`
4. Импортировать `basic/workflow_search_worker.json`
5. В ноде **Call Search Worker** убедиться, что указан правильный `workflowId`

#### AI-Enhanced версия

1. Открыть n8n → Workflows
2. Нажать **Import from File**
3. Импортировать `ai-enhanced/workflow_orchestrator_ai.json`
4. Импортировать `ai-enhanced/workflow_search_worker.json`
5. Проверить, что в ноде **Extract Parameters (OpenAI)** выбран правильный credential

### Шаг 4: Активация

1. Открыть нужный workflow orchestrator
2. Переключить в **Active** режим
3. Открыть `search_worker_test`
4. Переключить в **Active** режим

---

## Запуск

### Webhook endpoints

| Версия | Endpoint | Метод |
|--------|----------|-------|
| **Basic** | `POST /webhook/search-request` | JSON |
| **AI-Enhanced** | `POST /webhook/search-request-ai` | JSON |

### Пример запроса

```json
{
  "user_id": "10001",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}
```

### Примеры для тестирования

**Basic версия:**
```bash
curl -X POST http://localhost:5678/webhook/search-request \
  -H "Content-Type: application/json" \
  -d '{"user_id": "10001", "message": "Найди варианты на завтра в 19:00 на двоих в центре"}'
```

**AI-Enhanced версия:**
```bash
curl -X POST http://localhost:5678/webhook/search-request-ai \
  -H "Content-Type: application/json" \
  -d '{"user_id": "10001", "message": "Хочу поужинать завтра вечером с девушкой, есть что-нибудь романтичное?"}'
```

---

## Тестирование

### Автоматические тесты

Проект включает скрипты для автоматического тестирования workflow.

**Запуск всех тестов:**
```bash
cd tests
./run_all_tests.sh
```

**Запуск отдельного теста:**
```bash
# Тест #1: Success
./01_test_success.sh

# Тест #2: Missing Data
./02_test_missing_data.sh

# Тест #3: Error (требует эмуляции ошибки БД)
./03_test_error.sh
```

**Требования:**
- curl установлен
- Python 3 для валидации JSON
- n8n запущен и доступен
- PostgreSQL подключен

📄 **Подробная документация:** [tests/README_tests.md](tests/README_tests.md)

---

### Тест-кейс 1: Success (успешный поиск)

**Входные данные:**
```json
{
  "user_id": "10001",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}
```

**Ожидаемый ответ:**
```json
{
  "status": "success",
  "intent": "search_options",
  "session_id": "sess_1234567890_abc123",
  "results": [
    {
      "id": 1,
      "name": "Ресторан \"Центральный\"",
      "area": "Center",
      "capacity": 10,
      "rating": 4.8
    },
    {
      "id": 4,
      "name": "Лаунж \"Панорама\"",
      "area": "Center",
      "capacity": 12,
      "rating": 4.9
    },
    {
      "id": 3,
      "name": "Бистро \"Встреча\"",
      "area": "Center",
      "capacity": 8,
      "rating": 4.6
    }
  ],
  "results_count": 3,
  "search_params": {
    "date": "2026-03-16",
    "time": "19:00",
    "guests": 2,
    "location": "Center"
  },
  "timestamp": "2026-03-15T12:00:00.000Z"
}
```

---

### Тест-кейс 2: Missing Data (недостаточно данных)

**Входные данные:**
```json
{
  "user_id": "10001",
  "message": "Найди варианты"
}
```

**Ожидаемый ответ:**
```json
{
  "status": "missing_data",
  "intent": "search_options",
  "missing_fields": ["date", "time", "guests", "location"],
  "message": "Недостаточно данных для поиска. Пожалуйста, укажите: date, time, guests, location",
  "session_id": "sess_1234567890_abc123",
  "timestamp": "2026-03-15T12:00:00.000Z"
}
```

---

### Тест-кейс 3: Error (ошибка worker/БД)

**Сценарий:** Эмуляция недоступности БД (отключить БД или указать неверные credentials)

**Входные данные:**
```json
{
  "user_id": "10001",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}
```

**Ожидаемый ответ:**
```json
{
  "status": "error",
  "intent": "search_options",
  "session_id": "sess_1234567890_abc123",
  "message": "Database connection failed",
  "error_type": "orchestrator_error",
  "timestamp": "2026-03-15T12:00:00.000Z"
}
```

---

### Тест-кейс 4: AI-Enhanced (сложный запрос)

**Входные данные:**
```json
{
  "user_id": "10001",
  "message": "Хочу поужинать завтра вечером с девушкой, есть что-нибудь романтичное в центре?"
}
```

**Ожидаемый ответ (AI извлекает параметры):**
```json
{
  "status": "success",
  "intent": "search_options",
  "session_id": "sess_1234567890_xyz789",
  "results": [
    {
      "id": 4,
      "name": "Лаунж \"Панорама\"",
      "area": "Center",
      "capacity": 12,
      "rating": 4.9
    },
    ...
  ],
  "results_count": 3,
  "search_params": {
    "date": "2026-03-16",
    "time": "19:00",
    "guests": 2,
    "location": "Center"
  },
  "timestamp": "2026-03-15T12:00:00.000Z"
}
```

**Преимущество AI-версии:**
- Распознаёт "завтра вечером" → time: "19:00"
- Распознаёт "с девушкой" → guests: 2
- Понимает контекстный запрос "что-нибудь романтичное" → intent: search_options

---

## Контракты

### Входной контракт (Webhook)

```typescript
interface WebhookRequest {
  user_id: string;
  message: string;
}
```

### Контракт между Orchestrator → Worker

```typescript
interface WorkerInput {
  date: string;      // YYYY-MM-DD
  time: string;      // HH:MM
  guests: number;
  location: string;  // Center, North, South, East, West
}
```

### Контракт ответа Worker → Orchestrator

```typescript
interface WorkerResponse {
  status: 'success' | 'error';
  search_params?: {
    date: string;
    time: string;
    guests: number;
    location: string;
  };
  results_count?: number;
  results?: Array<{
    id: number;
    name: string;
    area: string;
    capacity: number;
    rating: number;
    time_slot: string;
    features: string[];
  }>;
  error_type?: string;
  message?: string;
  timestamp: string;
}
```

### Финальный контракт ответа (Webhook Response)

```typescript
interface FinalResponse {
  status: 'success' | 'missing_data' | 'error';
  intent: string;
  session_id: string;
  results?: Array<...>;
  results_count?: number;
  missing_fields?: string[];
  message?: string;
  search_params?: {...};
  error_type?: string;
  timestamp: string;
}
```

---

## Архитектурные решения

### 1. Разделение на Orchestrator и Worker

**Почему так:**
- **Изоляция ответственности**: Orchestrator управляет потоком, Worker выполняет конкретную задачу
- **Масштабируемость**: Можно добавить больше workers для других типов запросов (booking_worker, review_worker и т.д.)
- **Переиспользование**: Worker можно вызывать из нескольких orchestrator'ов
- **Отладка**: Легче локализовать проблемы в независимых модулях

### 2. Session State в PostgreSQL

**Почему так:**
- **Единый источник истины**: Все состояния сессий в одном месте
- **Аудит**: Можно отследить историю всех запросов пользователя
- **Восстановление**: При сбое можно восстановить контекст сессии
- **Аналитика**: Данные для последующего анализа поведения пользователей

**Структура session_state:**
```sql
{
  user_id: string,      // идентификатор пользователя
  session_id: string,   // уникальный ID сессии
  intent: string,       // намерение (search_options)
  data: JSONB,          // полные данные сессии
  status: string,       // pending, processing, completed, error
  created_at: timestamp,
  updated_at: timestamp
}
```

### 3. Error Handling и Retry

**Где реализовано:**
- **Retry на Query Options Catalog** (worker): 3 попытки с интервалом 1 сек — защита от временных сбоев БД
- **Retry на Call Search Worker** (orchestrator): 3 попытки с интервалом 2 сек — защита от сбоев worker
- **Error Trigger** в каждом workflow: глобальный перехват ошибок
- **Error Handler** ноды: форматирование ошибок в едином контракте

### 4. Structured JSON Contracts

**Преимущества:**
- Предсказуемость интеграции
- Упрощение тестирования
- Возможность валидации на границах workflow
- Лёгкость документирования

### 5. NLP через Code Node

**Почему не внешняя AI-нода:**
- Простота для демонстрации
- Не требует внешних API ключей
- Легко заменить на реальную AI-ноду (OpenAI, Claude) при необходимости
- Контроль над логикой парсинга

---

## Структура проекта

```
C:\qwen\test_n8n\2\
├── schema.sql                    # SQL схема БД
├── basic/                        # Basic версия (эвристика)
│   ├── workflow_orchestrator.json
│   └── workflow_search_worker.json
├── ai-enhanced/                  # AI-версия (OpenAI)
│   ├── workflow_orchestrator_ai.json
│   └── workflow_search_worker.json
├── tests/                        # Автоматические тесты
│   ├── 01_test_success.sh        # Тест успешного поиска
│   ├── 02_test_missing_data.sh   # Тест недостающих данных
│   ├── 03_test_error.sh          # Тест ошибки БД
│   ├── run_all_tests.sh          # Запуск всех тестов
│   └── README_tests.md           # Документация тестов
├── README.md                     # Основная документация
├── ARCHITECTURE.md               # Архитектурные решения
├── CHANGELOG.md                  # История изменений
└── .env.example                  # Шаблон переменных окружения
```

---

## Масштабирование

### Возможные улучшения

1. **Добавление новых workers:**
   - `booking_worker` — бронирование мест
   - `notification_worker` — отправка уведомлений
   - `analytics_worker` — сбор метрик

2. **AI-интеграция:**
   - Замена Code Node на OpenAI/Anthropic для извлечения параметров
   - Классификация intent через ML-модель

3. **Кеширование:**
   - Redis для кеширования частых запросов
   - Session state в Redis для скорости

4. **Мониторинг:**
   - Логирование в external system (ELK, Datadog)
   - Метрики выполнения workflow

---

## Поддержка

При возникновении проблем:
1. Проверить логи выполнения в n8n (Execution Log)
2. Проверить статус сессии в таблице `session_state`
3. Убедиться, что credentials БД корректны
4. Проверить, что worker workflow активен и импортирован

---

## 🤝 Вклад в проект

Приветствуются issue и pull requests! См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

- 🐛 [Сообщить об ошибке](../../issues/new?template=bug_report.md)
- 💡 [Предложить функцию](../../issues/new?template=feature_request.md)
- 📝 [Улучшить документацию](CONTRIBUTING.md)

---

## 📄 Лицензия

MIT License — см. [LICENSE](LICENSE) файл.

---

## 👥 Авторы

- **n8n Mini Orchestrator + Worker** — тестовое задание для кандидата

См. также список [контрибьюторов](../../graphs/contributors).

---

## 🙏 Благодарности

- [n8n](https://n8n.io) — платформа автоматизации
- [PostgreSQL](https://www.postgresql.org) — база данных
- [OpenAI](https://openai.com) — AI-модели (для AI-версии)

---

<div align="center">

**Если проект полезен — поставьте ⭐ на GitHub!**

[⬆️ Вернуться к началу](#n8n-mini-orchestrator--worker)

</div>
