using System;
using System.Collections.Generic;

namespace GestionAutorizaciones.Application.Auth.GetCurrentClient
{
    public class GetCurrentClientResponseDto
    {
        public string ClientName { get; set; }
        public string ClientId { get; set; }
        public bool? IsExternal { get; set; }
        public bool? IsActive { get; set; }
        public bool? Blocked { get; set; }
        public string CurrentResource { get; set; }
        public ICollection<string> Permissions { get; set; }
        public ICollection<ClientMetadataDto> Metadata { get; set; }
    }

    public class ClientMetadataDto
    {
        public string Key { get; set; }
        public string Value { get; set; }
    }
}