using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace Dominio.DTO.Common
{
    public class JsonResponse
    {
        [JsonPropertyName("success")]
        public bool Success { get; set; }
        [JsonPropertyName("message")]
        public string Mensaje { get; set; } = string.Empty;
        [JsonPropertyName("data")]
        public T? Data { get; set; }
        [JsonPropertyName("errors")]
        public List<string> Errors { get; set; } = new();
    }
}
