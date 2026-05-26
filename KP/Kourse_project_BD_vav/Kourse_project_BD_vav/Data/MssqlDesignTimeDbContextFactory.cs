using Kourse_project_BD_vav.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

public class MssqlDesignTimeDbContextFactory : IDesignTimeDbContextFactory<MssqlDbContext>
{
    public MssqlDbContext CreateDbContext(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json")
            .Build();

        var optionsBuilder = new DbContextOptionsBuilder<MssqlDbContext>();
        optionsBuilder.UseSqlServer(configuration.GetConnectionString("MssqlConnection"));

        return new MssqlDbContext(optionsBuilder.Options);
    }
}