import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Role } from '../../common/enums';
import { UUID_REGEX } from '../../common/uuid';
import { AuthUser } from '../auth-user.interface';

/**
 * Corazón del multi-empresa. Se usa en toda ruta /companies/:companyId/...
 *  - SUPER_ADMIN: puede entrar a cualquier empresa.
 *  - COMPANY_ADMIN: solo a la suya (la del token).
 */
@Injectable()
export class CompanyAccessGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const user: AuthUser | undefined = req.user;
    const companyId: string | undefined = req.params?.companyId;

    if (!companyId || !UUID_REGEX.test(companyId)) {
      throw new BadRequestException('companyId inválido');
    }
    if (!user) throw new ForbiddenException();
    if (user.role === Role.SUPER_ADMIN) return true;
    if (user.role === Role.COMPANY_ADMIN && user.companyId === companyId) return true;

    throw new ForbiddenException('No tienes acceso a esta empresa');
  }
}
