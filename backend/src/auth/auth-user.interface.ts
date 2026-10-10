import { Role } from '../common/enums';

/** Lo que va dentro del JWT */
export interface JwtPayload {
  sub: string;
  role: Role;
  companyId: string | null;
}

/** Lo que queda en request.user después de validar el token */
export interface AuthUser {
  id: string;
  email: string;
  role: Role;
  companyId: string | null;
}
