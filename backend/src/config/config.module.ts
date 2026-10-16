import { Global, Inject, Module } from '@nestjs/common';
import { APP_CONFIG, loadConfig } from './app-config';

/**
 * Expone la configuración a Nest como provider SINGLETON (Nest crea una
 * sola instancia por defecto). Global: cualquier módulo puede inyectarla.
 *
 * En pruebas se reemplaza fácil:
 *   Test.createTestingModule({...}).overrideProvider(APP_CONFIG).useValue(fakeConfig)
 */
@Global()
@Module({
  providers: [{ provide: APP_CONFIG, useFactory: loadConfig }],
  exports: [APP_CONFIG],
})
export class AppConfigModule {}

/** Atajo: `constructor(@InjectConfig() private readonly config: AppConfig)` */
export const InjectConfig = () => Inject(APP_CONFIG);
