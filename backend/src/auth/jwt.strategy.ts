import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Role } from '../common/enums';
import { APP_CONFIG, AppConfig } from '../config/app-config';
import { UsersService } from '../users/users.service';
import { AuthUser, JwtPayload } from './auth-user.interface';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @Inject(APP_CONFIG) config: AppConfig,
    private readonly users: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.jwt.secret,
    });
  }

  /**
   * Se consulta el usuario en cada petición: si el super admin lo desactiva
   * o suspende su empresa, el token deja de servir de inmediato.
   */
  async validate(payload: JwtPayload): Promise<AuthUser> {
    const user = await this.users.findByIdWithCompany(payload.sub);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Usuario inactivo o inexistente');
    }
    if (user.role === Role.COMPANY_ADMIN && (!user.company || !user.company.isActive)) {
      throw new UnauthorizedException('La empresa está suspendida');
    }
    return { id: user.id, email: user.email, role: user.role, companyId: user.companyId };
  }
}
