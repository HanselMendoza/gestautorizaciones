using AutoMapper;
using GestionAutorizaciones.Application.Asegurado.Common;
using GestionAutorizaciones.Application.Asegurado.ObtenerAsegurado;
using GestionAutorizaciones.Application.Prestadores.Common;
using GestionAutorizaciones.Application.Sesion.Common;
using GestionAutorizaciones.Domain.Entities;
using Moq;
using NUnit.Framework;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace GestionAutorizaciones.Tests.UnitTests.Services
{
    public class AseguradoTest
    {
        Mock<IMapper> _mapper;
        Mock<ISesionRepositorio> _autorizacionRepositorio;
        Mock<IAseguradoRepositorio> _aseguradoRepositorio;
        Mock<IPrestadorRepositorio> _prestadorRepositorio;

        long numeroPlastico = 25462541;
       // bool esTokenVirtual = true;
        long numeroSesion = 225451424;

        long? numeroAsegurado = 1432;
        string nombres = "jose";
        string primerApellido = "Santiago";
        string segundoApellido = "Gimenez";
        string sexo = "M";
        DateTime? fechaNacimiento = new DateTime();
        string nacionalidad = "Dominicano";
        string parentesco = "Padre";
        long? codigoEmpresa = 30;
        string empresa = "Humano";
        string telefonoEmpresa = "8096028958";
        string direccionEmpresa = "Prueba";
        string actividad = "prueba";
        string tipoDocumento = "C";
        DateTime? fechaSolicitud = new DateTime();
        string cedula = "001172456985";
        string descripcionPlan = "Royal";
        string tipoPlan = "Individual";


        public AseguradoTest()
        {
        }
        [SetUp]
        public void Setup()
        {
            _mapper = new Mock<IMapper>();
            _autorizacionRepositorio = new Mock<ISesionRepositorio>();
            _aseguradoRepositorio = new Mock<IAseguradoRepositorio>();
            _prestadorRepositorio = new Mock<IPrestadorRepositorio>();


            _aseguradoRepositorio.Setup(x => x.ObtenerAfiliado(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<int>())).
           Returns(Task.FromResult(new Afiliado
           {
               Actividad = actividad,
               Cedula = cedula,
               CodigoEmpresa = codigoEmpresa,
               DescripcionPlan = descripcionPlan,
               DireccionEmpresa = direccionEmpresa,
               Empresa = empresa,
               FechaNacimiento = fechaNacimiento,
               FechaSolicitud = fechaSolicitud,
               Nacionalidad = nacionalidad,
               Nombres = nombres,
               NumeroAsegurado = numeroAsegurado,
               Parentesco = parentesco,
               PrimerApellido = primerApellido,
               SegundoApellido = segundoApellido,
               Sexo = sexo,
               TelefonoEmpresa = telefonoEmpresa,
               TipoDocumento = tipoDocumento,
               TipoPlan = tipoPlan,
           }));

        }

        [Test]
        public async Task Obtener_Informacion_Asegurado_Test()
        {
            var command = new ObtenerAseguradoQuery
            {
                NumeroPlastico = numeroPlastico,
                NumeroSesion = numeroSesion
            };
            var handler = new ObtenerAseguradoQueryHandler(_mapper.Object, 
            _aseguradoRepositorio.Object, _autorizacionRepositorio.Object,
            _prestadorRepositorio.Object);
            var result = await handler.Handle(command, default(CancellationToken));
            Assert.IsNotNull(result);

        }
    }
}
