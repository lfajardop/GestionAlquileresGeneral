namespace Dominio.DTO.Yape;

public class YapeCajaActivaDto
{
    public string CodCajaChica { get; set; } = "";
    public string DesCajaChica { get; set; } = "";
    public int NumMovstk { get; set; }
    public int NumTransaccion { get; set; }
    public DateTime FechaDesde { get; set; }
    public DateTime FechaHasta { get; set; }
    public string Observaciones { get; set; } = "";
}

public class YapeConceptoDto
{
    public string Codigo { get; set; } = "";
    public string Descripcion { get; set; } = "";
    public string Tipo { get; set; } = "";
}

public class YapeMovimientoCargaDto
{
    public int NumFilaExcel { get; set; }
    public DateTime FechaYape { get; set; }
    public string TipoYape { get; set; } = "";
    public string TipoNormalizado { get; set; } = "";
    public string Origen { get; set; } = "";
    public string Destino { get; set; } = "";
    public decimal Monto { get; set; }
    public string Glosa { get; set; } = "";
    public string Beneficiario { get; set; } = "";
    public string HashMovimiento { get; set; } = "";
}

public class YapeLoteDto
{
    public int IdLote { get; set; }
    public string NombreArchivo { get; set; } = "";
    public string Periodo { get; set; } = "";
    public string CodCajaChica { get; set; } = "";
    public int NumMovstk { get; set; }
    public int NumTransaccion { get; set; }
    public DateTime FechaDesde { get; set; }
    public DateTime FechaHasta { get; set; }
    public string Estado { get; set; } = "";
    public int TotalFilas { get; set; }
    public int TotalInsertadas { get; set; }
    public int TotalDuplicadas { get; set; }
    public int TotalRevision { get; set; }
}

public class YapeMovimientoPreviewDto
{
    public int IdDetalle { get; set; }
    public int NumFilaExcel { get; set; }
    public DateTime FechaYape { get; set; }
    public string TipoYape { get; set; } = "";
    public string TipoNormalizado { get; set; } = "";
    public string Origen { get; set; } = "";
    public string Destino { get; set; } = "";
    public string Beneficiario { get; set; } = "";
    public decimal Monto { get; set; }
    public string Glosa { get; set; } = "";
    public string CodConceptoCaja { get; set; } = "";
    public string DesConceptoCaja { get; set; } = "";
    public int Score { get; set; }
    public bool RequiereRevision { get; set; }
    public bool FueDuplicado { get; set; }
    public string FlgSeleccionado { get; set; } = "N";
    public string Estado { get; set; } = "";
    public string Observacion { get; set; } = "";
    public string MotivoResultado { get; set; } = "";
    public int? SecMovimientoExistente { get; set; }
}

public class YapePreviewDto
{
    public YapeLoteDto Lote { get; set; } = new();
    public List<YapeMovimientoPreviewDto> Movimientos { get; set; } = new();
}

public class YapeActualizarRequestDto
{
    public int IdLote { get; set; }
    public int IdDetalle { get; set; }
    public string FlgSeleccionado { get; set; } = "N";
    public string CodConceptoCaja { get; set; } = "";
    public string? Observacion { get; set; }
}
