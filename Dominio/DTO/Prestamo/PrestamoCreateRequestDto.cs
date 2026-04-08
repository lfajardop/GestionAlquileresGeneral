using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoCreateRequestDto
    {
        public string Cod_TipAnex { get; set; } = "C";
        public string Cod_Anxo { get; set; } = string.Empty;

        public DateTime Fecha { get; set; } = DateTime.Today;
        public decimal Capital { get; set; }

        public string TipoInteres { get; set; } = "M";      // N / M
        public string TipoModalidad { get; set; } = "M";      // C=Cuotas normales, I=Interés+capital final, F=Todo al final
        public decimal PorcInteresMensual { get; set; }

        public string FrecuenciaPago { get; set; } = "M";   // D / S / M
        public DateTime FechaInicioCobro { get; set; } = DateTime.Today;
        public DateTime FechaFinCobro { get; set; } = DateTime.Today;

        public string Observacion { get; set; } = string.Empty;
        public string Cod_Almacen { get; set; } = "1";
        //Para Garantia
        public bool TieneGarantia { get; set; }

        public string? TipoGarantia { get; set; }
        public string? DescripcionGarantia { get; set; }
        public string? MarcaGarantia { get; set; }
        public string? ModeloGarantia { get; set; }
        public string? SerieGarantia { get; set; }
        public string? EstadoGarantia { get; set; }
        public decimal? ValorGarantia { get; set; }
        public string? ObservacionGarantia { get; set; }

    }
}
