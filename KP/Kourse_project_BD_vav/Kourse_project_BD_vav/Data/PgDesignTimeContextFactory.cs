using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Kourse_project_BD_vav.Data
{
    public class PgDesignTimeDbContextFactory : IDesignTimeDbContextFactory<PgDbContext>
    {
        public PgDbContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<PgDbContext>();
            optionsBuilder.UseNpgsql("Host=localhost;Database=kursovoy_project_VAV;Username=postgres;Password=qwer12;");
            return new PgDbContext(optionsBuilder.Options);
        }
    }
}