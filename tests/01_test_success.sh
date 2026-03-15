#!/bin/bash
# =============================================================================
# Тест #1: SUCCESS — Успешный поиск вариантов
# =============================================================================
# Ожидаемый результат: status = "success", результаты поиска (до 3 вариантов)
# =============================================================================

# Настройки
N8N_URL="${N8N_URL:-http://localhost:5678}"
WEBHOOK_PATH="webhook/search-request"
TIMEOUT=30

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=============================================="
echo "Тест #1: SUCCESS"
echo "=============================================="
echo ""

# Тестовые данные — все параметры присутствуют
TEST_DATA='{
  "user_id": "10001",
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

# Проверка HTTP статуса
if [ "$HTTP_CODE" != "200" ]; then
  echo "${RED}❌ FAIL: HTTP статус != 200${NC}"
  exit 1
fi

# Проверка статуса в ответе
STATUS=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null)

if [ "$STATUS" != "success" ]; then
  echo "${RED}❌ FAIL: status != 'success' (получено: '$STATUS')${NC}"
  exit 1
fi

# Проверка наличия результатов
RESULTS_COUNT=$(echo "$BODY" | python -c "import sys, json; print(len(json.load(sys.stdin).get('results', [])))" 2>/dev/null)

if [ "$RESULTS_COUNT" -lt 1 ]; then
  echo "${RED}❌ FAIL:.results пуст${NC}"
  exit 1
fi

# Проверка session_id
SESSION_ID=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  echo "${RED}❌ FAIL: session_id отсутствует${NC}"
  exit 1
fi

echo "${GREEN}✅ PASS: Все проверки пройдены${NC}"
echo "  - HTTP статус: 200"
echo "  - status: success"
echo "  - Найдено вариантов: $RESULTS_COUNT"
echo "  - session_id: $SESSION_ID"
echo ""

exit 0
