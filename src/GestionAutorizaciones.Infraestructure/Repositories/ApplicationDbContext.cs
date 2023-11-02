using GestionAutorizaciones.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace GestionAutorizaciones.Infraestructure.Repositories
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }
        public DbSet<Prestador> InformacionPss { get; set; }
        public DbSet<InfoSesion> InfoSesionPrestador { get; set; }
        public DbSet<Reclamacion> Reclamaciones { get; set; }
        public DbSet<DetalleReclamacion> InfoSesionReclamacion { get; set; }
        public DbSet<Nucleo> Nucleos { get; set; }
        public DbSet<Procedimiento> Procedimientos { get; set; }
        public DbSet<ReclamacionPss> ReclamacionPss { get; set; }
        public DbSet<Afiliado> Afiliados { get; set; }
        public DbSet<Precertificacion> Precertificaciones { get; set; }
		public DbSet<Diagnostico> Diagnosticos { get; set; }

		protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<CoberturaSalud>(entity =>
            {
                entity.ToTable("COBERTURA_SALUD", "DBAPER");
                entity.HasKey(x => x.Codigo);

                entity.Property(x => x.Codigo).HasColumnName("CODIGO");
                entity.Property(x => x.Descripcion).HasColumnName("DESCRIPCION");
                entity.Property(x => x.CodigoSimon).HasColumnName("COD_SIMON");
                entity.Property(x => x.Agrupador).HasColumnName("AGRUPADOR");
            });


            modelBuilder.Entity<ReclamacionFarmaCard>(entity =>
            {
                entity.ToTable("TEMP_RECLAMACION_FARMACARD", "DBAPER");
                entity.HasNoKey();

                entity.Property(x => x.TipoCobertura).HasColumnName("TIP_COB");
                entity.Property(x => x.TipoServicio).HasColumnName("TIP_SER");
                entity.Property(x => x.Cobertura).HasColumnName("COBERTURA");
                entity.Property(x => x.Reclamante).HasColumnName("RECLAMANTE");
            });

            modelBuilder.Entity<LimiteCobertura>(entity =>
            {
                entity.ToTable("NO_M_COB02_V", "DBAPER");
                entity.HasNoKey();

                entity.Property(x => x.Codigo).HasColumnName("CODIGO");
                entity.Property(x => x.Descripcion).HasColumnName("DESCRIPCION");
                entity.Property(x => x.Limite).HasColumnName("LIMITE");
                entity.Property(x => x.Compania).HasColumnName("COMPANIA");
            });

            modelBuilder.Entity<Afiliado>(entity =>
            {
                entity.ToTable("P_BUSCA_AFILIADO");
                entity.HasNoKey();
                entity.Property(e => e.NumeroAsegurado).HasColumnName("NUM_ASEGURADO");
                entity.Property(e => e.Nombres).HasColumnName("NOMBRES");
                entity.Property(e => e.PrimerApellido).HasColumnName("PRI_APE");
                entity.Property(e => e.SegundoApellido).HasColumnName("SEG_APE");
                entity.Property(e => e.Sexo).HasColumnName("SEXO");
                entity.Property(e => e.FechaNacimiento).HasColumnName("FEC_NAC");
                entity.Property(e => e.Nacionalidad).HasColumnName("NACIONALIDAD");
                entity.Property(e => e.Parentesco).HasColumnName("PARENTESCO");
                entity.Property(e => e.CodigoEmpresa).HasColumnName("COD_EMP");
                entity.Property(e => e.Empresa).HasColumnName("EMPRESA");
                entity.Property(e => e.TelefonoEmpresa).HasColumnName("TEL_EMPRESA");
                entity.Property(e => e.DireccionEmpresa).HasColumnName("DIR_EMPRESA");
                entity.Property(e => e.Actividad).HasColumnName("ACTIVIDAD");
                entity.Property(e => e.TipoDocumento).HasColumnName("TIPO_DOC");
                entity.Property(e => e.FechaSolicitud).HasColumnName("FEC_SOL");
                entity.Property(e => e.Cedula).HasColumnName("CEDULA");
                entity.Property(e => e.DescripcionPlan).HasColumnName("DESC_PLAN");
                entity.Property(e => e.TipoPlan).HasColumnName("TIPO_PLAN");
                entity.Property(e => e.Nss).HasColumnName("NSS");
            });
            
            modelBuilder.Entity<Prestador>(entity =>
            {
                entity.ToTable("P_OBTENER_INFO_PSS");
                entity.HasNoKey();
                entity.Property(e => e.TipoPss).HasColumnName("TIP_REC");
                entity.Property(e => e.Tipo).HasColumnName("TIPO");
                entity.Property(e => e.Codigo).HasColumnName("CODIGO");
                entity.Property(e => e.Nombre).HasColumnName("NOMBRE");
                entity.Property(e => e.Cedula).HasColumnName("CED_ACT");
                entity.Property(e => e.CodigoEstado).HasColumnName("ESTATUS");
                entity.Property(e => e.DescripcionEstado).HasColumnName("DESCRIPCION");
                entity.Property(e => e.Activo).HasColumnName("VAL_L_REC");
                entity.Property(e => e.Rnc).HasColumnName("RNC");
                entity.Property(e => e.FechaIngreso).HasColumnName("FEC_ING");
                entity.Property(e => e.FechaSalida).HasColumnName("FEC_SAL");
                entity.Property(e => e.Ars).HasColumnName("ARS");
                entity.Property(e => e.Pyp).HasColumnName("PYP");
            });

            modelBuilder.Entity<InfoSesion>(entity =>
            {
                entity.ToTable("P_OBTENER_INFOX_SESSION");
                entity.HasNoKey();
                entity.Property(e => e.Estatus).HasColumnName("ESTATUS");
                entity.Property(e => e.DescripcionEstatus).HasColumnName("DESCRIPCION_ESTATUS");
                entity.Property(e => e.EsSoloPbs).HasColumnName("ES_SOLO_PBS");
                entity.Property(e => e.EsPssPaquete).HasColumnName("ES_PSS_PAQUETE");
                entity.Property(e => e.TieneExcesoPorGrupo).HasColumnName("TIENE_EXCESOPORGRUPO");
                entity.Property(e => e.TipoPss).HasColumnName("TIPO_PSS");
                entity.Property(e => e.CodigoPss).HasColumnName("CODIGO_PSS");
                entity.Property(e => e.CodigoAsegurado).HasColumnName("COD_ASEGURADO");
                entity.Property(e => e.SecuenciaDependiente).HasColumnName("SEC_DEPENDIENTE");

            });

            modelBuilder.Entity<Reclamacion>(entity =>
            {
                entity.ToTable("P_OBTENER_INFO_RECLAMACION");
                entity.HasNoKey();
                entity.Property(e => e.Ano).HasColumnName("ANO");
                entity.Property(e => e.Compania).HasColumnName("COMPANIA");
                entity.Property(e => e.Ramo).HasColumnName("RAMO");
                entity.Property(e => e.Secuencial).HasColumnName("SECUENCIAL");
                entity.Property(e => e.UsuarioIngreso).HasColumnName("USU_ING");
                entity.Property(e => e.FechaApertura).HasColumnName("FEC_APE");
                entity.Property(e => e.Estatus).HasColumnName("ESTATUS");
                entity.Property(e => e.Descripcion).HasColumnName("DESCRIPCION");
                entity.Property(e => e.NumeroPlastico).HasColumnName("NUM_PLA");
                entity.Property(e => e.Cobertura).HasColumnName("COBERTURA");
                entity.Property(e => e.DescripcionCobertura).HasColumnName("DESCRIPCION_COBERTURA");
                entity.Property(e => e.Frecuencia).HasColumnName("FRECUENCIA");
                entity.Property(e => e.MontoReclamado).HasColumnName("MON_REC");
                entity.Property(e => e.MontoPagado).HasColumnName("MON_PAG");
                entity.Property(e => e.MontoAsegurado).HasColumnName("MON_COASEG");
                entity.Property(e => e.TipoReclamante).HasColumnName("TIP_REC");
                entity.Property(e => e.Reclamante).HasColumnName("RECLAMANTE");
                entity.Property(e => e.Nombre).HasColumnName("NOMBRE");
                entity.Property(e => e.TipoServicio).HasColumnName("TIP_SER");
                entity.Property(e => e.ValidarReclamacion).HasColumnName("VAL_L_REC");
                entity.Property(e => e.DescripcionReclamacion).HasColumnName("DESCRIPCION_RECLAMACION");
            });
            modelBuilder.Entity<DetalleReclamacion>(entity =>
            {
                entity.ToTable("P_OBTENER_DET_RECLAMACION");
                entity.HasNoKey();
                entity.Property(e => e.Ano).HasColumnName("ANO");
                entity.Property(e => e.Compania).HasColumnName("COMPANIA");
                entity.Property(e => e.Ramo).HasColumnName("RAMO");
                entity.Property(e => e.Secuencial).HasColumnName("SECUENCIAL");
                entity.Property(e => e.Secuencia).HasColumnName("SECUENCIA");
                entity.Property(e => e.Procedimiento).HasColumnName("PROC");
                entity.Property(e => e.MontoArs).HasColumnName("MONTOARS");
                entity.Property(e => e.MontoAfiliado).HasColumnName("MONTOAFILIADO");
                entity.Property(e => e.MontoReclamado).HasColumnName("MONTOREC");
                entity.Property(e => e.Frecuencia).HasColumnName("FRECUENCIA");


            });
            modelBuilder.Entity<ReclamacionPss>(entity =>
            {
                entity.ToTable("P_OBTENER_RECLAMACIONES_PSS");
                entity.HasNoKey();
                entity.Property(e => e.Ano).HasColumnName("ANO");
                entity.Property(e => e.Compania).HasColumnName("COMPANIA");
                entity.Property(e => e.Ramo).HasColumnName("RAMO");
                entity.Property(e => e.Secuencial).HasColumnName("SECUENCIAL");
                entity.Property(e => e.UsuarioIngreso).HasColumnName("USU_ING");
                entity.Property(e => e.TipoServicio).HasColumnName("TIP_SER");
                entity.Property(e => e.FechaApertura).HasColumnName("FEC_APE");
                entity.Property(e => e.Estatus).HasColumnName("ESTATUS");
                entity.Property(e => e.DescripcionEstatus).HasColumnName("DESCRIPCION_ESTATUS");
                entity.Property(e => e.NumeroPlastico).HasColumnName("NUM_PLA");
                entity.Property(e => e.MontoReclamado).HasColumnName("SUM(C.MON_REC)");
                entity.Property(e => e.MontoPagado).HasColumnName("SUM(C.MON_PAG)");
                entity.Property(e => e.MontoAsegurado).HasColumnName("SUM(C.MON_COASEG)");


            });
            modelBuilder.Entity<Nucleo>(entity =>
            {
                entity.ToTable("P_OBTENER_NUCLEO_POR_NUM_PLA");
                entity.HasNoKey();
                entity.Property(e => e.Poliza).HasColumnName("POLIZA");
                entity.Property(e => e.Cedula).HasColumnName("CEDULA");
                entity.Property(e => e.Nombres).HasColumnName("NOMBRES");
                entity.Property(e => e.Apellidos).HasColumnName("APELLIDOS");
                entity.Property(e => e.Sexo).HasColumnName("SEXO");

            });
            modelBuilder.Entity<Procedimiento>(entity =>
            {
                entity.ToTable("P_OBTENER_PROCEDIMIENTOS_PSS");
                entity.HasNoKey();
                entity.Property(e => e.Codigo).HasColumnName("CODIGO");
                entity.Property(e => e.Nombre).HasColumnName("NOMBRE");
                entity.Property(e => e.Tipo).HasColumnName("TIPO");
                entity.Property(e => e.Servicio).HasColumnName("SERVICIO");
                entity.Property(e => e.TipoServicio).HasColumnName("TIPO_SERVICIO");
                entity.Property(e => e.Cobertura).HasColumnName("COBERTURA");
                entity.Property(e => e.NombreCobertura).HasColumnName("NOMBRE_COBERTURA");

            });

            modelBuilder.Entity<ProcedimientoNoServicio>(entity =>
            {
                entity.ToTable("P_OBTENER_PROCEDIMIENTOS_PSSV2");
                entity.HasNoKey();
                entity.Property(e => e.Codigo).HasColumnName("CODIGO");
                entity.Property(e => e.Nombre).HasColumnName("NOMBRE");
                entity.Property(e => e.Tipo).HasColumnName("TIPO");
                entity.Property(e => e.Servicio).HasColumnName("SERVICIO");
                entity.Property(e => e.Cobertura).HasColumnName("COBERTURA");
                entity.Property(e => e.NombreCobertura).HasColumnName("NOMBRE_COBERTURA");
            });

            modelBuilder.Entity<Precertificacion>(entity =>
            {
                entity.ToTable("P_DATOS_PRECERTIFICACION");
                entity.HasNoKey();
                entity.Property(e => e.Prefijo).HasColumnName("PRE_FIJO");
                entity.Property(e => e.Secuencial).HasColumnName("SECUENCIAL");
                entity.Property(e => e.Compania).HasColumnName("COMPANIA");
                entity.Property(e => e.Ramo).HasColumnName("RAMO");
                entity.Property(e => e.SecuenciaPoliza).HasColumnName("SEC_POL");
                entity.Property(e => e.Plan).HasColumnName("PLAN");
                entity.Property(e => e.DescripcionPlan).HasColumnName("DSP_PLAN");
                entity.Property(e => e.TipoReclamante).HasColumnName("TIP_REC");
                entity.Property(e => e.CodigoPss).HasColumnName("CODIGO_PSS");
                entity.Property(e => e.NombrePss).HasColumnName("NOMBRE_PSS");
                entity.Property(e => e.TipoHos).HasColumnName("TIP_P_HOS");
                entity.Property(e => e.PerHos).HasColumnName("PER_HOS");
                entity.Property(e => e.DepUso).HasColumnName("DEP_USO");
                entity.Property(e => e.NumeroPlastico).HasColumnName("NUM_PLA");
                entity.Property(e => e.NumeroAsegurado).HasColumnName("NOM_ASEGURADO");
                entity.Property(e => e.NumeroCedula).HasColumnName("NUM_CEDULA");
                entity.Property(e => e.FechaIngreso).HasColumnName("FEC_ING");
                entity.Property(e => e.FechaTransaccion).HasColumnName("FEC_TRA");
                entity.Property(e => e.UsuarioIngreso).HasColumnName("USU_ING");
                entity.Property(e => e.Estatus).HasColumnName("ESTATUS");
                entity.Property(e => e.DescripcionEstatus).HasColumnName("DSP_ESTATUS");
                entity.Property(e => e.Servicio).HasColumnName("SERVICIO");
                entity.Property(e => e.TipoCobertura).HasColumnName("TIP_COB");
                entity.Property(e => e.Cobertura).HasColumnName("COBERTURA");
                entity.Property(e => e.DescripcionCobertura).HasColumnName("DSP_COBERTURA");
                entity.Property(e => e.MontoLimite).HasColumnName("LIM_AFI");
                entity.Property(e => e.MontoReclamado).HasColumnName("MON_REC");
                entity.Property(e => e.Frecuencia).HasColumnName("FRECUENCIA");
                entity.Property(e => e.MontoReserva).HasColumnName("RESERVA");
                entity.Property(e => e.MontoPagado).HasColumnName("MON_PAG");
                entity.Property(e => e.MontoPagadoAfiliado).HasColumnName("MON_PAG_AFI");

            });

			modelBuilder.Entity<Diagnostico>(entity =>
			{
				entity.ToTable("DIAGNOSTICO", "DBAPER");
                entity.HasNoKey();

				entity.Property(x => x.Codigo).HasColumnName("CODIGO");
				entity.Property(x => x.Descripcion).HasColumnName("DESCRIPCION");
			});

		}
    }
}