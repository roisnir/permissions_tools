using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Security.AccessControl;
using System.Text;
using System.Threading.Tasks;

namespace PermissionsReporter
{
    public class AccessRule
    {
        public DirectoryPermissions Dir { get; set; }
        public String DirName => Dir.Name;
        public String DirPath => Dir.DirPath;
        public Entity Account { get; set; }
        public AccessControlType Type { get; set; }
        public FileSystemRights Rights { get; set; }
        public String SimpleRights
        { 
            get 
            {
                if (Rights == FileSystemRights.FullControl)
                    return "Full Control";
                var _simpleRights = new List<string>();
                if (Rights.HasFlag(FileSystemRights.Read)) _simpleRights.Add("Read");
                if (Rights.HasFlag(FileSystemRights.Write)) _simpleRights.Add("Write");
                if (Rights.HasFlag(FileSystemRights.Delete)) _simpleRights.Add("Delete");
                if (Rights.HasFlag(FileSystemRights.Traverse)) _simpleRights.Add("Execute");
                if (_simpleRights.Count == 0) return Rights.ToString();
                if (_simpleRights.Count == 1) return _simpleRights[0];
                return $"{String.Join(", ", _simpleRights.GetRange(0, _simpleRights.Count - 1))} and {_simpleRights.Last()}";
            }
        }
        public bool IsInherited { get; set; }
        public bool IsExpandable => Account.IsExpandable;

        public AccessRule(DirectoryPermissions dir, string account, AccessControlType type, FileSystemRights rights, bool isInherited)
        {
            Dir = dir;
            Account = new Entity(account);
            Type = type;
            Rights = rights;
            IsInherited = isInherited;
        }
        public AccessRule(DirectoryPermissions dir, Entity account, AccessControlType type, FileSystemRights rights, bool isInherited)
        {
            Dir = dir;
            Account = account;
            Type = type;
            Rights = rights;
            IsInherited = isInherited;
        }
        public AccessRule(DirectoryPermissions dir, FileSystemAccessRule ace)
        {
            Dir = dir;
            Account = new Entity(ace.IdentityReference.Value);
            Type = ace.AccessControlType;
            Rights = ace.FileSystemRights;
            IsInherited = ace.IsInherited;
            
        }
        public AccessRule(FileSystemAccessRule ace)
        {
            Account = new Entity(ace.IdentityReference.Value);
            Type = ace.AccessControlType;
            Rights = ace.FileSystemRights;
            IsInherited = ace.IsInherited;
        }

        public IEnumerable<AccessRule> Expand()
        {
            if (!Account.IsExpandable)
                throw new Exception("access rule is not expandable");
            foreach (Entity entity in Account.Expand())
                yield return new AccessRule(Dir, entity, Type, Rights, IsInherited);
        }

        public override string ToString()
        {
            string s = $"{DirName} - {Account.DisplayName} - {Rights}";
            if (IsInherited)
                s += " - Inherited";
            return s;
        }
        public string ToStringDir()
        {
            string s = $"{Account.DisplayName} - {Rights}";
            if (IsInherited)
                s += " - Inherited";
            return s;
        }
        public string ToStringUser()
        {
            string s = $"{Dir.DirPath} - {Rights}";
            if (IsInherited)
                s += " - Inherited";
            return s;
        }
    }
}