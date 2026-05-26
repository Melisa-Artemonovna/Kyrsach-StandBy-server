using Microsoft.EntityFrameworkCore;
using Kourse_project_BD_vav.Models;

namespace Kourse_project_BD_vav.Data
{
    public class PgDbContext : DbContext
    {
        public PgDbContext(DbContextOptions<PgDbContext> options) : base(options)
        {
        }

        // Таблица пользователей
        public DbSet<User> Users { get; set; } = null!;

        // Основные таблицы
        public DbSet<Client> Clients { get; set; } = null!;
        public DbSet<Realtor> Realtors { get; set; } = null!;
        public DbSet<Property> Properties { get; set; } = null!;
        public DbSet<Deal> Deals { get; set; } = null!;
        public DbSet<Contract> Contracts { get; set; } = null!;

        // Дополнительные таблицы
        public DbSet<PropertyReservation> PropertyReservations { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // PostgreSQL настройки
            modelBuilder.HasDefaultSchema("public");

            // Users
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(u => u.user_id);
                entity.ToTable("users");
                entity.Property(u => u.username).HasMaxLength(50).IsRequired();
                entity.Property(u => u.password_hash).HasMaxLength(255).IsRequired();
                entity.Property(u => u.email).HasMaxLength(100).IsRequired();
                entity.Property(u => u.full_name).HasMaxLength(100).IsRequired();
                entity.Property(u => u.role).HasMaxLength(20).IsRequired();
                entity.Property(u => u.created_at).HasDefaultValueSql("CURRENT_TIMESTAMP");

                entity.HasIndex(u => u.username).IsUnique();
                entity.HasIndex(u => u.email).IsUnique();
            });

            // Clients
            modelBuilder.Entity<Client>(entity =>
            {
                entity.HasKey(c => c.client_id);
                entity.ToTable("clients");
                entity.Property(c => c.full_name).HasMaxLength(100).IsRequired();
                entity.Property(c => c.phone_number).HasMaxLength(20);
                entity.Property(c => c.email).HasMaxLength(100);
                entity.Property(c => c.passport_number).HasMaxLength(20);
                entity.Property(c => c.registration_date).HasDefaultValueSql("CURRENT_DATE");
            });

            // Realtors
            modelBuilder.Entity<Realtor>(entity =>
            {
                entity.HasKey(r => r.realtor_id);
                entity.ToTable("realtors");
                entity.Property(r => r.full_name).HasMaxLength(100).IsRequired();
                entity.Property(r => r.phone_number).HasMaxLength(20);
                entity.Property(r => r.email).HasMaxLength(100);
                entity.Property(r => r.commission_rate).HasPrecision(5, 2);
                entity.Property(r => r.hire_date).HasDefaultValueSql("CURRENT_DATE");
            });

            // Properties
            modelBuilder.Entity<Property>(entity =>
            {
                entity.HasKey(p => p.property_id);
                entity.ToTable("properties");
                entity.Property(p => p.address).HasMaxLength(255).IsRequired();
                entity.Property(p => p.property_type).HasMaxLength(50).IsRequired(false);
                entity.Property(p => p.area).HasPrecision(10, 2);
                entity.Property(p => p.price).HasPrecision(15, 2);
                entity.Property(p => p.description).HasColumnType("text").IsRequired(false);
                // Новые поля для картинок
                entity.Property(p => p.main_image_url).HasMaxLength(500).IsRequired(false);
                entity.Property(p => p.image_urls).HasColumnType("text").IsRequired(false);
                entity.Property(p => p.is_available).HasDefaultValue(true);
            });

            // Deals
            modelBuilder.Entity<Deal>(entity =>
            {
                entity.HasKey(d => d.deal_id);
                entity.ToTable("deals");
                entity.Property(d => d.deal_type).HasMaxLength(50).IsRequired(false);
                entity.Property(d => d.deal_status).HasMaxLength(50).IsRequired(false);
                entity.Property(d => d.deal_price).HasPrecision(15, 2);
            });

            // Contracts
            modelBuilder.Entity<Contract>(entity =>
            {
                entity.HasKey(c => c.contract_id);
                entity.ToTable("contracts");
                entity.Property(c => c.contract_file).HasMaxLength(255);
                entity.Property(c => c.notes).HasColumnType("text");
            });

            // PropertyReservations
            modelBuilder.Entity<PropertyReservation>(entity =>
            {
                entity.HasKey(pr => pr.reservation_id);
                entity.ToTable("propertyreservations");
                entity.Property(pr => pr.status).HasMaxLength(20).HasDefaultValue("Active");
                entity.Property(pr => pr.reservation_date).HasDefaultValueSql("CURRENT_TIMESTAMP");
                entity.Property(pr => pr.expiry_date).IsRequired();
                entity.Property(pr => pr.realtor_id).IsRequired();
                
                // Настройка связей - явно указываем внешние ключи
                entity.HasOne(pr => pr.Property)
                    .WithMany()
                    .HasForeignKey(pr => pr.property_id)
                    .IsRequired()
                    .OnDelete(DeleteBehavior.Restrict);
                
                entity.HasOne(pr => pr.Client)
                    .WithMany(c => c.Reservations)
                    .HasForeignKey(pr => pr.client_id)
                    .IsRequired()
                    .OnDelete(DeleteBehavior.Restrict);
                
                entity.HasOne(pr => pr.Realtor)
                    .WithMany(r => r.Reservations)
                    .HasForeignKey(pr => pr.realtor_id)
                    .IsRequired()
                    .OnDelete(DeleteBehavior.Restrict);
            });

            base.OnModelCreating(modelBuilder);
        }
    }
}