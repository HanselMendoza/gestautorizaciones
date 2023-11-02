using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Prestadores.ObtenerPrestador;
using GestionAutorizaciones.Application.Prestadores.ObtenerProcedimientosPermitidos;
using GestionAutorizaciones.Application.Prestadores.ValidarPssPuedeOfrecerServicio;
using GestionAutorizaciones.Application.Procedimientos.Common;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class PrestadorTest
    {


        Mock<IMapper> _mapper;
        Mock<IPrestadorRepositorio> _prestadorRepositorio;
        Mock<IProcedimientoRepositorio> _procedimientoRepositorio;

        string TipoPss = "MEDICO";
        string Tipo = "MEDICO";
        long Codigo = 1944;
        string Nombre = "GUSTAVO ENRIQUE LLUBERES GOMEZ";
        string Cedula = "00103245429";
        string Rnc = "00103245429";
        string CodigoEstado = "1";
        string DescripcionEstado = "VIGENTE";
        string Activo = "T";
        DateTime? FechaIngreso = new DateTime();
        DateTime? FechaSalida = new DateTime();
        string Ars = "S";
        long TipoCobertura = 4;


        public PrestadorTest()
        {
        }


        [SetUp]
        public void Setup()
        {

            _mapper = new Mock<IMapper>();
            _prestadorRepositorio = new Mock<IPrestadorRepositorio>();
            _procedimientoRepositorio = new Mock<IProcedimientoRepositorio>();

            _prestadorRepositorio.Setup(x => x.
            ObtenerInfoPss(It.IsAny<string>(), It.IsAny<long>())).
            Returns(Task.FromResult(new Prestador
            {
                TipoPss = TipoPss,
                Tipo = Tipo,
                Codigo = Codigo,
                Nombre = Nombre,
                Cedula = Cedula,
                Rnc = Rnc,
                CodigoEstado = CodigoEstado,
                DescripcionEstado = DescripcionEstado,
                Activo = Activo,
                FechaIngreso = FechaIngreso,
                FechaSalida = FechaSalida,
                Ars = Ars,
            }));

            _prestadorRepositorio.Setup(x => x.ValidarPrestadorOfreceTipoCobertra(It.IsAny<string>(),
                It.IsAny<long>(), It.IsAny<long>())).
                Returns(Task.FromResult(new SalidaEstandar
                {
                    Resultado = "Ok",
                    Mensaje = "Ok",
                    Aplica = true
                }));


            IEnumerable<Procedimiento> procedimientos = new List<Procedimiento>();
            _procedimientoRepositorio.Setup(x => x.ObtenerProcedimientos
            (It.IsAny<string>(), It.IsAny<long>(), It.IsAny<long>())).
            Returns(Task.FromResult(procedimientos));

        }

        [Test]
        public async Task Validar_Prestador_Test()
        {
            var command = new ObtenerPrestadorQuery { TipoPss = TipoPss, CodigoPss = Codigo };
            var handler = new ObtenerPrestadorQueryHandler(_mapper.Object, _prestadorRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }

        [Test]
        public async Task Validar_Pss_Ofrece_Cobertura_Test()
        {
            var command = new ValidarPssOfreceCoberturaQuery
            {
                TipoPss = TipoPss,
                CodigoPss = Codigo,
                TipoCobertura = TipoCobertura
            };

            var handler = new ValidarPssOfreceCoberturaQueryHandler(_prestadorRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }

        [Test]
        public async Task Obtener_Procedimiento_Permitido_Test()
        {
            var command = new ObtenerProcedimientosPermitidosQuery { TipoPss = TipoPss, CodigoPss = Codigo };
            var handler = new ObtenerProcedimientosPermitidosQueryHandler(_mapper.Object, _procedimientoRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
    }
}
