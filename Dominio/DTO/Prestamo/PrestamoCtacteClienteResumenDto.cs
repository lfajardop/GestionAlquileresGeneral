using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoCtacteClienteResumenDto
    {
        public string Cod_TipAnex { get; set; } = "";
        public string Cod_Anxo { get; set; } = "";
        public int CantPrestamos { get; set; }
        public decimal TotalCapital { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal SaldoPendiente { get; set; }
    }
    public class PrestamoCtacteClienteDetalleDto
    {
        public int Id_Prestamo { get; set; }
        public DateTime Fecha { get; set; }
        public decimal Capital { get; set; }
        public int Nro_Cuotas { get; set; }
        public decimal PorcInteresMensual { get; set; }
        public string PorcInteresMensualTexto { get; set; } = "";
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal SaldoPendiente { get; set; }
        public string Flg_Estado { get; set; } = "";
        public string EstadoTexto { get; set; } = "";
        public string Flg_Desembolsado { get; set; } = "";
        public string DesembolsadoTexto { get; set; } = "";
        public decimal Imp_Desembolsado { get; set; }
        public DateTime? UltimoPago { get; set; }
        public int? ProximaCuota { get; set; }
        public DateTime? ProximoVencimiento { get; set; }
        public int CuotasPendientes { get; set; }
        public int CuotasVencidas { get; set; }
        public int DiasAtraso { get; set; }
        public string Observacion { get; set; } = "";

        public string Cod_Concepto { get; set; } = "";
        public string NombreConcepto { get; set; } = "";
        public string ConceptoMostrar { get; set; } = "";
    }
    public class PrestamoCtacteClienteCuotaDto
    {
        public int Id_Prestamo { get; set; }
        public DateTime FechaPrestamo { get; set; }
        public decimal Capital { get; set; }
        public decimal TotalCobrar { get; set; }
        public decimal PorcInteresMensual { get; set; }
        public string PorcInteresMensualTexto { get; set; } = "";

        public int NumCuota { get; set; }
        public DateTime? Fec_Venc { get; set; }
        public decimal ImporteBase { get; set; }
        public decimal ImporteInteres { get; set; }
        public decimal ImpCuota { get; set; }
        public decimal ImpPagado { get; set; }
        public decimal SaldoCuota { get; set; }
        public string EstadoCuota { get; set; } = "";

        public decimal AcumProgramadoPrestamo { get; set; }
        public decimal AcumPagadoPrestamo { get; set; }
        public decimal AcumSaldoPrestamo { get; set; }

        public decimal AcumProgramadoGlobal { get; set; }
        public decimal AcumPagadoGlobal { get; set; }
        public decimal AcumSaldoGlobal { get; set; }

        public int DiasAtraso { get; set; }
    }
    public class PrestamoCtacteClienteCuotaResumenDto
    {
        public int TotalPrestamos { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalSaldo { get; set; }
    }
    public class PrestamoCtacteClienteCuotasResponseDto
    {
        public List<PrestamoCtacteClienteCuotaDto> Detalle { get; set; } = new();
        public PrestamoCtacteClienteCuotaResumenDto Resumen { get; set; } = new();
    }
    public class PrestamoCtacteClientesResumenGeneralDto
    {
        public string Cod_TipAnex { get; set; } = "";
        public string Cod_Anxo { get; set; } = "";
        public string Cliente { get; set; } = "";

        public int CantPrestamos { get; set; }
        public decimal TotalCapital { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalSaldo { get; set; }
    }
    public class PrestamoCtacteClientesResumenGeneralTotalDto
    {
        public int TotalClientes { get; set; }
        public int TotalPrestamos { get; set; }
        public decimal TotalCapital { get; set; }
        public decimal TotalProgramado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal TotalSaldo { get; set; }
    }
    public class PrestamoCtacteClientesResumenGeneralResponseDto
    {
        public List<PrestamoCtacteClientesResumenGeneralDto> Detalle { get; set; } = new();
        public PrestamoCtacteClientesResumenGeneralTotalDto Totales { get; set; } = new();
    }
}
