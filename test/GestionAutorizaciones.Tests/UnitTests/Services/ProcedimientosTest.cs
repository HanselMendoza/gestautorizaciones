using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Procedimientos.Common;
using GestionAutorizaciones.Application.Procedimientos.EliminarProcedimiento;
using GestionAutorizaciones.Application.Procedimientos.InsertarProcedimiento;
using GestionAutorizaciones.Application.Procedimientos.ValidarProcedimiento;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
using NUnit.Framework.Constraints;
using System;
using System.Threading;
using System.Threading.Tasks;
using static GestionAutorizaciones.Application.Common.Utils.Constantes;

namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class ProcedimientosTest
    {

        Mock<ISesionRepositorio> _sesionRepositorio;
        Mock<IProcedimientoRepositorio> _procedimientoRepositorio;
        Mock<IPrestadorRepositorio> _prestadorRepositorio;
 
        long NumeroSesion = 1254254254;
        int Frecuencia = 1;
        long Cobertura = 111;
        decimal Monto = 500;
        int TipoServicio = 1;


        [SetUp]
        public void Setup()
        {

            _sesionRepositorio = new Mock<ISesionRepositorio>();
            _procedimientoRepositorio = new Mock<IProcedimientoRepositorio>();
            _prestadorRepositorio = new Mock<IPrestadorRepositorio>();

            _procedimientoRepositorio.Setup(x => x.ValidarPasaReglasCobertura(
                It.IsAny<long>(), It.IsAny<long>(), It.IsAny<long>())).
                Returns(Task.FromResult(new SalidaEstandar {
                    Aplica = true,
                    Resultado = RespuestaInfoxprocValidaCobertura.CoberturaValida,
                    Mensaje = "OK"
                }));

            _sesionRepositorio.Setup(x => x.Infoxproc(It.IsAny<string>(),
                It.IsAny<long>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int?>(),
                It.IsAny<int?>(), It.IsAny<string>())).
                Returns<string,long,string,string,int?,int?>(GetInfoxProcResponse);

        }

        private Task<RespuestaInfoxProc> GetInfoxProcResponse(string funcion, long numeroSesion, 
            string inString1, string inString2, int? inNum1, int? inNum2)
        {
            RespuestaInfoxProc result = new RespuestaInfoxProc();

            if (funcion == NombreOperacion.ValidarCobertura)
            {
                var montoCubierto = Convert.ToString(Monto);
                var montoAsegurado = "0";
                result.Outstr1 = montoCubierto;
                result.Outstr2 = montoAsegurado;
                result.Outnum1 = RespuestaInfoxprocValidaCobertura.CoberturaValida;
            }

            if (funcion == NombreOperacion.EliminarCobertura)
            {
                result.Outnum1 = RespuestaInfoxprocEliminarCobertura.CoberturaEliminada;
            }

            if (funcion == NombreOperacion.InsertarCobertura)
            {
                result.Outnum1 = RespuestaInfoxprocInsertarCobertura.CoberturaInsertada;
            }

            return Task.FromResult(result);
        }

        [Test]
        public async Task Insertar_Procedimiento_Test()
        {
            var command = new InsertarProcedimientoCommand { NumeroSesion = NumeroSesion };

            var handler = new InsertarProcedimientoCommandHandler(_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task Valida_Procedimiento_Test()
        {
            var command = new ValidarProcedimientoCommand
            {
                NumeroSesion = NumeroSesion,
                Monto = Monto,
                Frecuencia = Frecuencia,
                TipoServicio = TipoServicio
            };

            var handler = new ValidarProcedimientoCommandHandler(_sesionRepositorio.Object, _procedimientoRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
        [Test]
        public async Task Eliminar_Procedimiento_Test()
        {
            var command = new EliminarProcedimientoCommand
            {
                NumeroSesion = NumeroSesion,
                Procedimiento = Cobertura
            };

            var handler = new EliminarProcedimientoCommandHandler(_sesionRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }

    }
}
