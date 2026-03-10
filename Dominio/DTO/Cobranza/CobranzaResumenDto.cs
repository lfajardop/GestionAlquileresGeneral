using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Cobranza
{
    public class CobranzaResumenDto
    {
        public decimal TotalPorCobrar { get; set; }
        public decimal TotalVencido { get; set; }
        public decimal TotalPorVencer14Dias { get; set; }
        public int CantPrestamosPendientes { get; set; }
        public int CantAlquileresPendientes { get; set; }
        public int CantRentasPorVencer { get; set; }


    }
}
