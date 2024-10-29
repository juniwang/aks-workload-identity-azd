using Azure.Core;
using Azure.Identity;
using Microsoft.Extensions.Options;

namespace TestApp
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var builder = WebApplication.CreateBuilder(args);
            builder.Configuration.AddAzureAppConfiguration(options =>
            {
                Uri endpoint = new Uri(Environment.GetEnvironmentVariable("StoreEndpoint") ?? throw new ArgumentNullException("StoreEndpoint"));
                TokenCredential credential = new WorkloadIdentityCredential();
                options.Connect(endpoint, credential);
            });
            builder.Services.Configure<Settings>(builder.Configuration.GetSection("TestApp:Settings"));

            var app = builder.Build();

            app.MapGet("/", () => app.Services.GetRequiredService<IOptions<Settings>>().Value.Message);

            app.Run();
        }
    }
}

