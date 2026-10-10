// Carga .env antes que cualquier otro import (algunos decoradores leen process.env)
import 'dotenv/config';
import 'reflect-metadata';
import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { resolve } from 'path';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  const origins = (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
  app.enableCors({ origin: origins.length ? origins : true });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // quita campos que no estén en el DTO
      forbidNonWhitelisted: true, // ...y avisa si mandan campos de más
      transform: true,
    }),
  );

  // Imágenes subidas: GET /uploads/<companyId>/<archivo>
  app.useStaticAssets(resolve(process.env.UPLOAD_DIR ?? 'uploads'), {
    prefix: '/uploads/',
    index: false,
  });

  const swagger = new DocumentBuilder()
    .setTitle('La Carta API')
    .setDescription('Menús multi-empresa: super admin, admins de empresa y menú público')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  SwaggerModule.setup('docs', app, () => SwaggerModule.createDocument(app, swagger), {
    swaggerOptions: { persistAuthorization: true },
  });

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port);
  Logger.log(`API lista en http://localhost:${port}  ·  Swagger: http://localhost:${port}/docs`, 'Bootstrap');
}
bootstrap();
