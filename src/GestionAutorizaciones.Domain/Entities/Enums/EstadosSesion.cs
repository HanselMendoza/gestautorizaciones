using System;
using System.Collections.Generic;
using System.Text;

namespace GestionAutorizaciones.Domain.Entities.Enums
{
    public enum EstadosSesion
    {
        Pendiente = 268,
        Enviada,
        PreAutorizada,
        Cancelada,
        Abierta
    }
}