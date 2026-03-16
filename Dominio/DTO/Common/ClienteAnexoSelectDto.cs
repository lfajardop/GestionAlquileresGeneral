using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Dominio.DTO.Common
{
    public class ClienteAnexoSelectDto
    {
        public string Cod_TipAnex { get; set; } = string.Empty;
        public string Cod_Anxo { get; set; } = string.Empty;
        public string Documento { get; set; } = string.Empty;
        public string NombreCompleto { get; set; } = string.Empty;
        public string TextoMostrar { get; set; } = string.Empty;
    }
}
