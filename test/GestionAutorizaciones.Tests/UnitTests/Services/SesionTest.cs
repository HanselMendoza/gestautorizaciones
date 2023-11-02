using System;
using System.Threading;
using System.Threading.Tasks;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Sesion.CerrarSesion;
using GestionAutorizaciones.Application.Sesion.IniciarSesion;
using GestionAutorizaciones.Application.Sesion.ReactivarSesion;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
using GestionAutorizaciones.Application.Autorizaciones.Common;

namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class SesionTest
    {

        Mock<ISesionRepositorio> _sesionRepositorio;
        Mock<IAutorizacionRepositorio> _autorizacionRepositorio;


        string Sesion = "12345";
        long Codigo = 1944;
        long Pin = 4419;

        string nompreOperacion = "CerrarReclamacion";
        string estadoReclamacion = "ESTADO_PRE_AUTORIZADO";
        bool esarl = true;

        bool aplica = true;
        string mensaje = " ";
        string resultado = "OK";
        string numeroAutorizacion = "H95-1789748";

        public SesionTest()
        {
        }


        [SetUp]
        public void Setup()
        {
            _sesionRepositorio = new Mock<ISesionRepositorio>();
            _autorizacionRepositorio = new Mock<IAutorizacionRepositorio>();

            _sesionRepositorio.Setup(x => x.Infoxproc(It.IsAny<string>(), It.IsAny<long>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<string>())).
            Returns(Task.FromResult(new RespuestaInfoxProc { Outstr1 = nompreOperacion, Outstr2 = Convert.ToString(Sesion), Outnum1 = estadoReclamacion, Outnum2 = Sesion, }));

            _sesionRepositorio.Setup(x => x.ReactivarSesion(It.IsAny<int>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<long>())).
            Returns(Task.FromResult(new Sesion
            {
                NumeroSesion = Convert.ToInt32(Sesion),
                Aplica = aplica,
                Mensaje = mensaje,
                Resultado = resultado
            }));

        }

        [Test]
        public async Task Iniciar_Sesion_Test()
        {
            var command = new IniciarSesionCommand
            {
                Codigo = Codigo,
                Pin = Pin
            };
            var handler = new IniciarSesionCommandHandler(_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task Cerrar_Sesion_Test()
        {
            var command = new CerrarSesionCommand
            {
                PreAutorizar = true,
                EsARL = esarl,
                NumeroSesion = Convert.ToInt32(Sesion)
            };
            var handler = new CerrarSesionCommandHandler(_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task Reactivar_Sesion_Test()
        {
            var command = new ReactivarSesionCommand
            {
                Anio = DateTime.Now.Year,
                CodigoPss = Codigo,
                NumeroAutorizacion = numeroAutorizacion
            };
            var handler = new ReactivarSesionCommandHandler(_sesionRepositorio.Object, _autorizacionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);
        }

    }
}

