using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoEdicionDto
    {
        public int Id_Prestamo { get; set; }
        public string Cod_TipAnex { get; set; } = "";
        public string Cod_Anxo { get; set; } = "";
        public DateTime Fecha { get; set; }
        public decimal Capital { get; set; }
        public int Nro_Cuotas { get; set; }
        public string Tipo_Modalidad { get; set; } = "";
        public string TipoInteres { get; set; } = "";
        public decimal PorcInteresMensual { get; set; }
        public string FrecuenciaPago { get; set; } = "";
        public DateTime FechaInicioCobro { get; set; }
        public DateTime FechaFinCobro { get; set; }
        public string Cod_Concepto { get; set; } = "";
        public string Observacion { get; set; } = "";

        public bool TieneGarantia { get; set; }

        public string Tipo_Garantia { get; set; } = "";
        public string Marca { get; set; } = "";
        public string Modelo { get; set; } = "";
        public string Serie { get; set; } = "";
        public string Estado_Articulo { get; set; } = "";
        public decimal? Valor_Referencial { get; set; }
        public string DescripcionGarantia { get; set; } = "";
        public string ObservacionGarantia { get; set; } = "";

        public bool TienePagos { get; set; }
        public bool TieneDesembolsos { get; set; }
        public bool PuedeEditar { get; set; }
    }
}
