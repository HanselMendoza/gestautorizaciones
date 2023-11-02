# GestionAutorizaciones DotNetCore

Proyecto con estructura inicial base para todos los proyectos basados en .NET Core


## Iniciando

### Tecnologías

- .NET Core 3.1
- Docker
- SonarQube
  - [![Quality Gate Status](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/api/project_badges/measure?project=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w&metric=alert_status&token=b0abebd281689ec60091fe74acdf4fb9ea9ab212)](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/dashboard?id=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w)
  - [![Coverage](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/api/project_badges/measure?project=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w&metric=coverage&token=b0abebd281689ec60091fe74acdf4fb9ea9ab212)](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/dashboard?id=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w)
  - [![Code Smells](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/api/project_badges/measure?project=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w&metric=code_smells&token=b0abebd281689ec60091fe74acdf4fb9ea9ab212)](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/dashboard?id=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w)
  - [![Maintainability Rating](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/api/project_badges/measure?project=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w&metric=sqale_rating&token=b0abebd281689ec60091fe74acdf4fb9ea9ab212)](http://husonarqubedev.eastus2.cloudapp.azure.com:9000/dashboard?id=Autorizaciones_gestion-autorizaciones_AYmDPz_M7P5wQ4pmM56w)
### Setup
1. Clonar el repositorio
2. Situarse en la raiz del directorio, y construir imagen Docker
```
docker build -t gestion-autorizaciones -f Dockerfile .
```
3. Correr imagen
```
docker run -dp 5000:80  --name gestion-autorizaciones gestion-autorizaciones
```

4. Ir al navegador con el host y puerto en que está corriendo el proyecto; deberá visualizarse UI de Swagger.

## Arquitectura

### Clean Architecture 

En Clean Architecture, una aplicación se divide en responsabilidades y cada una de estas responsabilidades se representa en forma de capa.

Se basa en que la capa de dominio no dependa de ninguna capa exterior. La de aplicación sólo depende de la de dominio y el resto (normalmente presentación y acceso a datos) depende de la capa de aplicación. Esto se logra con la implementación de interfaces de servicios que luego tendrán que implementar las capas externas y con la inyección de dependencias.

### Capas

- Domain: es el corazon de la aplicación y tiene que estar totalmente aislada de cualquier dependencia ajena a la lógica o los datos de negocio. Puede contener entidades, value objects, eventos y servicios del dominio.

- Application: es la capa que contiene los servicios que conectan el dominio con el mundo exterior (capas exteriores). Aquí se definen los contratos, interfaces.
- Infraestructure: es la capa de acceso a datos. Implementa interfaces definida en la capa de Application.
- API: es la capa de presentación. Maneja los requests y responses, y se comúnmente se comunica con la capa de Application.

### Patrones y metodologías utilizadas:

- *MediatR*: Para la llamada de servicios a la capa de aplicación sin hacer uso de dependencias.
No sólo para evitar el tema de dependencias, si no sobre todo para estructurar las llamadas de queries (consulta) y comandos (inserción/modificación/borrado) de manera fácilmente entendible, desarrollable y mantenible.

- *CQRS*: Patrón de arquitectura que separa los modelos para leer y escribir datos.
La idea básica es que puede dividir las operaciones de un sistema en dos categorías claramente diferenciadas:

  *Consultas*. Estas consultas devuelven un resultado sin cambiar el estado del sistema y no tienen efectos secundarios.

  *Comandos*. Estos comandos cambian el estado de un sistema.

- *FluentValidation*. Permite «aislar» las validaciones de los comandos para tenerlas en un único sitio y así ahorrar código.

- *AutoMapper*. Para sistematizar la conversión de objetos de Entities a Dtos o Commands, de una manera fácil y ahorrando código

- *Acceso a datos*: Entity Framework Core (DbContext) o Unit Of Work & Repository Pattern. Se recomienda Entity Framework.

- *Pruebas*. Para pruebas unitarias se puede usar nUnit o xUnit, mientras que para las pruebas funcionales se incluyen los siguientes frameworks:
   
    *  *Machine Specifications*: como framework BDD (Behaviour Driven Development).
    *  *FakeItEasy*: como framework para mocks.
    *  *Machine Specifications*: como framework BDD (Behaviour Driven Development).

- *Migraciones*. Se sugiere el uso de FluentMigrations como framework para crear migraciones de bases de datos.