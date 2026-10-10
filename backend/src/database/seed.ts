/**
 * npm run seed
 *  - Crea el SUPER_ADMIN (si no existe) con SUPERADMIN_EMAIL / SUPERADMIN_PASSWORD.
 *  - Si SEED_DEMO=true, crea el restaurante de prueba "burger_house" con su admin y un menú.
 * Se puede correr varias veces: no duplica nada.
 */
import 'dotenv/config';
import 'reflect-metadata';
import * as bcrypt from 'bcryptjs';
import { DataSource } from 'typeorm';
import { Category } from '../categories/category.entity';
import { Role } from '../common/enums';
import { BusinessHour } from '../companies/business-hour.entity';
import { Company } from '../companies/company.entity';
import { ExtraGroup } from '../products/extra-group.entity';
import { ExtraOption } from '../products/extra-option.entity';
import { Product } from '../products/product.entity';
import { User } from '../users/user.entity';
import { buildDataSourceOptions } from './data-source-options';

async function upsertUser(
  ds: DataSource,
  data: { email: string; password: string; fullName: string; role: Role; companyId?: string },
) {
  const repo = ds.getRepository(User);
  const email = data.email.trim().toLowerCase();
  const existing = await repo.findOne({ where: { email } });
  if (existing) {
    console.log(`  · ${email} ya existe`);
    return existing;
  }
  const user = await repo.save(
    repo.create({
      email,
      fullName: data.fullName,
      role: data.role,
      companyId: data.companyId ?? null,
      passwordHash: await bcrypt.hash(data.password, 10),
    }),
  );
  console.log(`  ✓ usuario ${email} (${data.role})`);
  return user;
}

async function seedDemo(ds: DataSource) {
  const companies = ds.getRepository(Company);
  let company = await companies.findOne({ where: { slug: 'burger_house' } });
  if (company) {
    console.log('  · burger_house ya existe');
  } else {
    company = await companies.save(
      companies.create({
        name: 'Burger House',
        slug: 'burger_house',
        phone: '6055555555',
        whatsappPhone: '573001234567',
        address: 'Cra 9 # 16-50, Valledupar',
        latitude: 10.4631,
        longitude: -73.2532,
        primaryColor: '#E53935',
      }),
    );
    console.log('  ✓ empresa burger_house');

    await ds.getRepository(BusinessHour).insert(
      [1, 2, 3, 4, 5, 6, 7].map((d) => ({
        companyId: company!.id,
        dayOfWeek: d,
        openTime: d >= 5 ? '12:00' : '11:00',
        closeTime: d >= 5 ? '02:00' : '22:00', // vie-dom cierra pasada la medianoche
        closed: false,
      })),
    );

    const cats = ds.getRepository(Category);
    const burgers = await cats.save(cats.create({ companyId: company.id, name: 'Hamburguesas', sortOrder: 0 }));
    const drinks = await cats.save(cats.create({ companyId: company.id, name: 'Bebidas', sortOrder: 1 }));

    const products = ds.getRepository(Product);
    const classic = await products.save(
      products.create({
        companyId: company.id,
        categoryId: burgers.id,
        name: 'Hamburguesa clásica',
        description: 'Carne 150 g, queso, lechuga, tomate y salsa de la casa',
        basePrice: 18000,
        sortOrder: 0,
      }),
    );
    await products.save(
      products.create({
        companyId: company.id,
        categoryId: burgers.id,
        name: 'Doble carne',
        description: 'Dos carnes de 150 g, doble queso y tocineta',
        basePrice: 26000,
        sortOrder: 1,
      }),
    );
    await products.save(
      products.create({
        companyId: company.id,
        categoryId: drinks.id,
        name: 'Limonada de coco',
        basePrice: 8000,
      }),
    );

    const groups = ds.getRepository(ExtraGroup);
    const options = ds.getRepository(ExtraOption);
    const term = await groups.save(
      groups.create({ productId: classic.id, title: 'Término de la carne', isRequired: true, minSelection: 1, maxSelection: 1, sortOrder: 0 }),
    );
    await options.insert([
      { groupId: term.id, name: 'Medio', price: 0, sortOrder: 0 },
      { groupId: term.id, name: 'Tres cuartos', price: 0, sortOrder: 1 },
      { groupId: term.id, name: 'Bien asado', price: 0, sortOrder: 2 },
    ]);
    const adds = await groups.save(
      groups.create({ productId: classic.id, title: 'Adiciones', isRequired: false, minSelection: 0, maxSelection: 3, sortOrder: 1 }),
    );
    await options.insert([
      { groupId: adds.id, name: 'Tocineta', price: 3000, sortOrder: 0 },
      { groupId: adds.id, name: 'Queso extra', price: 2500, sortOrder: 1 },
      { groupId: adds.id, name: 'Huevo', price: 2000, sortOrder: 2 },
    ]);
    console.log('  ✓ menú de prueba');
  }

  await upsertUser(ds, {
    email: 'admin@burgerhouse.com',
    password: 'Admin12345',
    fullName: 'Admin Burger House',
    role: Role.COMPANY_ADMIN,
    companyId: company.id,
  });
}

async function main() {
  const ds = new DataSource(buildDataSourceOptions());
  await ds.initialize();
  console.log('Conectado a la base de datos');

  console.log('Super admin:');
  await upsertUser(ds, {
    email: process.env.SUPERADMIN_EMAIL ?? 'superadmin@lacarta.app',
    password: process.env.SUPERADMIN_PASSWORD ?? 'CambiaEsto123',
    fullName: process.env.SUPERADMIN_NAME ?? 'Super Admin',
    role: Role.SUPER_ADMIN,
  });

  if (process.env.SEED_DEMO === 'true') {
    console.log('Datos de prueba:');
    await seedDemo(ds);
  }

  await ds.destroy();
  console.log('Listo ✔');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
