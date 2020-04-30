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
        private static Dictionary<string, Entity> _cache = new Dictionary<string, Entity>();

        public string Name { get; }

        public bool IsExpandable => EntityType == EntityTypeEnum.Group;

        public static readonly PrincipalContext AdDomain = new PrincipalContext(ContextType.Domain, Environment.UserDomainName);

        public EntityTypeEnum EntityType
        {
            get
            {
                if (principal is GroupPrincipal)
                    return EntityTypeEnum.Group;
                if (principal is UserPrincipal)
                    return EntityTypeEnum.User;
                return EntityTypeEnum.Else;
            }
        }
        private bool? _isEnabled;

        public bool? IsEnabled
        {
            get
            {
                if (_isEnabled != null)
                    return _isEnabled;
                if (!(principal is UserPrincipal)) return true;
                var dirEntry = (DirectoryEntry)(principal.GetUnderlyingObject());
                var uac = (int)dirEntry.Properties["useraccountcontrol"].Value;
                _isEnabled = !Convert.ToBoolean(uac & 2);
                return _isEnabled;
            }
        }

        public Principal principal { get; }

        public string DisplayName => principal?.DisplayName ?? principal?.SamAccountName ?? Name;
        public string UserName => principal?.SamAccountName ?? Name;

        public Entity(string name)
        {
            Name = name;
            principal = Principal.FindByIdentity(AdDomain, name);
        }

        public static Entity GetEntity(string name)
        {
            if (_cache.ContainsKey(name))
                return _cache[name];
            return new Entity(name);
        }
        public static Entity GetEntity(Principal principal)
        {
            string name = principal?.DistinguishedName ?? principal?.SamAccountName ?? principal?.Name;
            if (_cache.ContainsKey(name))
                return _cache[name];
            return new Entity(principal);
        }

        public Entity(Principal principal, bool? isEnabled = null)
        {
            this.principal = principal;
            Name = this.principal.Name;
            _isEnabled = isEnabled;
        }
        public IEnumerable<Entity> Expand()
        {
            if (!IsExpandable)
                throw new Exception($"\"{principal.Name}\" is not expandable");
            var members = ((GroupPrincipal) principal).GetMembers(true);
            foreach (var memberPrincipal in members)
                yield return GetEntity(memberPrincipal);
        }

        public bool Equals(Entity other)
        {
            return (principal?.DistinguishedName ?? Name) == (other?.principal?.DistinguishedName ?? other?.Name);
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
            return (principal?.DistinguishedName ?? Name).GetHashCode();
        }
    }
}
