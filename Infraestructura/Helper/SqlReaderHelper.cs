using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;

namespace Infraestructura.Helper
{
    public class SqlReaderHelper
    {
        public static bool ValidaReaderBool(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return false;
            }
            return reader.GetBoolean(ordinal);
        }
        public static byte[]? ValorReaderBytes(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return null;
            }
            return reader.GetSqlBinary(ordinal).Value;
        }

        public static string ValorReaderString(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return string.Empty;
            }
            return reader.GetString(ordinal);
        }
        public static int ValorReaderInt(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return 0;
            }
            return Convert.ToInt32(reader.GetValue(ordinal));
        }
        public static Decimal ValorReaderDecimal(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return 0M;
            }
            return Convert.ToDecimal(reader.GetValue(ordinal));
        }

        public static Boolean ValorReaderBool(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);
            if (reader.IsDBNull(ordinal))
            {
                return false;
            }
            return Convert.ToBoolean(reader.GetValue(ordinal));
        }
        public static DateTime ValorReaderDateTime(SqlDataReader reader, string nombreCampo)
        {
            int ordinal = reader.GetOrdinal(nombreCampo);

            if (reader.IsDBNull(ordinal))
            {
                return new DateTime(2000, 1, 1);
            }

            object valor = reader.GetValue(ordinal);

            if (valor is DateTime dt)
            {
                return dt;
            }

            string fechaStr = valor.ToString().Trim();

            if (DateTime.TryParseExact(fechaStr, "yyyy-MM-dd",
                                       System.Globalization.CultureInfo.InvariantCulture,
                                       System.Globalization.DateTimeStyles.None,
                                       out DateTime resultado))
            {
                return resultado;
            }

            if (DateTime.TryParse(fechaStr, out DateTime resultadoFinal))
            {
                return resultadoFinal;
            }

            return new DateTime(2000, 1, 1);
        }
    }
}
