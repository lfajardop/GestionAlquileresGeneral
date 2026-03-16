using Aplicacion.CasosUso;
using Aplicacion.Interfaces;
using Infraestructura.Interfaces;
using Infraestructura.Repositorio;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion
{
    public static class DIConfigurationAplicacion
    {
        public static IServiceCollection AddConfigAplicacionDI(this IServiceCollection services)
        {

            services.AddScoped<ICobranzaService, CobranzaService>();
            services.AddScoped<ICobranzaRepository, CobranzaRepository>();
            services.AddScoped<IPrestamoRepository, PrestamoRepository>();
            services.AddScoped<IPrestamoService, PrestamoService>();
            return services;
        }
    }
}
