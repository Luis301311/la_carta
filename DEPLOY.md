# Despliegue de La Carta (Render + Neon + Cloudinary)

```
 Clientes y personal
        │
        ▼
 lacarta-web  (Render · sitio estático · Flutter web)      gratis
        │  HTTPS
        ▼
 lacarta-api  (Render · web service · NestJS)              gratis (se duerme a los 15 min)
        │                      │
        ▼                      ▼
 Neon (PostgreSQL)        Cloudinary (imágenes y comprobantes)
 gratis, no expira        gratis
```

> **¿Por qué Neon y no la base de datos de Render?** La base gratis de Render **se borra a los
> 30 días**. La de Neon es gratis de forma permanente (1 GB por proyecto) y se "duerme" sola
> cuando no se usa, sin perder datos.

---

## 0. Antes de empezar (en tu PC)

```powershell
cd C:\Proyectos\Movil\lacarta\backend
npm install            # instala cloudinary y @nestjs/throttler y actualiza package-lock.json
cd ..
flutter pub get
```

Haz commit de todo, **incluido `backend/package-lock.json`** (Render lo usa con `npm ci`), y
súbelo a GitHub.

---

## 1. Migraciones (una sola vez, en tu PC)

**¿Hace falta un script SQL?** No. TypeORM genera las migraciones a partir de las entidades;
`docs/schema.sql` es solo documentación.

**¿Por qué no dejar `DB_SYNC=true` en producción?** Porque `synchronize` modifica las tablas sin
control: si renombras un campo, TypeORM puede **borrar la columna con sus datos**, y no queda
historial de cambios. Con migraciones cada cambio queda en un archivo que revisas antes de
desplegar.

La primera migración se genera contra una base **vacía**:

```powershell
cd C:\Proyectos\Movil\lacarta\backend

# 1) Base local limpia (borra SOLO los datos de prueba de Docker)
docker compose down -v
docker compose up -d

# 2) En backend/.env pon:  DB_SYNC=false

# 3) Generar y aplicar la migración inicial
npm run migration:generate -- src/database/migrations/InitialSchema
npm run migration:run

# 4) Volver a cargar los datos de prueba (si los quieres en local)
npm run seed
```

Se crea `src/database/migrations/<fecha>-InitialSchema.ts`. **Haz commit de ese archivo.**

**De aquí en adelante**, cuando cambies una entidad (por ejemplo, un campo nuevo):

```powershell
npm run migration:generate -- src/database/migrations/NombreDelCambio
npm run migration:run      # en local
git add . ; git commit -m "..." ; git push   # Render la aplica sola al desplegar
```

---

## 2. Base de datos en Neon

1. Crea una cuenta en https://neon.com y un proyecto (región: **AWS US East (Ohio)**, cerca de
   la región de Render que elijas; ver paso 4).
2. En **Connect**, copia la cadena de conexión. Se ve así:
   `postgresql://usuario:clave@ep-xxxx.us-east-2.aws.neon.tech/neondb?sslmode=require`
3. Guárdala: es tu `DATABASE_URL`.

---

## 3. Imágenes en Cloudinary

1. Crea una cuenta en https://cloudinary.com.
2. En **Settings → API Keys** copia la **API environment variable**:
   `cloudinary://API_KEY:API_SECRET@CLOUD_NAME`
3. Guárdala: es tu `CLOUDINARY_URL`.

Las imágenes quedan en la carpeta `lacarta/<id-empresa>/images` y los comprobantes en
`lacarta/<id-empresa>/proofs`.

### Cambiar de Cloudinary a S3 u otro servicio (sin tocar el resto del código)

La API usa **puertos y adaptadores** (`backend/src/storage/`):

| Archivo | Rol |
|---|---|
| `file-storage.ts` | El **puerto**: la interfaz `FileStorage` (`upload`, `delete`). Es lo único que conocen los controladores y servicios. |
| `local-file-storage.ts` | Adaptador para disco (desarrollo). |
| `cloudinary-file-storage.ts` | Adaptador para Cloudinary (producción). |
| `storage.module.ts` | Elige el adaptador según `STORAGE_DRIVER`. |

Para S3: crea `s3-file-storage.ts` con una clase que implemente `FileStorage`, agrega
`case 's3'` en `storage.module.ts` y cambia `STORAGE_DRIVER=s3`. Nada más cambia.

---

## 4. Render

1. En https://render.com → **New → Blueprint** → conecta tu repositorio de GitHub.
   Render lee `render.yaml` y propone dos servicios: **lacarta-api** y **lacarta-web**.
2. Elige la **región** (por ejemplo **Ohio**, la misma de Neon).
3. Te pedirá las variables marcadas como `sync: false`:

| Servicio | Variable | Valor |
|---|---|---|
| lacarta-api | `DATABASE_URL` | La cadena de Neon (paso 2) |
| lacarta-api | `CLOUDINARY_URL` | La de Cloudinary (paso 3) |
| lacarta-api | `PUBLIC_URL` | `https://lacarta-api.onrender.com` |
| lacarta-api | `CORS_ORIGINS` | `https://lacarta-web.onrender.com` |
| lacarta-web | `API_URL` | `https://lacarta-api.onrender.com` |

> Si el nombre `lacarta-api` o `lacarta-web` ya está tomado, Render agrega letras al final.
> Revisa las URLs reales en el panel y corrige `PUBLIC_URL`, `CORS_ORIGINS` y `API_URL`
> (Environment → editar → Save, y vuelve a desplegar).

`JWT_SECRET` lo genera Render solo (aleatorio). El resto de variables ya viene en `render.yaml`.

4. **Apply**. Al arrancar, la API aplica las migraciones (`DB_MIGRATIONS_RUN=true`).
   La app web tarda varios minutos la primera vez porque descarga Flutter
   (`scripts/render_build_web.sh`).

---

## 5. Crear el super admin (desde tu PC)

El plan gratis de Render no tiene consola, así que el seed se corre en tu PC **apuntando a Neon**.
En `backend/.env` (temporalmente):

```
DATABASE_URL=postgresql://...neon.tech/neondb?sslmode=require
DB_SSL=true
DB_SYNC=false
SEED_DEMO=false
SUPERADMIN_EMAIL=tu-correo@dominio.com
SUPERADMIN_PASSWORD=UnaClaveLargaYSegura
```

```powershell
npm run seed
```

Luego **vuelve a dejar tu `.env` apuntando a Docker** para seguir desarrollando.

---

## 6. Verificar

- `https://lacarta-api.onrender.com/health` → `{"status":"ok","db":"ok"}`
- `https://lacarta-api.onrender.com/docs` → Swagger
- `https://lacarta-web.onrender.com/login` → entra con el super admin y crea el primer restaurante
- `https://lacarta-web.onrender.com/<slug>` → menú del restaurante

---

## 7. Lo que hay que saber del plan gratis

- **La API se duerme** tras 15 minutos sin uso y tarda ~1 minuto en despertar. El primer cliente
  del día esperaría ese minuto. Solución gratis: un "ping" a `/health` cada 10 minutos con
  https://cron-job.org. Un servicio siempre despierto usa ~744 de las 750 horas gratis al mes,
  así que alcanza **solo para la API**.
- **Neon** se duerme tras 5 minutos sin uso; despierta en menos de un segundo.
- **El disco de Render se borra** en cada despliegue o reinicio: por eso las imágenes van a
  Cloudinary (`STORAGE_DRIVER=cloudinary`), nunca a disco.
- **Minutos de build**: compilar Flutter en Render consume minutos del plan. Si se te agotan,
  alternativa: publica la web en **Firebase Hosting**, que ya está configurado en `firebase.json`:
  ```powershell
  flutter build web --release --dart-define=API_URL=https://lacarta-api.onrender.com --dart-define=DEFAULT_SLUG=
  firebase deploy --only hosting
  ```
  (agrega `https://<tu-proyecto>.web.app` a `CORS_ORIGINS`).

---

## 8. Seguridad (lista rápida)

- [x] `JWT_SECRET` aleatorio (lo genera Render).
- [x] Límite de peticiones: 10 intentos de login/min y 15 pedidos/min por IP.
- [x] CORS solo para tu dominio (`CORS_ORIGINS`).
- [ ] Cambia la contraseña del super admin desde el panel (ícono 🔑) después del primer ingreso.
- [ ] Opcional: ocultar Swagger (`/docs`) en producción.
- [ ] Pendiente: servir los comprobantes de pago solo con sesión (hoy se ven con el enlace, que es
      aleatorio y no adivinable).
