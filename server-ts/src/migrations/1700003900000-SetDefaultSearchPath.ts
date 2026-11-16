import type { MigrationInterface, QueryRunner } from "typeorm";

/** Ports db/load_all.sql's trailing step: make the regs schema visible without a prefix on new connections. */
export class SetDefaultSearchPath1700003900000 implements MigrationInterface {
  name = "SetDefaultSearchPath1700003900000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    const db = await queryRunner.query("SELECT current_database() AS db");
    await queryRunner.query(`ALTER DATABASE "${db[0].db}" SET search_path = regs, public`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    const db = await queryRunner.query("SELECT current_database() AS db");
    await queryRunner.query(`ALTER DATABASE "${db[0].db}" SET search_path = public`);
  }
}
