using Aplicacion.Common;
using Aplicacion.Interfaces;
using Dominio.DTO.Cobranza;
using Infraestructura.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.CasosUso
{
    public class CobranzaService:ICobranzaService
    {
        private readonly ICobranzaRepository _repo;
        private readonly ILogger<CobranzaService> _logger;

        public CobranzaService(
            ICobranzaRepository repo,
            ILogger<CobranzaService> logger)
        {
            _repo = repo;
            _logger = logger;
        }

        public async Task<JsonResponse<CobranzaResumenDto>> ObtenerResumenAsync(CancellationToken cancellationToken)
        {
            var res = new JsonResponse<CobranzaResumenDto>();

            try
            {
                var item = await _repo.ObtenerResumenAsync(cancellationToken);

                res.Success = true;
                res.Mensaje = "Resumen obtenido correctamente.";
                res.Data = item ?? new CobranzaResumenDto();

                _logger.LogInformation("Resumen de cobranza obtenido correctamente.");
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();

                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al obtener resumen de cobranza.", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al obtener el resumen. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

        public async Task<JsonResponse<List<CobranzaPendienteDto>>> ListarPrestamosPendientesAsync(CancellationToken cancellationToken)
        {
            return await EjecutarListaAsync(() => _repo.ListarPrestamosPendientesAsync(cancellationToken),"préstamos pendientes");
        }

        public async Task<JsonResponse<List<CobranzaPendienteDto>>> ListarAlquileresPendientesAsync(CancellationToken cancellationToken)
        {
            return await EjecutarListaAsync(() => _repo.ListarAlquileresPendientesAsync(cancellationToken),"alquileres pendientes");
        }

        public async Task<JsonResponse<List<CobranzaPendienteDto>>> ListarRentasPorVencerAsync(CancellationToken cancellationToken)
        {
            return await EjecutarListaAsync(() => _repo.ListarRentasPorVencerAsync(cancellationToken),"rentas por vencer");
        }

        private async Task<JsonResponse<List<CobranzaPendienteDto>>> EjecutarListaAsync(
            Func<Task<List<CobranzaPendienteDto>>> accion,
            string modulo)
        {
            var res = new JsonResponse<List<CobranzaPendienteDto>>();

            try
            {
                var lista = await accion();
                res.Success = true;
                res.Mensaje = $"Listado de {modulo} obtenido correctamente.";
                res.Data = lista;

                _logger.LogInformation("Listado de {Modulo} obtenido correctamente. Total: {Total}", modulo, lista.Count);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();

                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al obtener {Modulo}", errorId, modulo);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al obtener {modulo}. ErrorId: {errorId}";
                res.Errors.Add("Nro error:"+errorId);
            }

            return res;
        }
    }
}

