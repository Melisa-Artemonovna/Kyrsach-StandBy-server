using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Kourse_project_BD_vav.Migrations.Pg
{
    /// <inheritdoc />
    public partial class InitialCreate_Pg : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "public");

            migrationBuilder.CreateTable(
                name: "clients",
                schema: "public",
                columns: table => new
                {
                    client_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    full_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    phone_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    email = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    passport_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    registration_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_DATE"),
                    user_id = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_clients", x => x.client_id);
                });

            migrationBuilder.CreateTable(
                name: "contracts",
                schema: "public",
                columns: table => new
                {
                    contract_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    deal_id = table.Column<int>(type: "integer", nullable: false),
                    contract_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    contract_file = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    notes = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_contracts", x => x.contract_id);
                });

            migrationBuilder.CreateTable(
                name: "favorites",
                schema: "public",
                columns: table => new
                {
                    favorite_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    property_id = table.Column<int>(type: "integer", nullable: false),
                    added_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    added_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_favorites", x => x.favorite_id);
                });

            migrationBuilder.CreateTable(
                name: "properties",
                schema: "public",
                columns: table => new
                {
                    property_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    address = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    property_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    area = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    price = table.Column<decimal>(type: "numeric(15,2)", precision: 15, scale: 2, nullable: false),
                    description = table.Column<string>(type: "text", nullable: false),
                    realtor_id = table.Column<int>(type: "integer", nullable: true),
                    is_available = table.Column<bool>(type: "boolean", nullable: false),
                    main_image_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    image_urls = table.Column<string>(type: "text", nullable: true),
                    rooms = table.Column<int>(type: "integer", nullable: true),
                    floor = table.Column<int>(type: "integer", nullable: true),
                    total_floors = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_properties", x => x.property_id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                schema: "public",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    username = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    password_hash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    email = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    full_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    client_id = table.Column<int>(type: "integer", nullable: true),
                    realtor_id = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_users", x => x.user_id);
                });

            migrationBuilder.CreateTable(
                name: "realtors",
                schema: "public",
                columns: table => new
                {
                    realtor_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    full_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    phone_number = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    email = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    hire_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_DATE"),
                    commission_rate = table.Column<decimal>(type: "numeric(5,2)", precision: 5, scale: 2, nullable: false),
                    user_id = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_realtors", x => x.realtor_id);
                    table.ForeignKey(
                        name: "FK_realtors_users_user_id",
                        column: x => x.user_id,
                        principalSchema: "public",
                        principalTable: "users",
                        principalColumn: "user_id");
                });

            migrationBuilder.CreateTable(
                name: "deals",
                schema: "public",
                columns: table => new
                {
                    deal_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    property_id = table.Column<int>(type: "integer", nullable: false),
                    client_id = table.Column<int>(type: "integer", nullable: false),
                    realtor_id = table.Column<int>(type: "integer", nullable: true),
                    deal_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    deal_status = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    deal_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    deal_price = table.Column<decimal>(type: "numeric(15,2)", precision: 15, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_deals", x => x.deal_id);
                    table.ForeignKey(
                        name: "FK_deals_clients_client_id",
                        column: x => x.client_id,
                        principalSchema: "public",
                        principalTable: "clients",
                        principalColumn: "client_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_deals_properties_property_id",
                        column: x => x.property_id,
                        principalSchema: "public",
                        principalTable: "properties",
                        principalColumn: "property_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_deals_realtors_realtor_id",
                        column: x => x.realtor_id,
                        principalSchema: "public",
                        principalTable: "realtors",
                        principalColumn: "realtor_id");
                });

            migrationBuilder.CreateIndex(
                name: "IX_deals_client_id",
                schema: "public",
                table: "deals",
                column: "client_id");

            migrationBuilder.CreateIndex(
                name: "IX_deals_property_id",
                schema: "public",
                table: "deals",
                column: "property_id");

            migrationBuilder.CreateIndex(
                name: "IX_deals_realtor_id",
                schema: "public",
                table: "deals",
                column: "realtor_id");

            migrationBuilder.CreateIndex(
                name: "IX_realtors_user_id",
                schema: "public",
                table: "realtors",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_users_email",
                schema: "public",
                table: "users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_username",
                schema: "public",
                table: "users",
                column: "username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "contracts",
                schema: "public");

            migrationBuilder.DropTable(
                name: "deals",
                schema: "public");

            migrationBuilder.DropTable(
                name: "favorites",
                schema: "public");

            migrationBuilder.DropTable(
                name: "clients",
                schema: "public");

            migrationBuilder.DropTable(
                name: "properties",
                schema: "public");

            migrationBuilder.DropTable(
                name: "realtors",
                schema: "public");

            migrationBuilder.DropTable(
                name: "users",
                schema: "public");
        }
    }
}
