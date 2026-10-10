import { ConflictException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcryptjs';
import { EntityManager, Repository } from 'typeorm';
import { Role } from '../common/enums';
import { User } from './user.entity';

export interface CreateUserInput {
  email: string;
  password: string;
  fullName: string;
  role: Role;
  companyId?: string | null;
}

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly repo: Repository<User>) {}

  static hashPassword(plain: string) {
    return bcrypt.hash(plain, 10);
  }

  findByIdWithCompany(id: string) {
    return this.repo.findOne({ where: { id }, relations: { company: true } });
  }

  findByEmailWithPassword(email: string) {
    return this.repo
      .createQueryBuilder('u')
      .addSelect('u.passwordHash')
      .leftJoinAndSelect('u.company', 'c')
      .where('u.email = :email', { email: email.trim().toLowerCase() })
      .getOne();
  }

  findByIdWithPassword(id: string) {
    return this.repo
      .createQueryBuilder('u')
      .addSelect('u.passwordHash')
      .where('u.id = :id', { id })
      .getOne();
  }

  findByCompany(companyId: string) {
    return this.repo.find({ where: { companyId }, order: { createdAt: 'ASC' } });
  }

  /** Acepta un EntityManager para poder crearse dentro de una transacción */
  async create(input: CreateUserInput, manager?: EntityManager) {
    const repo = manager ? manager.getRepository(User) : this.repo;
    const email = input.email.trim().toLowerCase();
    if (await repo.exists({ where: { email } })) {
      throw new ConflictException(`Ya existe un usuario con el correo ${email}`);
    }
    const user = repo.create({
      email,
      fullName: input.fullName,
      role: input.role,
      companyId: input.companyId ?? null,
      passwordHash: await UsersService.hashPassword(input.password),
    });
    const saved = await repo.save(user);
    const { passwordHash: _omit, ...safe } = saved;
    return safe;
  }

  async setPassword(id: string, plain: string) {
    await this.repo.update(id, { passwordHash: await UsersService.hashPassword(plain) });
  }

  async setActive(id: string, isActive: boolean) {
    await this.repo.update(id, { isActive });
  }

  findOne(where: { id?: string; companyId?: string }) {
    return this.repo.findOne({ where });
  }

  async touchLastLogin(id: string) {
    await this.repo.update(id, { lastLoginAt: new Date() });
  }
}
