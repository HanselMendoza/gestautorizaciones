using AutoMapper;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Autorizaciones.CancelarAutorizacion;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Autorizaciones.CompararAutorizacion;
using GestionAutorizaciones.Application.Autorizaciones.ConciliarAutorizacion;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerAutorizaciones;
using GestionAutorizaciones.Application.Autorizaciones.ObtenerDetalleAutorizacion;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Autorizaciones.Common;

namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class AutorizacionesTest
    {
        Mock<IMapper> _mapper;
        Mock<IPrestadorRepositorio> _prestadorRepositorio;
        Mock<ISesionRepositorio> _sesionRepositorio;
        Mock<IAutorizacionRepositorio> _autorizacioRepositorio;
        Mock<IAseguradoRepositorio> _aseguradoRepositorio;

        string tipoPss = "MEDICO";
        long codigoPss = 1944;
        DateTime fechaInicio = DateTime.Parse("04/01/2022");
        DateTime fechaFin = DateTime.Parse("07/01/2022");
        int? ramo = 95;
        long? secuencial = 25252525;
        string usuarioIngreso = null;
        long numeroPlastico = 1903921403200;

        string nompreOperacion = "EliminarReclamacion";
        int reclamacionCodigoEstado = 183;
        string Sesion = "12345";
        decimal? montoReclamado = 250;
        decimal? montoARS = 250;
        decimal? montoAseg = 100;
        string numeroAutorizacion = "H95-653269";



        public AutorizacionesTest()
        {
        }
        [SetUp]
        public void Setup()
        {
            _mapper = new Mock<IMapper>();
            _prestadorRepositorio = new Mock<IPrestadorRepositorio>();
            _sesionRepositorio = new Mock<ISesionRepositorio>();
            _aseguradoRepositorio = new Mock<IAseguradoRepositorio>();
            _autorizacioRepositorio = new Mock<IAutorizacionRepositorio>();

            IEnumerable<ReclamacionPss> reclamacion = new List<ReclamacionPss>();
            _prestadorRepositorio.Setup(x => x.ObtenerReclamacionesPss
            (It.IsAny<string>(), It.IsAny<long>(), It.IsAny<DateTime>(), It.IsAny<DateTime>(),
            It.IsAny<int>(), It.IsAny<long>(), It.IsAny<string>(), It.IsAny<long>(), It.IsAny<int?>())).
            Returns(Task.FromResult(reclamacion));

            _sesionRepositorio.Setup(x => x.Infoxproc(It.IsAny<string>(), It.IsAny<long>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string>())).
            Returns(Task.FromResult(new RespuestaInfoxProc { Outstr1 = nompreOperacion, Outstr2 = Convert.ToString(Sesion), Outnum1 = Convert.ToString(reclamacionCodigoEstado), Outnum2 = Sesion, }));

            IEnumerable<Reclamacion> reclamacion_detalle = new List<Reclamacion>();
            _autorizacioRepositorio.Setup(x => x.ObtenerInformacionReclamaciones
            (It.IsAny<int>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<long>(), It.IsAny<long>())).
             Returns(Task.FromResult(reclamacion_detalle));


        }

        [Test]
        public async Task Obtener_Autorizaciones_Pss_Test()
        {
            var command = new ObtenerAutorizacionesQuery
            {
                TipoPss = tipoPss,
                CodigoPss = codigoPss,
                FechaInicio = fechaInicio,
                FechaFin = fechaFin,
                Ramo = ramo,
                Secuencial = secuencial,
                UsuarioIngreso = usuarioIngreso,
                NumeroPlastico = numeroPlastico,
            };
            var handler = new ObtenerAutorizacionesQueryHandler(_mapper.Object, _prestadorRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task Cancelar_Autorizacion_Test()
        {
            var command = new CancelarAutorizacionCommand
            {
                NumeroPlastico = numeroPlastico,
                NumeroAutorizacion = numeroAutorizacion,
            };
            var handler = new CancelarAutorizacionCommandHandler(_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task obtener_Detalle_Autorizacion_Test()
        {
            var command = new ObtenerDetalleAutorizacionQuery
            {
                NumeroAutorizacion = numeroAutorizacion,
            };
            var handler = new ObtenerDetalleAutorizacionQueryHandler(_mapper.Object, 
                _aseguradoRepositorio.Object, _sesionRepositorio.Object, _autorizacioRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task comparar_Autorizaciones_Test()
        {
            var command = new CompararAutorizacionCommand
            {
                Autorizaciones = new List<Autorizacion>(),
                NumeroSesion = Convert.ToInt64(Sesion),

            };
            var handler = new CompararAutorizacionCommandHandler(_prestadorRepositorio.Object, 
                _sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task conciliar_Autorizaciones_Test()
        {
            var command = new ConciliarAutorizacionCommand
            {
                FechaInicio = fechaInicio,
                FechaFin = fechaFin,
                TotalARS = montoARS,
                TotalAsegurado = montoAseg,
                TotalReclamado = montoReclamado,
                Detalle = new List<DetalleAutorizacion>(),
                NumeroSesion = Convert.ToInt64(Sesion),

            };
            var handler = new ConciliarAutorizacionCommandHandler(_prestadorRepositorio.Object,_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }

    }

}
