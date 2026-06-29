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
            services.AddScoped<IFormaPagoService, FormaPagoService>();
            services.AddScoped<ICajaService, CajaService>();
            services.AddScoped<ICajaRepository, CajaRepository>();
            services.AddScoped<IFormaPagoRepository, FormaPagoRepository>();
            services.AddScoped<IReporteService, ReporteService>();
            services.AddScoped<IReporteRepository, ReporteRepository>();
            services.AddScoped<IYapeImportacionService, YapeImportacionService>();
            services.AddScoped<IYapeImportacionRepository, YapeImportacionRepository>();
            services.AddScoped<IRefinanciamientoService, RefinanciamientoService>();
            services.AddScoped<IRefinanciamientoRepository, RefinanciamientoRepository>();
            services.AddScoped<ICompensacionService, CompensacionService>();
            services.AddScoped<ICompensacionRepository, CompensacionRepository>();
            services.AddScoped<IFlotaService, FlotaService>();
            services.AddScoped<IFlotaRepository, FlotaRepository>();
            return services;
        }
    }
}
