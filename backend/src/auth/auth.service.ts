import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { Role } from '../common/enums';
import { User } from '../users/user.entity';
import { UsersService } from '../users/users.service';
import { JwtPayload } from './auth-user.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async login(email: string, password: string) {
    const user = await this.users.findByEmailWithPassword(email);
    // Mismo mensaje en ambos casos para no revelar qué correos existen
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      throw new UnauthorizedException('Correo o contraseña incorrectos');
    }
    if (!user.isActive) throw new UnauthorizedException('Usuario desactivado');
    if (user.role === Role.COMPANY_ADMIN && (!user.company || !user.company.isActive)) {
      throw new UnauthorizedException('La empresa está suspendida. Contacta al administrador');
    }

    await this.users.touchLastLogin(user.id);

    const payload: JwtPayload = { sub: user.id, role: user.role, companyId: user.companyId };
    return {
      accessToken: await this.jwt.signAsync(payload),
      user: this.toProfile(user),
    };
  }

  async me(userId: string) {
    const user = await this.users.findByIdWithCompany(userId);
    if (!user) throw new UnauthorizedException();
    return this.toProfile(user);
  }

  async changePassword(userId: string, current: string, next: string) {
    const user = await this.users.findByIdWithPassword(userId);
    if (!user || !(await bcrypt.compare(current, user.passwordHash))) {
      throw new BadRequestException('La contraseña actual no es correcta');
    }
    await this.users.setPassword(userId, next);
    return { ok: true };
  }

  private toProfile(user: User) {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      companyId: user.companyId,
      company: user.company
        ? { id: user.company.id, name: user.company.name, slug: user.company.slug }
        : null,
    };
  }
}
