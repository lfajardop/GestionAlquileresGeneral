using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoDetalleCabeceraDto
    {
        public int IdPrestamo { get; set; }
        public DateTime Fecha { get; set; }
        public decimal Capital { get; set; }
        public int NroCuotas { get; set; }
        public decimal PorcInteresMensual { get; set; }
        public decimal TotalCobrar { get; set; }
        public string CodConcepto { get; set; } = string.Empty;
        public string NombreConcepto { get; set; } = string.Empty;
        public string ConceptoMostrar { get; set; } = string.Empty;
        public string Observacion { get; set; } = string.Empty;
        public decimal TotalDesembolsado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal SaldoPendiente { get; set; }
    }

    public class PrestamoDetalleCuotaDto
    {
        public int NumCuota { get; set; }
        public DateTime? FecVenc { get; set; }
        public decimal ImporteBase { get; set; }
        public decimal ImporteInteres { get; set; }
        public decimal ImpCuota { get; set; }
        public decimal Pagado { get; set; }
        public decimal Saldo { get; set; }
        public string FlgStatusPago { get; set; } = string.Empty;
    }
    public class PrestamoDetallePagoDto
    {
        public DateTime? FecPago { get; set; }
        public decimal Importe { get; set; }
        public string FormaPago { get; set; } = string.Empty;
        public string Glosa { get; set; } = string.Empty;
    }
    public class PrestamoDetalleDesembolsoDto
    {
        public DateTime? FecDesembolso { get; set; }
        public decimal Importe { get; set; }
        public string CodCajaChica { get; set; } = string.Empty;
        public string Glosa { get; set; } = string.Empty;
    }
    public class PrestamoDetalleDto
    {
        public PrestamoDetalleCabeceraDto Cabecera { get; set; } = new();
        public List<PrestamoDetalleCuotaDto> Cuotas { get; set; } = new();
        public List<PrestamoDetallePagoDto> Pagos { get; set; } = new();
        public List<PrestamoDetalleDesembolsoDto> Desembolsos { get; set; } = new();
    }

}
