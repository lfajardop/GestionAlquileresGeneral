using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.FormaPago
{
    public class FormaPagoDto
    {
         public int IdFormaPago { get; set; }
        public string Tipo { get; set; } = string.Empty;
    }
}
