
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Precertificaciones.Common;
using GestionAutorizaciones.Application.Precertificaciones.ConfirmarPrecertificacion;
using GestionAutorizaciones.Application.Precertificaciones.CancelarPrecertificacion;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class PrecertificacionTest
    {

        Mock<IPrecertificacionRepositorio> _precertificacionRepositorio;
        Mock<ISesionRepositorio> _sesionRepositorio;

        long numeroPrecertificacion = 254254525;
        long numeroSesion = 214526;

        int estatus = 52;
        string descripcionEstatus = "Vigente";
        string esSoloPbs = "S";
        string esPssPaquete = "N";
        string tieneExcesoPorGrupo = "N";
        long codigoPss = 1944;


        public PrecertificacionTest()
        {
        }

        [SetUp]
        public void Setup()
        {
            _precertificacionRepositorio = new Mock<IPrecertificacionRepositorio>();
            _sesionRepositorio = new Mock<ISesionRepositorio>();

            _sesionRepositorio.Setup(x => x.ObtenerInfoSesion(It.IsAny<long>())).
             Returns(Task.FromResult(new InfoSesion
             {
                 CodigoPss = Convert.ToString(codigoPss),
                 DescripcionEstatus = descripcionEstatus,
                 EsPssPaquete = esPssPaquete,
                 EsSoloPbs = esSoloPbs,
                 Estatus = estatus,
                 TieneExcesoPorGrupo = tieneExcesoPorGrupo
             }));

            _precertificacionRepositorio
                .Setup(x => x.CancelarPrecertificacion(It.IsAny<string>(), It.IsAny<long?>(), It.IsAny<int?>(), It.IsAny<long?>()))
                .Returns(Task.FromResult(new CancelaPrecertificacion
                {
                    CodigoValidacion = 0,
                    NumeroPrecertificacion = numeroPrecertificacion
                }));
                ;
        }

        [Test]
        public async Task Confirmar_Precertificacion_Test()
        {
            var command = new ConfirmarPrecertificacionCommand
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                NumeroSesion = numeroSesion
            };
            var handler = new ConfirmarPrecertificacionCommandHandler(_sesionRepositorio.Object, _precertificacionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }

        [Test]
        public async Task CancelarPrecertificacion_Test()
        {
            var command = new CancelarPrecertificacionCommand
            {
                NumeroPrecertificacion = numeroPrecertificacion,
                
            };
            var handler = new CancelarPrecertificacionCommandHandler(_precertificacionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);
            Assert.IsTrue(result.respuesta?.Codigo == 0);
        }

    }
}
