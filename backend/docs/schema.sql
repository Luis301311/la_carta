-- =====================================================================
-- La Carta · Esquema de referencia (PostgreSQL)
-- No necesitas correr esto si usas DB_SYNC=true: TypeORM crea las tablas
-- a partir de las entidades. Sirve para documentación, el diagrama E-R
-- o para crear la base a mano en producción.
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TYPE user_role    AS ENUM ('SUPER_ADMIN', 'COMPANY_ADMIN');
CREATE TYPE order_status AS ENUM ('pending','confirmed','preparing','ready','delivered','cancelled');
CREATE TYPE order_type   AS ENUM ('dine_in','takeaway','delivery');
CREATE TYPE payment_method AS ENUM ('cash','transfer');

CREATE TABLE companies (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name           varchar(120) NOT NULL,
  slug           varchar(80)  NOT NULL UNIQUE,
  tax_id         varchar(40),
  phone          varchar(30),
  whatsapp_phone varchar(30),
  email          varchar(160),
  address        varchar(255),
  latitude       double precision,
  longitude      double precision,
  logo_url       varchar(500),
  cover_url      varchar(500),
  primary_color  varchar(9),
  timezone       varchar(60) NOT NULL DEFAULT 'America/Bogota',
  -- Pagos sin pasarela (transferencia por QR / llave Bre-B, verificada a mano)
  accepts_cash     boolean NOT NULL DEFAULT true,
  accepts_transfer boolean NOT NULL DEFAULT false,
  bre_bkey         varchar(80),            -- llave Bre-B
  payment_holder   varchar(120),
  payment_qr_url   varchar(500),
  payment_notes    text,
  is_active      boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email         varchar(160) NOT NULL UNIQUE,
  password_hash varchar NOT NULL,
  full_name     varchar(120) NOT NULL,
  role          user_role NOT NULL,
  company_id    uuid REFERENCES companies(id) ON DELETE CASCADE,  -- NULL = super admin
  is_active     boolean NOT NULL DEFAULT true,
  last_login_at timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE business_hours (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  day_of_week smallint NOT NULL,            -- 1 = lunes ... 7 = domingo
  open_time   varchar(5) NOT NULL DEFAULT '00:00',
  close_time  varchar(5) NOT NULL DEFAULT '00:00',
  closed      boolean NOT NULL DEFAULT false,
  UNIQUE (company_id, day_of_week)
);

CREATE TABLE categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id  uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  name        varchar(100) NOT NULL,
  description text,
  image_url   varchar(500),
  sort_order  int NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON categories (company_id, sort_order);

CREATE TABLE products (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  category_id  uuid NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
  name         varchar(150) NOT NULL,
  description  text NOT NULL DEFAULT '',
  base_price   numeric(12,2) NOT NULL,
  image_urls   text[] NOT NULL DEFAULT '{}',
  is_available boolean NOT NULL DEFAULT true,
  sort_order   int NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON products (company_id, category_id);

CREATE TABLE extra_groups (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  title         varchar(100) NOT NULL,
  is_required   boolean NOT NULL DEFAULT false,
  min_selection int NOT NULL DEFAULT 0,
  max_selection int NOT NULL DEFAULT 1,
  sort_order    int NOT NULL DEFAULT 0
);

CREATE TABLE extra_options (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   uuid NOT NULL REFERENCES extra_groups(id) ON DELETE CASCADE,
  name       varchar(100) NOT NULL,
  price      numeric(12,2) NOT NULL DEFAULT 0,
  is_active  boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0
);

CREATE TABLE orders (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id    uuid NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
  order_number  int NOT NULL,
  status        order_status NOT NULL DEFAULT 'pending',
  type          order_type NOT NULL,
  customer_name varchar(120) NOT NULL,
  phone         varchar(30),
  address       varchar(255),
  table_number  varchar(20),
  notes         text,
  payment_method    payment_method NOT NULL DEFAULT 'cash',
  payment_proof_url varchar(500),            -- captura del comprobante
  proof_token       varchar(64),             -- clave para subir el comprobante sin login
  total         numeric(12,2) NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (company_id, order_number)
);
CREATE INDEX ON orders (company_id, created_at);

CREATE TABLE order_items (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id     uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id   uuid REFERENCES products(id) ON DELETE SET NULL,
  product_name varchar(150) NOT NULL,
  unit_price   numeric(12,2) NOT NULL,
  quantity     int NOT NULL,
  extras_total numeric(12,2) NOT NULL,
  line_total   numeric(12,2) NOT NULL,
  comment      text
);

CREATE TABLE order_item_extras (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_item_id uuid NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
  option_id     uuid,                     -- sin FK a propósito (histórico)
  group_title   varchar(100) NOT NULL,
  option_name   varchar(100) NOT NULL,
  unit_price    numeric(12,2) NOT NULL,
  quantity      int NOT NULL DEFAULT 1
);
