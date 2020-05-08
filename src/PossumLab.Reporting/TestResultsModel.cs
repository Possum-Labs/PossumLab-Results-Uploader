using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace PossumLab.Reporting
{
    //https://docs.microsoft.com/en-us/ef/core/get-started/?tabs=visual-studio

    public class ResultsContext : DbContext
    {
        public ResultsContext()
        {
            ConnectionString = GetEnvironmentVariable("pl_reporting_db");
        }

        public ResultsContext(string connectionString)
        {
            ConnectionString = connectionString;
        }

        public static string GetEnvironmentVariable(string name)
        {
            return name + ": " +
                System.Environment.GetEnvironmentVariable(name, EnvironmentVariableTarget.Process);
        }

        public string ConnectionString { get; }
        public DbSet<Repo> Repos { get; set; }

        public DbSet<Process> Processes { get; set; }
        public DbSet<Run> Runs { get; set; }
        protected override void OnConfiguring(DbContextOptionsBuilder options)
            => options.UseSqlServer(
                "Server=tcp:possum-lab-reporting.database.windows.net,1433;" +
                "Initial Catalog=PossumLabReporting;" +
                "Persist Security Info=False;" +
                "User ID=possumadmin;" +
                "Password=9mBQt8X25E#4PRwx;" +
                "MultipleActiveResultSets=False;" +
                "Encrypt=True;TrustServerCertificate=False;" +
                "Connection Timeout=30;").EnableDetailedErrors();
    }

    public class Repo
    {
        [Key]
        public int RepoId { get; set; }
        public string Url { get; set; }
        public string ApiKey { get; set; }
        public ICollection<Process> Processes { get; } = new List<Process>();
    }

    public class Process
    {
        [Key]
        public int ProcessId { get; set; }

        [ForeignKey("Repo")]
        public int RepoId { get; set; }
        public Repo Repo { get; set; }

        public string Name { get; set; }
        public string Url { get; set; }
        public string ProcessType { get; set; }
        public ICollection<Run> Runs { get; } = new List<Run>();
    }
    public class Run
    {
        [Key]
        public int RunId { get; set; }

        [ForeignKey("Process")]
        public int ProcessId { get; set; }
        public Process Process { get; set; }
        public string ExternalId { get; set; }
        public string Name { get; set; }

        [DatabaseGenerated(DatabaseGeneratedOption.Computed)]
        public DateTime Created { get; set; }
    }
}
