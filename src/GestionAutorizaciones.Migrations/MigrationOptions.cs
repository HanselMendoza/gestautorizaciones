namespace GestionAutorizaciones.Migrations
{
    internal class MigrationOptions
    {
        public MigrationDirection MigrationDirection {get; set;}
        public long MigrationVersion {get; set;}

        public MigrationOptions() {
            MigrationDirection = MigrationDirection.Up;
            MigrationVersion = 0;
        }
    }
}