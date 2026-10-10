# La Carta · API (NestJS + PostgreSQL)

Backend multi-empresa de La Carta: cada restaurante tiene su propio menú y su propio admin,
y el **super admin** administra todos los restaurantes.

```
lacarta/            ← app Flutter (sin cambios)
└── backend/        ← esta API
```

## Roles

| Rol | Qué puede hacer |
|---|---|
| `SUPER_ADMIN` | Crear, editar, suspender y borrar empresas; crear o desactivar sus admins; entrar al menú y a los pedidos de **cualquier** empresa |
| `COMPANY_ADMIN` | Solo **su** empresa: perfil, horario, categorías, productos con extras, imágenes y pedidos |
| Público (sin login) | Ver el menú por slug y hacer pedidos |

El aislamiento lo garantiza `CompanyAccessGuard`. Toda ruta `/companies/:companyId/...` verifica
que el `companyId` del token sea el mismo de la URL (el super admin pasa siempre). Además, cada
consulta filtra por `companyId`, así que un admin nunca ve ni modifica datos de otra empresa.

## Puesta en marcha (Windows)

Requisitos: Node 20 o superior, y Docker Desktop **o** una base Postgres (sirve la de Supabase).

```bash
cd backend
copy .env.example .env          # en PowerShell: Copy-Item .env.example .env
docker compose up -d            # Postgres local en el puerto 5432 (omítelo si usas Supabase)
npm install
npm run start:dev               # la primera vez crea las tablas (DB_SYNC=true)
```

En otra terminal, carga el super admin y un restaurante de prueba:

```bash
npm run seed
```

- API: http://localhost:3000
- Swagger (documentación y pruebas): http://localhost:3000/docs. Haz login, copia el
  `accessToken` y pégalo en **Authorize**.
- `requests.http`: el flujo completo listo para la extensión REST Client de VS Code.

Usuarios del seed:

| Usuario | Contraseña |
|---|---|
| `superadmin@lacarta.app` | `CambiaEsto123` (o lo que pongas en `.env`) |
| `admin@burgerhouse.com` | `Admin12345` |

### Usar el Postgres de Supabase en vez de Docker

En Supabase ve a *Project Settings → Database → Connection string (URI)* y ponlo en `.env`:

```
DATABASE_URL=postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres
DB_SSL=true
```

Supabase queda solo como base de datos. La lógica y los permisos viven en esta API.

## Endpoints

**Auth**

| Método | Ruta | Quién |
|---|---|---|
| POST | `/auth/login` | todos |
| GET | `/auth/me` | con token |
| PATCH | `/auth/password` | con token |

**Empresas**

| Método | Ruta | Quién |
|---|---|---|
| GET | `/companies?search=` | super admin |
| POST | `/companies` (con `admin` opcional) | super admin |
| GET / PATCH | `/companies/:companyId` | super admin o su admin (`slug` solo lo cambia el super admin) |
| PUT | `/companies/:companyId/hours` | super admin o su admin |
| PATCH | `/companies/:companyId/status` | super admin |
| DELETE | `/companies/:companyId` | super admin (borra todo en cascada) |
| GET / POST | `/companies/:companyId/admins` | super admin |
| PATCH | `/companies/:companyId/admins/:userId/status` y `/password` | super admin |

**Menú de cada empresa** (super admin o su admin)

| Método | Ruta |
|---|---|
| GET / POST | `/companies/:companyId/categories` |
| GET / PATCH / DELETE | `/companies/:companyId/categories/:id` |
| GET / POST | `/companies/:companyId/products?categoryId=` |
| GET / PATCH / DELETE | `/companies/:companyId/products/:id` |
| PATCH | `/companies/:companyId/products/:id/availability` |
| POST | `/companies/:companyId/uploads/image` (multipart, campo `file`) |
| GET | `/companies/:companyId/orders?status=&from=&to=&page=&limit=` |
| GET | `/companies/:companyId/orders/:id` |
| PATCH | `/companies/:companyId/orders/:id/status` |

**Público** (sin token)

| Método | Ruta |
|---|---|
| GET | `/public/:slug/menu`: empresa, horario, `isOpenNow` y categorías con productos y extras |
| POST | `/public/:slug/orders`: devuelve el pedido y un `whatsappUrl` listo para abrir |

## Decisiones importantes

- **Los precios los calcula el servidor.** El pedido solo envía `productId`, `quantity` y los
  `optionId` de los extras. El total que llega desde el celular se ignora.
- **Reglas de extras.** Se validan `minSelection`, `maxSelection` y `isRequired` de cada grupo.
- **Histórico de pedidos.** Cada ítem guarda nombre y precio del momento. Si después editas o
  borras el producto, el pedido viejo no cambia.
- **Consecutivo por empresa.** Pedido #1, #2… para cada restaurante, sin choques cuando llegan
  pedidos al mismo tiempo.
- **Horarios que pasan la medianoche.** Por ejemplo, 18:00–02:00. Se calculan en la zona horaria
  de la empresa (por defecto `America/Bogota`).
- **Borrar una categoría con productos** da 409: mueve los productos o desactiva la categoría.
- **Suspender una empresa.** Su menú público da 404 y su admin pierde acceso de inmediato,
  incluso con un token vigente.

## Modelo de datos

`docs/schema.sql` tiene el esquema equivalente en SQL; sirve para el diagrama E-R o para crear
la base a mano.

```
companies 1─* users (COMPANY_ADMIN)
companies 1─* business_hours
companies 1─* categories 1─* products 1─* extra_groups 1─* extra_options
companies 1─* orders 1─* order_items 1─* order_item_extras
```

## Producción

- Pon `DB_SYNC=false` y crea las tablas con `docs/schema.sql` o con migraciones de TypeORM.
- Cambia `JWT_SECRET` y la contraseña del super admin.
- Define `CORS_ORIGINS` con el dominio de la app web.
- Las imágenes se guardan en disco (`uploads/`). Para producción conviene S3, Cloudinary o
  Supabase Storage; solo hay que cambiar `uploads.controller.ts`.

## Conectar la app Flutter

| Hoy en Flutter | Pasa a |
|---|---|
| `main.dart`: consulta `restaurants` por slug | `GET /public/:slug/menu` (una sola petición trae todo) |
| `ProductServices` / `CategoryServices` (menú) | Ya vienen dentro del menú público |
| `OrderService.saveOrder` | `POST /public/:slug/orders` y abrir `whatsappUrl` |
| Panel `/admin` sin login | Pantalla de login → `POST /auth/login`, guardar el token y enviarlo en `Authorization: Bearer` |
| CRUD del admin | `/companies/{companyId}/categories`, `/products`, `/uploads/image`, `/orders` |
| `StorageService` (Supabase) | `POST /companies/:companyId/uploads/image` |
| Super admin | Nuevas pantallas sobre `/companies` |

Después se pueden quitar `supabase_flutter`, `firebase_core`, `cloud_firestore` y
`firebase_storage` del `pubspec.yaml`.
