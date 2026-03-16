using Aplicacion.Interfaces;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using Infraestructura.Interfaces;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Aplicacion.CasosUso
{
    public class PrestamoService:IPrestamoService
    {
        private readonly IPrestamoRepository _repo;
        private readonly ILogger<PrestamoService> _logger;

        public PrestamoService(
           IPrestamoRepository repo,
           ILogger<PrestamoService> logger)
        {
            _repo = repo;
            _logger = logger;
        }

        public async Task<JsonResponse<List<PrestamoListDto>>> ListarAsync(CancellationToken cancellationToken)
        {
            var res = new JsonResponse<List<PrestamoListDto>>();

            try
            {
                var lista = await _repo.ListarAsync(cancellationToken);

                res.Success = true;
                res.Mensaje = "Listado de préstamos obtenido correctamente.";
                res.Data = lista;

                _logger.LogInformation("Listado de préstamos obtenido correctamente. Total: {Total}", lista.Count);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al listar préstamos", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al listar préstamos. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }



        public async Task<JsonResponse<List<ClienteAnexoSelectDto>>> BuscarClientesAsync(string texto, CancellationToken cancellationToken)
        {
            var res = new JsonResponse<List<ClienteAnexoSelectDto>>();

            try
            {
                var lista = await _repo.BuscarClientesAsync(texto, cancellationToken);

                res.Success = true;
                res.Mensaje = "Clientes obtenidos correctamente.";
                res.Data = lista;
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al buscar clientes", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al buscar clientes. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

        public async Task<JsonResponse<PrestamoSimulacionDto>> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken)
        {
            var res = new JsonResponse<PrestamoSimulacionDto>();

            try
            {
                if (request.Capital <= 0)
                {
                    res.Success = false;
                    res.Mensaje = "El capital debe ser mayor a cero.";
                    res.Errors.Add("Capital|El capital debe ser mayor a cero.");
                    return res;
                }

                if (request.FechaFinCobro < request.FechaInicioCobro)
                {
                    res.Success = false;
                    res.Mensaje = "La fecha fin debe ser mayor o igual a la fecha inicio.";
                    res.Errors.Add("FechaFinCobro|La fecha fin debe ser mayor o igual a la fecha inicio.");
                    return res;
                }

                var sim = await _repo.SimularAsync(request, cancellationToken);

                res.Success = sim?.Ok ?? false;
                res.Mensaje = sim?.Mensaje ?? "No se pudo simular.";
                res.Data = sim;

                if (!(sim?.Ok ?? false))
                    res.Errors.Add(res.Mensaje);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al simular préstamo", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al simular el préstamo. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

        public async Task<JsonResponse<DbActionResult>> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken)
        {
            var res = new JsonResponse<DbActionResult>();

            try
            {
                if (string.IsNullOrWhiteSpace(request.Cod_Anxo))
                {
                    res.Success = false;
                    res.Mensaje = "Debe seleccionar un cliente.";
                    res.Errors.Add("Cod_Anxo|Debe seleccionar un cliente.");
                    return res;
                }

                if (request.Capital <= 0)
                {
                    res.Success = false;
                    res.Mensaje = "El capital debe ser mayor a cero.";
                    res.Errors.Add("Capital|El capital debe ser mayor a cero.");
                    return res;
                }

                if (request.FechaFinCobro < request.FechaInicioCobro)
                {
                    res.Success = false;
                    res.Mensaje = "La fecha fin debe ser mayor o igual a la fecha inicio.";
                    res.Errors.Add("FechaFinCobro|La fecha fin debe ser mayor o igual a la fecha inicio.");
                    return res;
                }

                var result = await _repo.GuardarAsync(request, usuario, cancellationToken);

                res.Success = result.Ok;
                res.Mensaje = result.Mensaje;
                res.Data = result;

                if (!result.Ok)
                    res.Errors.Add(result.Mensaje);

                _logger.LogInformation("Préstamo guardado correctamente. IdPrestamo: {IdPrestamo}", result.IdGenerado);
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al guardar préstamo", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al guardar el préstamo. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

        public async Task<JsonResponse<List<AlmacenSelectDto>>> ListarAlmacenesAsync(CancellationToken cancellationToken)
        {
            var res = new JsonResponse<List<AlmacenSelectDto>>();

            try
            {
                var lista = await _repo.ListarAlmacenesAsync(cancellationToken);

                res.Success = true;
                res.Mensaje = "Almacenes obtenidos correctamente.";
                res.Data = lista;
            }
            catch (Exception ex)
            {
                var errorId = Guid.NewGuid();
                _logger.LogError(ex, "ErrorId: {ErrorId} - Error al listar almacenes", errorId);

                res.Success = false;
                res.Mensaje = $"Ocurrió un error al listar almacenes. ErrorId: {errorId}";
                res.Errors.Add(ex.Message);
            }

            return res;
        }

    }
}
