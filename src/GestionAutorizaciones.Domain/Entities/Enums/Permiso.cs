namespace GestionAutorizaciones.Domain.Entities.Enums
{
    public enum Permiso
    {
        IniciarSesion = 1,
        CerrarSesion,
        ReactivarSesion,
        LeerPrestador,
        LeerAfiliado,
        LeerProcedimiento,
        CancelarProcedimiento,
        ValidarProcedimiento,
        InsertarProcedimiento,
        LeerProcedimientosPermitidos,
        LeerAutorizaciones,
        LeerAutorizacion,
        CancelarAutorizacion,
        ConciliarAutorizaciones,
        CompararAutorizaciones,
        LeerPrecertificacion,
        ConfirmarPrecertificacion,
        LeerTipoCobertura,
        LeerRegimenAfiliado,
        ConfirmarAutorizacion,
        CancelarPrecertificacion
    }
}