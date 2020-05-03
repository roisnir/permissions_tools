using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;
using System.Security.AccessControl;
using System.Threading.Tasks;
using System.DirectoryServices.AccountManagement;

namespace PermissionsReporter
{
    public class DirectoryPermissions
    {
        public static List<string> UsersExclude = new List<string>{
            @"NT AUTHORITY\SYSTEM",
            @"Microsoft Exchange Approval Assistant",
            @"Discovery Search Mailbox",
            @"Microsoft Exchange",
            @"OWNER RIGHTS",
            @"CREATOR OWNER",
            @"COMPUGATE-EX$",
            @"ServerAdmin$",
            @"NT AUTHORITY\Authenticated Users"
        };

        public static List<string> UsersWhitelist= new List<string>();

        public String DirPath {get; set;}
        public String Name => Path.GetFileName(DirPath);
        public String DirBasePath => Path.GetDirectoryName(DirPath);
        public List<AccessRule> AccessRules {get;}

        public DirectoryPermissions(string dirPath, bool recursive=true)
        {
            DirPath = dirPath;
            AccessRules = GetAccessRules(this, recursive);
        }

        private static bool IsExcluded(Entity account)
        { 
            return UsersExclude.Contains(account.DisplayName) || 
                   UsersExclude.Contains(account.UserName) ||
                   account.IsEnabled == false ||
                   (
                     (!UsersWhitelist.Contains(account.DisplayName)) &&
                     (!UsersWhitelist.Contains(account.UserName))
                   );
        }

        private static void AddRule(List<AccessRule> accessRules, AccessRule rule)
        {
            if (IsExcluded(rule.Account))
            {
                return;
            }
            var existing = accessRules.Find(r => r.Account.UserName == rule.Account.UserName);
            if (existing is null)
            {
                accessRules.Add(rule);
            }
            else
            {
                rule.Rights |= existing.Rights;
            }
        }

        public static List<AccessRule> GetAccessRules(DirectoryPermissions dir, bool recursive=true)
        {
            List<AccessRule> accessRules = new List<AccessRule>();
            var acCollection = new DirectoryInfo(dir.DirPath).GetAccessControl().GetAccessRules(
                true, true, typeof(System.Security.Principal.NTAccount));
            foreach (FileSystemAccessRule ace in acCollection)
            {
                var rule = new AccessRule(dir, ace);
                if (!rule.IsExpandable)
                {
                    AddRule(accessRules, rule);
                    continue;
                }
                foreach (var subRule in rule.Expand())
                {
                    AddRule(accessRules, subRule);
                }
            }
            return accessRules;
        }



    }
}
