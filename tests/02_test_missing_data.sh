#!/bin/bash
# =============================================================================
# Тест #2: MISSING_DATA — Недостаточно данных для поиска
# =============================================================================
# Ожидаемый результат: status = "missing_data", список missing_fields
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
echo "Тест #2: MISSING_DATA"
echo "=============================================="
echo ""

# Тестовые данные — нет параметров (только общее сообщение)
TEST_DATA='{
  "user_id": "10002",
  "message": "Найди варианты"
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

if [ "$STATUS" != "missing_data" ]; then
  echo "${RED}❌ FAIL: status != 'missing_data' (получено: '$STATUS')${NC}"
  exit 1
fi

# Проверка наличия missing_fields
MISSING_FIELDS=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('missing_fields', []))" 2>/dev/null)

if [ -z "$MISSING_FIELDS" ] || [ "$MISSING_FIELDS" == "[]" ]; then
  echo "${RED}❌ FAIL: missing_fields пуст${NC}"
  exit 1
fi

# Проверка session_id
SESSION_ID=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  echo "${RED}❌ FAIL: session_id отсутствует${NC}"
  exit 1
fi

# Проверка наличия message
MESSAGE=$(echo "$BODY" | python -c "import sys, json; print(json.load(sys.stdin).get('message', ''))" 2>/dev/null)

if [ -z "$MESSAGE" ]; then
  echo "${RED}❌ FAIL: message отсутствует${NC}"
  exit 1
fi

echo "${GREEN}✅ PASS: Все проверки пройдены${NC}"
echo "  - HTTP статус: 200"
echo "  - status: missing_data"
echo "  - missing_fields: $MISSING_FIELDS"
echo "  - message: $MESSAGE"
echo "  - session_id: $SESSION_ID"
echo ""

exit 0
