using GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion;
using GestionAutorizaciones.Application.Common.Dtos;
using MediatR;
using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace GestionAutorizaciones.Application.Autorizaciones.ProcesarAutorizacion
{
    public class ProcesarAutorizacionCommand: IRequest<ResponseDto<ProcesarAutorizacionResponseDto>>
    {
        public string UsuarioRegistra { get; set; }
        public int? IdAutorizacion { get; set; }
        public long? NumeroPlastico { get; set; }
        [JsonIgnore]
        public long? NumeroSesion { get; set; }
        public List<MedicamentoDto> Medicamentos { get; set; }
    }

    public class MedicamentoDto
    {
        public string CodigoSimon { get; set; }
        public string Descripcion { get; set; }
        public string TipoMedicamento { get; set; }
        public int? Cantidad { get; set; }
        public decimal? Precio { get; set; }
    }
}
