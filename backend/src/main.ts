import 'reflect-metadata';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { resolve } from 'path';
import { AppConfig, loadConfig } from './config/app-config';
import { InvalidEnvironmentError } from './config/env.validation';

async function bootstrap(config: AppConfig) {
  // Se importa DESPUÉS de validar la configuración: algunos decoradores
  // (p. ej. el límite de tamaño de las subidas) la leen al cargarse
  const { AppModule } = await import('./app.module');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Render (y casi cualquier hosting) pone un proxy delante: así req.ip es la
  // IP real del cliente y el límite de peticiones funciona por persona
  app.set('trust proxy', 1);
  app.enableShutdownHooks();

  const origins = config.server.corsOrigins;
  app.enableCors({ origin: origins.length ? [...origins] : true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // quita campos que no estén en el DTO
      forbidNonWhitelisted: true, // ...y avisa si mandan campos de más
      transform: true,
    }),
  );

  // Solo con almacenamiento local: servir las imágenes en /uploads/...
  // (con Cloudinary las URLs ya apuntan a Cloudinary)
  if (config.storage.driver === 'local') {
    app.useStaticAssets(resolve(config.storage.local.uploadDir), {
      prefix: '/uploads/',
      index: false,
    });
  }

  const swagger = new DocumentBuilder()
    .setTitle('La Carta API')
    .setDescription('Menús multi-empresa: super admin, admins de empresa y menú público')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('docs', app, () => SwaggerModule.createDocument(app, swagger), {
    swaggerOptions: { persistAuthorization: true },
  });

  await app.listen(config.server.port);
  Logger.log(
    `API lista en el puerto ${config.server.port} (${config.env})  ·  Swagger: /docs`,
    'Bootstrap',
  );
}

// Fail-fast: si el .env está mal, se explica qué falta y no arranca
let config: AppConfig;
try {
  config = loadConfig();
} catch (err) {
  if (err instanceof InvalidEnvironmentError) {
    Logger.error(err.message, undefined, 'Config');
    process.exit(1);
  }
  throw err;
}
bootstrap(config);
