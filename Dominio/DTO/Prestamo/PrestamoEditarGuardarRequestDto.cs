using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoEditarGuardarRequestDto
    {
        public int Id_Prestamo { get; set; }

        public DateTime Fecha { get; set; }
        public decimal Capital { get; set; }
        public string TipoModalidad { get; set; } = "";
        public string TipoInteres { get; set; } = "";
        public decimal PorcInteresMensual { get; set; }
        public string FrecuenciaPago { get; set; } = "";
        public DateTime FechaInicioCobro { get; set; }
        public DateTime FechaFinCobro { get; set; }

        public string Cod_Concepto { get; set; } = "";
        public string Observacion { get; set; } = "";

        public bool TieneGarantia { get; set; }
        public string TipoGarantia { get; set; } = "";
        public string MarcaGarantia { get; set; } = "";
        public string ModeloGarantia { get; set; } = "";
        public string SerieGarantia { get; set; } = "";
        public string EstadoGarantia { get; set; } = "";
        public decimal? ValorGarantia { get; set; }
        public string DescripcionGarantia { get; set; } = "";
        public string ObservacionGarantia { get; set; } = "";
    }
}
