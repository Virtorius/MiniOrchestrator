-- Schema для n8n Mini Orchestrator + Worker
-- Версия n8n: 2.4.8
-- База данных: PostgreSQL / Supabase

-- ============================================
-- Таблица: session_state
-- Хранение состояния сессии между шагами workflow
-- ============================================
CREATE TABLE IF NOT EXISTS session_state (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    session_id VARCHAR(255) NOT NULL UNIQUE,
    intent VARCHAR(100),
    data JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Индексы для ускорения поиска
CREATE INDEX IF NOT EXISTS idx_session_state_user_id ON session_state(user_id);
CREATE INDEX IF NOT EXISTS idx_session_state_session_id ON session_state(session_id);
CREATE INDEX IF NOT EXISTS idx_session_state_status ON session_state(status);

-- ============================================
-- Таблица: options_catalog
-- Каталог вариантов для поиска (mock данные)
-- ============================================
CREATE TABLE IF NOT EXISTS options_catalog (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    area VARCHAR(100) NOT NULL,
    capacity INTEGER NOT NULL DEFAULT 2,
    time_slot VARCHAR(50),
    features JSONB DEFAULT '[]',
    rating DECIMAL(2,1) DEFAULT 5.0,
    is_active BOOLEAN DEFAULT TRUE
);

-- Индексы для фильтрации
CREATE INDEX IF NOT EXISTS idx_options_catalog_area ON options_catalog(area);
CREATE INDEX IF NOT EXISTS idx_options_catalog_capacity ON options_catalog(capacity);
CREATE INDEX IF NOT EXISTS idx_options_catalog_is_active ON options_catalog(is_active);

-- ============================================
-- Mock данные для options_catalog
-- ============================================
INSERT INTO options_catalog (name, area, capacity, time_slot, features, rating, is_active) VALUES
    ('Ресторан "Центральный"', 'Center', 10, '18:00-23:00', '["wifi", "parking", "terrace"]', 4.8, TRUE),
    ('Кафе "Уют"', 'Center', 6, '17:00-22:00', '["wifi", "pet_friendly"]', 4.5, TRUE),
    ('Бистро "Встреча"', 'Center', 8, '18:00-00:00', '["parking", "live_music"]', 4.6, TRUE),
    ('Лаунж "Панорама"', 'Center', 12, '19:00-02:00', '["wifi", "view", "cocktails"]', 4.9, TRUE),
    ('Пиццерия "Италия"', 'North', 8, '12:00-23:00', '["delivery", "kids_menu"]', 4.3, TRUE),
    ('Суши-бар "Сакура"', 'East', 6, '13:00-22:00', '["delivery", "sake_bar"]', 4.4, TRUE),
    ('Стейк-хаус "Огонь"', 'West', 10, '17:00-00:00', '["parking", "wine_cellar"]', 4.7, TRUE),
    ('Кофейня "Зерно"', 'Center', 4, '08:00-20:00', '["wifi", "coworking"]', 4.2, TRUE),
    ('Бар "Ночь"', 'Center', 15, '20:00-05:00', '["cocktails", "dj", "dance_floor"]', 4.5, TRUE),
    ('Семейный ресторан "Дом"', 'South', 20, '11:00-23:00', '["kids_menu", "parking", "playground"]', 4.6, TRUE)
ON CONFLICT DO NOTHING;

-- ============================================
-- Комментарий к таблицам
-- ============================================
COMMENT ON TABLE session_state IS 'Хранение состояния сессии для n8n workflow';
COMMENT ON TABLE options_catalog IS 'Каталог вариантов для поиска (рестораны, места)';

-- Поля таблицы session_state
COMMENT ON COLUMN session_state.user_id IS 'Идентификатор пользователя';
COMMENT ON COLUMN session_state.session_id IS 'Уникальный идентификатор сессии (формат: sess_XXX)';
COMMENT ON COLUMN session_state.intent IS 'Намерение пользователя (например: search_options)';
COMMENT ON COLUMN session_state.data IS 'JSON с данными сессии (date, time, guests, location и др.)';
COMMENT ON COLUMN session_state.status IS 'Статус сессии: pending, processing, completed, error';

-- Поля таблицы options_catalog
COMMENT ON COLUMN options_catalog.name IS 'Название места';
COMMENT ON COLUMN options_catalog.area IS 'Район расположения (Center, North, South, East, West)';
COMMENT ON COLUMN options_catalog.capacity IS 'Максимальная вместимость (кол-во гостей)';
COMMENT ON COLUMN options_catalog.time_slot IS 'Временной интервал работы';
COMMENT ON COLUMN options_catalog.features IS 'JSON массив с особенностями места';
COMMENT ON COLUMN options_catalog.rating IS 'Рейтинг места (0-5)';
