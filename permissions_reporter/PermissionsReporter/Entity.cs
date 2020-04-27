using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.DirectoryServices.AccountManagement;
using System.DirectoryServices;

namespace PermissionsReporter
{
    public enum EntityTypeEnum
    {
        User,
        Group,
        Else
    }
    public class Entity : IEquatable<Entity>
    {
        public String Name { get; }

        public bool IsExpandable => EntityType == EntityTypeEnum.Group;
        private readonly Principal _principal;
        public static readonly PrincipalContext AdDomain = new PrincipalContext(ContextType.Domain, Environment.UserDomainName);

        public EntityTypeEnum EntityType
        {
            get
            {
                if (_principal is GroupPrincipal)
                    return EntityTypeEnum.Group;
                if (_principal is UserPrincipal)
                    return EntityTypeEnum.User;
                return EntityTypeEnum.Else;
            }
        }

        public bool? IsEnabled
        {
            get
            {   if (!(_principal is UserPrincipal)) return true;
                var dirEntry = (DirectoryEntry)(_principal.GetUnderlyingObject());
                var uac = (int)dirEntry.Properties["useraccountcontrol"].Value;
                return !Convert.ToBoolean(uac & 2);
            }
        }

        public Principal principal => _principal;

        public string DisplayName => _principal?.DisplayName ?? _principal?.SamAccountName ?? Name;
        public string UserName => _principal?.SamAccountName ?? Name;

        public Entity(string name)
        {
            Name = name;
            _principal = Principal.FindByIdentity(AdDomain, name);
        }
        public Entity(Principal principal)
        {
            _principal = principal;
            Name = _principal.Name;
        }
        public IEnumerable<Entity> Expand()
        {
            if (!IsExpandable)
                throw new Exception($"\"{_principal.Name}\" is not expandable");
            var members = ((GroupPrincipal) _principal).GetMembers(true).ToList();
            foreach (var memberPrincipal in members)
                yield return new Entity(memberPrincipal);
        }

        public bool Equals(Entity other)
        {
            return (_principal?.DistinguishedName ?? Name) == (other?._principal?.DistinguishedName ?? other?.Name);
        }

        public override bool Equals(object obj)
        {
            if (obj == null) return false;
            if (ReferenceEquals(this, obj)) return true;
            if (obj.GetType() != this.GetType()) return false;
            return Equals((Entity) obj);
        }

        public override int GetHashCode()
        {
            return (_principal?.DistinguishedName ?? Name).GetHashCode();
        }
    }
}
