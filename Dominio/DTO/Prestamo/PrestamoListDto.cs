using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Prestamo
{
    public class PrestamoListDto
    {
        public int Id_Prestamo { get; set; }
        public string Cliente { get; set; } = string.Empty;
        public string Almacen { get; set; } = string.Empty;
        public string Tipo_Modalidad { get; set; } = string.Empty;
        public string Documento { get; set; } = string.Empty;
        public string Estado_Descripcion { get; set; } = string.Empty;
        public string flg_Estado { get; set; } = string.Empty;
        public decimal Total_Programado { get; set; } 
        public decimal Total_Pagado { get; set; }
        public decimal Saldo_Pendiente { get; set; }
        public DateTime Fecha { get; set; }
        public decimal Capital { get; set; }
        public int Nro_Cuotas { get; set; }
        public decimal TEA { get; set; }
        public string Estado { get; set; } = string.Empty;
    }
}
