using Infraestructura.Data;
using Aplicacion;
using GestionAlquileres.Security;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);
var mobileRequireHttps = builder.Configuration.GetValue<bool?>("FlotaMobile:RequireHttps") ?? false;

// Add services to the container.
builder.Services.AddControllersWithViews();
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.KnownNetworks.Clear();
    options.KnownProxies.Clear();
});
builder.Services.AddAuthentication(FlotaMobileAuth.Scheme)
    .AddCookie(FlotaMobileAuth.Scheme, options =>
    {
        options.Cookie.Name = "Flota.Mobile.Auth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.Cookie.SecurePolicy = CookieSecurePolicy.SameAsRequest;
        options.LoginPath = "/Flota/MobileLogin";
        options.ExpireTimeSpan = TimeSpan.FromDays(30);
        options.SlidingExpiration = true;
    });

builder.Services.Configure<SqlConfig>(builder.Configuration.GetSection("SqlConfig"));
builder.Services.AddConfigAplicacionDI();


var app = builder.Build();
app.UseForwardedHeaders();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment() && mobileRequireHttps)
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}
else if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
}

if (mobileRequireHttps)
{
    app.UseHttpsRedirection();
}
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
