#!/bin/bash
# =============================================================================
# Тест #3: ERROR — Ошибка при выполнении (эмуляция ошибки БД)
# =============================================================================
# Ожидаемый результат: status = "error", message с описанием ошибки
# =============================================================================
# ПРИМЕЧАНИЕ: Этот тест требует временного отключения БД или указания
# неверных credentials для PostgreSQL в n8n.
#
# Способ 1: Временно отключите PostgreSQL
# Способ 2: Измените credentials в n8n на неверные
# Способ 3: Используйте отдельный workflow с эмуляцией ошибки
# =============================================================================

# Настройки
N8N_URL="${N8N_URL:-http://localhost:5678}"
WEBHOOK_PATH="webhook/search-request"
TIMEOUT=30

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=============================================="
echo "Тест #3: ERROR"
echo "=============================================="
echo ""

echo "${BLUE}ВАЖНО:${NC}"
echo "Этот тест требует эмуляции ошибки БД."
echo ""
echo "Варианты:"
echo "  1. Отключите PostgreSQL перед запуском"
echo "  2. Используйте неверные credentials в n8n"
echo "  3. Измените query на заведомо ошибочный"
echo ""
read -p "Продолжить? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "${YELLOW}Тест пропущен${NC}"
  exit 0
fi

# Тестовые данные — все параметры присутствуют (но БД должна вернуть ошибку)
TEST_DATA='{
  "user_id": "10003",
  "message": "Найди варианты на завтра в 19:00 на двоих в центре"
}'

echo "${YELLOW}Входные данные:${NC}"
echo "$TEST_DATA" | python -m json.tool 2>/dev/null || echo "$TEST_DATA"
echo ""

# Отправка запроса
echo "${YELLOW}Отправка запроса...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  "$N8N_URL/$WEBHOOK_PATH" \
  -H "Content-Type: application/json" \
  -d "$TEST_DATA" \
  --max-time $TIMEOUT)

# Разделение тела ответа и HTTP кода
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

echo ""
echo "${YELLOW}HTTP статус:${NC} $HTTP_CODE"
echo ""
echo "${YELLOW}Ответ:${NC}"
echo "$BODY" | python -m json.tool 2>/dev/null || echo "$BODY"
echo ""

# Валидация ответа
echo "${YELLOW}Валидация...${NC}"

# Проверка статуса в ответе (может быть 200 или 500 в зависимости от настройки)
STATUS=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null)

if [ "$STATUS" != "error" ]; then
  echo "${RED}❌ FAIL: status != 'error' (получено: '$STATUS')${NC}"
  echo "${YELLOW}Подсказка: Убедитесь, что БД отключена или credentials неверны${NC}"
  exit 1
fi

# Проверка наличия message
MESSAGE=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('message', ''))" 2>/dev/null)

if [ -z "$MESSAGE" ]; then
  echo "${RED}❌ FAIL: message отсутствует${NC}"
  exit 1
fi

# Проверка session_id (может быть или не быть в зависимости от точки ошибки)
SESSION_ID=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('session_id', 'none'))" 2>/dev/null)

echo "${GREEN}✅ PASS: Все проверки пройдены${NC}"
echo "  - status: error"
echo "  - message: $MESSAGE"
echo "  - session_id: $SESSION_ID"
echo ""

exit 0
