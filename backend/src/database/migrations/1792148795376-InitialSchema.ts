import { MigrationInterface, QueryRunner } from "typeorm";

export class InitialSchema1792148795376 implements MigrationInterface {
    name = 'InitialSchema1792148795376'

    public async up(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`CREATE TYPE "public"."user_role" AS ENUM('SUPER_ADMIN', 'COMPANY_ADMIN')`);
        await queryRunner.query(`CREATE TABLE "users" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "email" character varying(160) NOT NULL, "password_hash" character varying NOT NULL, "full_name" character varying(120) NOT NULL, "role" "public"."user_role" NOT NULL, "company_id" uuid, "is_active" boolean NOT NULL DEFAULT true, "last_login_at" TIMESTAMP WITH TIME ZONE, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_a3ffb1c0c8416b9fc6f907b7433" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE UNIQUE INDEX "IDX_97672ac88f789774dd47f7c8be" ON "users" ("email") `);
        await queryRunner.query(`CREATE TABLE "business_hours" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "company_id" uuid NOT NULL, "day_of_week" smallint NOT NULL, "open_time" character varying(5) NOT NULL DEFAULT '00:00', "close_time" character varying(5) NOT NULL DEFAULT '00:00', "closed" boolean NOT NULL DEFAULT false, CONSTRAINT "UQ_5c32f982e24bf0a940c27442396" UNIQUE ("company_id", "day_of_week"), CONSTRAINT "PK_560a76077605005da835fe505a5" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "companies" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "name" character varying(120) NOT NULL, "slug" character varying(80) NOT NULL, "tax_id" character varying(40), "phone" character varying(30), "whatsapp_phone" character varying(30), "email" character varying(160), "address" character varying(255), "latitude" double precision, "longitude" double precision, "logo_url" character varying(500), "cover_url" character varying(500), "primary_color" character varying(9), "timezone" character varying(60) NOT NULL DEFAULT 'America/Bogota', "accepts_cash" boolean NOT NULL DEFAULT true, "accepts_transfer" boolean NOT NULL DEFAULT false, "bre_bkey" character varying(80), "payment_holder" character varying(120), "payment_qr_url" character varying(500), "payment_notes" text, "is_active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_d4bc3e82a314fa9e29f652c2c22" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE UNIQUE INDEX "IDX_b28b07d25e4324eee577de5496" ON "companies" ("slug") `);
        await queryRunner.query(`CREATE TABLE "categories" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "company_id" uuid NOT NULL, "name" character varying(100) NOT NULL, "description" text, "image_url" character varying(500), "sort_order" integer NOT NULL DEFAULT '0', "is_active" boolean NOT NULL DEFAULT true, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_24dbc6126a28ff948da33e97d3b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_b050c07f008b7997355d4bd16a" ON "categories" ("company_id", "sort_order") `);
        await queryRunner.query(`CREATE TABLE "extra_options" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "group_id" uuid NOT NULL, "name" character varying(100) NOT NULL, "price" numeric(12,2) NOT NULL DEFAULT '0', "is_active" boolean NOT NULL DEFAULT true, "sort_order" integer NOT NULL DEFAULT '0', CONSTRAINT "PK_b1e10a1152b3e21096a7b4be7a8" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "extra_groups" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "product_id" uuid NOT NULL, "title" character varying(100) NOT NULL, "is_required" boolean NOT NULL DEFAULT false, "min_selection" integer NOT NULL DEFAULT '0', "max_selection" integer NOT NULL DEFAULT '1', "sort_order" integer NOT NULL DEFAULT '0', CONSTRAINT "PK_32d43b0a5f988a06651883eea57" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TABLE "products" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "company_id" uuid NOT NULL, "category_id" uuid NOT NULL, "name" character varying(150) NOT NULL, "description" text NOT NULL DEFAULT '', "base_price" numeric(12,2) NOT NULL, "image_urls" text array NOT NULL DEFAULT '{}', "is_available" boolean NOT NULL DEFAULT true, "sort_order" integer NOT NULL DEFAULT '0', "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "PK_0806c755e0aca124e67c0cf6d7d" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_416f1b5b9e026913bf5b2a95a5" ON "products" ("company_id", "category_id") `);
        await queryRunner.query(`CREATE TABLE "order_item_extras" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "order_item_id" uuid NOT NULL, "option_id" uuid, "group_title" character varying(100) NOT NULL, "option_name" character varying(100) NOT NULL, "unit_price" numeric(12,2) NOT NULL, "quantity" integer NOT NULL DEFAULT '1', CONSTRAINT "PK_1d9ad4d7e5da987f8f20e7f8b6b" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE TYPE "public"."order_status" AS ENUM('pending', 'confirmed', 'preparing', 'ready', 'delivered', 'cancelled')`);
        await queryRunner.query(`CREATE TYPE "public"."order_type" AS ENUM('dine_in', 'takeaway', 'delivery')`);
        await queryRunner.query(`CREATE TYPE "public"."payment_method" AS ENUM('cash', 'transfer')`);
        await queryRunner.query(`CREATE TABLE "orders" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "company_id" uuid NOT NULL, "order_number" integer NOT NULL, "status" "public"."order_status" NOT NULL DEFAULT 'pending', "type" "public"."order_type" NOT NULL, "customer_name" character varying(120) NOT NULL, "phone" character varying(30), "address" character varying(255), "table_number" character varying(20), "notes" text, "payment_method" "public"."payment_method" NOT NULL DEFAULT 'cash', "payment_proof_url" character varying(500), "proof_token" character varying(64), "total" numeric(12,2) NOT NULL, "created_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), "updated_at" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(), CONSTRAINT "UQ_d95ebf731e4f442488d77d20f2d" UNIQUE ("company_id", "order_number"), CONSTRAINT "PK_710e2d4957aa5878dfe94e4ac2f" PRIMARY KEY ("id"))`);
        await queryRunner.query(`CREATE INDEX "IDX_1d2ed27b498dce90eff79ed992" ON "orders" ("company_id", "created_at") `);
        await queryRunner.query(`CREATE TABLE "order_items" ("id" uuid NOT NULL DEFAULT uuid_generate_v4(), "order_id" uuid NOT NULL, "product_id" uuid, "product_name" character varying(150) NOT NULL, "unit_price" numeric(12,2) NOT NULL, "quantity" integer NOT NULL, "extras_total" numeric(12,2) NOT NULL, "line_total" numeric(12,2) NOT NULL, "comment" text, CONSTRAINT "PK_005269d8574e6fac0493715c308" PRIMARY KEY ("id"))`);
        await queryRunner.query(`ALTER TABLE "users" ADD CONSTRAINT "FK_7ae6334059289559722437bcc1c" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "business_hours" ADD CONSTRAINT "FK_959dfc391d26065eea66dd57a01" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "categories" ADD CONSTRAINT "FK_987f987126a3f2e4f9ec03db04e" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "extra_options" ADD CONSTRAINT "FK_0224d5e942ddba71cd223018a50" FOREIGN KEY ("group_id") REFERENCES "extra_groups"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "extra_groups" ADD CONSTRAINT "FK_c9c2ef53293b36e1355844d566d" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "products" ADD CONSTRAINT "FK_b417f1726f6ccafb18730adffb0" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "products" ADD CONSTRAINT "FK_9a5f6868c96e0069e699f33e124" FOREIGN KEY ("category_id") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "order_item_extras" ADD CONSTRAINT "FK_aacb138279f83d4f9ae082c1547" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "orders" ADD CONSTRAINT "FK_f5d519a61e918f7efb299de31a0" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "order_items" ADD CONSTRAINT "FK_145532db85752b29c57d2b7b1f1" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE NO ACTION`);
        await queryRunner.query(`ALTER TABLE "order_items" ADD CONSTRAINT "FK_9263386c35b6b242540f9493b00" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE SET NULL ON UPDATE NO ACTION`);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`ALTER TABLE "order_items" DROP CONSTRAINT "FK_9263386c35b6b242540f9493b00"`);
        await queryRunner.query(`ALTER TABLE "order_items" DROP CONSTRAINT "FK_145532db85752b29c57d2b7b1f1"`);
        await queryRunner.query(`ALTER TABLE "orders" DROP CONSTRAINT "FK_f5d519a61e918f7efb299de31a0"`);
        await queryRunner.query(`ALTER TABLE "order_item_extras" DROP CONSTRAINT "FK_aacb138279f83d4f9ae082c1547"`);
        await queryRunner.query(`ALTER TABLE "products" DROP CONSTRAINT "FK_9a5f6868c96e0069e699f33e124"`);
        await queryRunner.query(`ALTER TABLE "products" DROP CONSTRAINT "FK_b417f1726f6ccafb18730adffb0"`);
        await queryRunner.query(`ALTER TABLE "extra_groups" DROP CONSTRAINT "FK_c9c2ef53293b36e1355844d566d"`);
        await queryRunner.query(`ALTER TABLE "extra_options" DROP CONSTRAINT "FK_0224d5e942ddba71cd223018a50"`);
        await queryRunner.query(`ALTER TABLE "categories" DROP CONSTRAINT "FK_987f987126a3f2e4f9ec03db04e"`);
        await queryRunner.query(`ALTER TABLE "business_hours" DROP CONSTRAINT "FK_959dfc391d26065eea66dd57a01"`);
        await queryRunner.query(`ALTER TABLE "users" DROP CONSTRAINT "FK_7ae6334059289559722437bcc1c"`);
        await queryRunner.query(`DROP TABLE "order_items"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_1d2ed27b498dce90eff79ed992"`);
        await queryRunner.query(`DROP TABLE "orders"`);
        await queryRunner.query(`DROP TYPE "public"."payment_method"`);
        await queryRunner.query(`DROP TYPE "public"."order_type"`);
        await queryRunner.query(`DROP TYPE "public"."order_status"`);
        await queryRunner.query(`DROP TABLE "order_item_extras"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_416f1b5b9e026913bf5b2a95a5"`);
        await queryRunner.query(`DROP TABLE "products"`);
        await queryRunner.query(`DROP TABLE "extra_groups"`);
        await queryRunner.query(`DROP TABLE "extra_options"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_b050c07f008b7997355d4bd16a"`);
        await queryRunner.query(`DROP TABLE "categories"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_b28b07d25e4324eee577de5496"`);
        await queryRunner.query(`DROP TABLE "companies"`);
        await queryRunner.query(`DROP TABLE "business_hours"`);
        await queryRunner.query(`DROP INDEX "public"."IDX_97672ac88f789774dd47f7c8be"`);
        await queryRunner.query(`DROP TABLE "users"`);
        await queryRunner.query(`DROP TYPE "public"."user_role"`);
    }

}
