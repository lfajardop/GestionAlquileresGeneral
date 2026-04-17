using Aplicacion.Common;
using Aplicacion.Interfaces;
using Dominio.DTO.Common;
using Dominio.DTO.Prestamo;
using Infraestructura.Interfaces;
using Infraestructura.Repositorio;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
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

        public async Task<JsonResponseRequest<List<PrestamoListDto>>> ListarAsync(CancellationToken cancellationToken)
        {
            var res = new JsonResponseRequest<List<PrestamoListDto>>();

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



        public async Task<JsonResponseRequest<List<ClienteAnexoSelectDto>>> BuscarClientesAsync(string texto, CancellationToken cancellationToken)
        {
            var res = new JsonResponseRequest<List<ClienteAnexoSelectDto>>();

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

        public async Task<JsonResponseRequest<PrestamoSimulacionDto>> SimularAsync(PrestamoSimulacionRequestDto request, CancellationToken cancellationToken)
        {
            var res = new JsonResponseRequest<PrestamoSimulacionDto>();

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

        //public async Task<JsonResponse<DbActionResult>> GuardarAsync(PrestamoCreateRequestDto request, string usuario, CancellationToken cancellationToken)
        //{
        //    var res = new JsonResponse<DbActionResult>();

        //    try
        //    {
        //        if (string.IsNullOrWhiteSpace(request.Cod_Anxo))
        //        {
        //            res.Success = false;
        //            res.Mensaje = "Debe seleccionar un cliente.";
        //            res.Errors.Add("Cod_Anxo|Debe seleccionar un cliente.");
        //            return res;
        //        }

        //        if (request.Capital <= 0)
        //        {
        //            res.Success = false;
        //            res.Mensaje = "El capital debe ser mayor a cero.";
        //            res.Errors.Add("Capital|El capital debe ser mayor a cero.");
        //            return res;
        //        }

        //        if (request.FechaFinCobro < request.FechaInicioCobro)
        //        {
        //            res.Success = false;
        //            res.Mensaje = "La fecha fin debe ser mayor o igual a la fecha inicio.";
        //            res.Errors.Add("FechaFinCobro|La fecha fin debe ser mayor o igual a la fecha inicio.");
        //            return res;
        //        }

        //        var result = await _repo.GuardarAsync(request, usuario, cancellationToken);

        //        res.Success = result.Ok;
        //        res.Mensaje = result.Mensaje;
        //        res.Data = result;

        //        if (!result.Ok)
        //            res.Errors.Add(result.Mensaje);

        //        _logger.LogInformation("Préstamo guardado correctamente. IdPrestamo: {IdPrestamo}", result.IdGenerado);
        //    }
        //    catch (Exception ex)
        //    {
        //        var errorId = Guid.NewGuid();
        //        _logger.LogError(ex, "ErrorId: {ErrorId} - Error al guardar préstamo", errorId);

        //        res.Success = false;
        //        res.Mensaje = $"Ocurrió un error al guardar el préstamo. ErrorId: {errorId}";
        //        res.Errors.Add(ex.Message);
        //    }

        //    return res;
        //}

        public async Task<JsonResponseRequest<DbActionResult>> GuardarAsync(
    PrestamoCreateRequestDto request,
    string usuario,
    CancellationToken cancellationToken)
{
    var res = new JsonResponseRequest<DbActionResult>();

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
        if (string.IsNullOrWhiteSpace(request.Cod_Concepto))
        {
            res.Success = false;
            res.Mensaje = "Debe indicar el concepto del préstamo.";
            res.Errors.Add("Cod_Concepto|Debe indicar el concepto del préstamo.");
            return res;
        }
        if (string.IsNullOrWhiteSpace(request.Observacion))
        {
            res.Success = false;
            res.Mensaje = "Debe registrar las observaciones.";
            res.Errors.Add("Observacion|Debe registrar las observaciones.");
            return res;
        }

                if (request.FechaFinCobro < request.FechaInicioCobro)
        {
            res.Success = false;
            res.Mensaje = "La fecha fin debe ser mayor o igual a la fecha inicio.";
            res.Errors.Add("FechaFinCobro|La fecha fin debe ser mayor o igual a la fecha inicio.");
            return res;
        }

        if (request.TieneGarantia && string.IsNullOrWhiteSpace(request.TipoGarantia))
        {
            res.Success = false;
            res.Mensaje = "Debe indicar el tipo de garantía.";
            res.Errors.Add("TipoGarantia|Debe indicar el tipo de garantía.");
            return res;
        }


                var result = await _repo.GuardarAsync(request, usuario, cancellationToken);

        if (result == null)
        {
            res.Success = false;
            res.Mensaje = "No se obtuvo respuesta al guardar el préstamo.";
            res.Errors.Add("No se obtuvo respuesta del SP principal.");
            return res;
        }

        if (!result.Ok)
        {
            res.Success = false;
            res.Mensaje = result.Mensaje;
            res.Data = result;
            res.Errors.Add(result.Mensaje);
            return res;
        }

        // Si el préstamo se guardó bien y tiene garantía, registrar garantía
        if (request.TieneGarantia &&Convert.ToInt32( result.IdGenerado) > 0)
        {
            var resultGarantia = await _repo.InsertarGarantiaAsync(
                request,
                result.IdGenerado??0,
                cancellationToken);

            if (resultGarantia == null)
            {
                res.Success = false;
                res.Mensaje = "El préstamo se registró, pero no se obtuvo respuesta al registrar la garantía.";
                res.Data = result;
                res.Errors.Add("No se obtuvo respuesta del SP de garantía.");
                return res;
            }

            if (!resultGarantia.Ok)
            {
                res.Success = false;
                res.Mensaje = $"El préstamo se registró, pero ocurrió un problema al registrar la garantía: {resultGarantia.Mensaje}";
                res.Data = result;
                res.Errors.Add(resultGarantia.Mensaje);
                return res;
            }
        }

        res.Success = true;
        res.Mensaje = request.TieneGarantia
            ? "Préstamo y garantía registrados correctamente."
            : result.Mensaje;

        res.Data = result;

        _logger.LogInformation(
            "Préstamo guardado correctamente. IdPrestamo: {IdPrestamo}, TieneGarantia: {TieneGarantia}",
            result.IdGenerado,
            request.TieneGarantia);
    }
    catch (Exception ex)
    {
        var errorId = Guid.NewGuid();
        _logger.LogError(ex, "ErrorId: {ErrorId} - Error al guardar préstamo", errorId);

        res.Success = false;
        res.Mensaje = $"Ocurrió un error al guardar el préstamo. ErrorId: {errorId}";
        res.Errors.Add("Nro error:" + errorId);
    }

    return res;
}

        public async Task<JsonResponseRequest<List<AlmacenSelectDto>>> ListarAlmacenesAsync(CancellationToken cancellationToken)
        {
            var res = new JsonResponseRequest<List<AlmacenSelectDto>>();

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


        public async Task<List<PrestamoDesembolsoListadoDto>> ListarDesembolsosAsync(
    int idPrestamo,
    CancellationToken cancellationToken)
        {
            if (idPrestamo <= 0)
                throw new ArgumentException("El Id del préstamo debe ser mayor a cero.", nameof(idPrestamo));

            return await _repo.ListarDesembolsosAsync(idPrestamo, cancellationToken);
        }


public async Task<DbActionResult> RegistrarDesembolsoAsync(
    PrestamoRegistrarDesembolsoRequestDto request,
    string usuario,
    string? estacion,
    CancellationToken cancellationToken)
        {
            if (request is null)
                throw new ArgumentNullException(nameof(request));

            request.CodCajaChicaDesembolso = (request.CodCajaChicaDesembolso ?? string.Empty).Trim();


            request.GlosaDesembolso = (request.GlosaDesembolso ?? string.Empty).Trim();

            var errores = new List<string>();

            if (request.IdPrestamo <= 0)
                errores.Add("El préstamo es obligatorio.");

            if (string.IsNullOrWhiteSpace(request.CodCajaChicaDesembolso))
                errores.Add("La caja origen es obligatoria.");

            if (request.ImpDesembolso <= 0)
                errores.Add("El importe de desembolso debe ser mayor a cero.");

            if (request.FecDesembolso == default)
                errores.Add("La fecha de desembolso es obligatoria.");

            if (string.IsNullOrWhiteSpace(usuario))
                errores.Add("No se pudo identificar el usuario.");

            if (errores.Count > 0)
            {
                return new DbActionResult
                {
                    Ok = false,
                    Mensaje = string.Join(" ", errores)
                };
            }
            
            return await _repo.RegistrarDesembolsoAsync(
                request,
                usuario,
                estacion,
                cancellationToken);
        }

        public async Task<List<PrestamoPagoListadoDto>> ListarPagosAsync(
    int idPrestamo,
    CancellationToken cancellationToken)
        {
            if (idPrestamo <= 0)
                throw new ArgumentException("El IdPrestamo es obligatorio.", nameof(idPrestamo));

            return await _repo.ListarPagosAsync(idPrestamo, cancellationToken);
        }

        public async Task<DbActionResult> RegistrarPagoAsync(
    PrestamoRegistrarPagoRequestDto request,
    string usuario,
    string? estacion,
    CancellationToken cancellationToken)
        {
            if (request is null)
                throw new ArgumentNullException(nameof(request));

            var errores = new List<string>();

            if (request.IdPrestamo <= 0)
                errores.Add("El préstamo es obligatorio.");

            //if (string.IsNullOrWhiteSpace(request.NroCobranza))
            //    errores.Add("La cobranza es obligatoria.");

            if (request.FecPago == default)
                errores.Add("La fecha de pago es obligatoria.");

            if (request.IdFormaPago <= 0)
                errores.Add("La forma de pago es obligatoria.");

            if (string.IsNullOrWhiteSpace(request.CodCajaChica))
                errores.Add("La caja es obligatoria.");

            if (request.ImportePago <= 0)
                errores.Add("El importe de pago debe ser mayor a cero.");



            if (errores.Count > 0)
            {
                return new DbActionResult
                {
                    Ok = false,
                    Mensaje = string.Join(" ", errores)
                };
            }

            return await _repo.RegistrarPagoAsync(request, usuario, estacion, cancellationToken);
        }

        public async Task<List<PrestamoConceptoDto>> ListarConceptosAsync(CancellationToken cancellationToken)
        {
            return await _repo.ListarConceptosAsync(cancellationToken);
        }
        public async Task<JsonResponseRequest<PrestamoDetalleDto>> ObtenerDetalleAsync(int idPrestamo)
        {
            try
            {
                if (idPrestamo <= 0)
                {
                    return new JsonResponseRequest<PrestamoDetalleDto>
                    {
                        Success = false,
                        Mensaje = "Id inválido.",
                        Errors = new List<string> { "IdPrestamo|Id inválido." }
                    };
                }

                var it = await _repo.ObtenerDetalleAsync(idPrestamo, CancellationToken.None);

                if (it == null)
                {
                    return new JsonResponseRequest<PrestamoDetalleDto>
                    {
                        Success = false,
                        Mensaje = "No existe el préstamo.",
                        Errors = new List<string> { "IdPrestamo|No existe el préstamo." }
                    };
                }

                return new JsonResponseRequest<PrestamoDetalleDto>
                {
                    Success = true,
                    Data = it
                };
            }
            catch (Exception ex)
            {
                Guid errorId = Guid.NewGuid();
                _logger.LogError(ex, "Error ID: {ErrorId} - {Message}", errorId, ex.Message);

                return new JsonResponseRequest<PrestamoDetalleDto>
                {
                    Success = false,
                    Mensaje = $"Ocurrió un error al obtener el detalle. ErrorId: {errorId}",
                    Errors = new List<string> { ex.Message }
                };
            }
        }

        public async Task<JsonResponseRequest<PrestamoEdicionDto>> ObtenerEdicionAsync(int idPrestamo)
        {
            try
            {
                if (idPrestamo <= 0)
                {
                    return new JsonResponseRequest<PrestamoEdicionDto>
                    {
                        Success = false,
                        Mensaje = "Id inválido.",
                        Errors = new List<string> { "IdPrestamo|Id inválido." }
                    };
                }

                var it = await _repo.ObtenerEdicionAsync(idPrestamo, CancellationToken.None);
                if (it == null)
                {
                    return new JsonResponseRequest<PrestamoEdicionDto>
                    {
                        Success = false,
                        Mensaje = "No existe el préstamo.",
                        Errors = new List<string> { "IdPrestamo|No existe el préstamo." }
                    };
                }

                if (!it.PuedeEditar)
                {
                    return new JsonResponseRequest<PrestamoEdicionDto>
                    {
                        Success = false,
                        Mensaje = "El préstamo no se puede editar porque ya tiene pagos o desembolsos.",
                        Errors = new List<string> { "IdPrestamo|El préstamo ya tiene movimientos." },
                        Data = it
                    };
                }

                return new JsonResponseRequest<PrestamoEdicionDto>
                {
                    Success = true,
                    Data = it
                };
            }
            catch (Exception ex)
            {
                Guid errorId = Guid.NewGuid();
                _logger.LogError(ex, "Error ID: {ErrorId} - {Message}", errorId, ex.Message);

                return new JsonResponseRequest<PrestamoEdicionDto>
                {
                    Success = false,
                    Mensaje = $"Ocurrió un error al obtener el préstamo para edición. ErrorId: {errorId}",
                    Errors = new List<string> { ex.Message }
                };
            }
        }
    }
}
