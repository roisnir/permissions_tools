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
        public String DirPath {get; set;}
        public String Name => Path.GetFileName(DirPath);
        public String DirBasePath => Path.GetDirectoryName(DirPath);
        public List<AccessRule> AccessRules {get;}

        public DirectoryPermissions(string dirPath, bool recursive=true)
        {
            DirPath = dirPath;
            AccessRules = GetAccessRules(this, recursive).ToList();
        }
        public static IEnumerable<AccessRule> GetAccessRules(DirectoryPermissions dir, bool recursive=true)
        {
            var acCollection = new DirectoryInfo(dir.DirPath).GetAccessControl().GetAccessRules(
                true, true, typeof(System.Security.Principal.NTAccount));
            foreach (FileSystemAccessRule ace in acCollection)
            {
                var rule = new AccessRule(dir, ace);
                if (!rule.IsExpandable)
                {
                    bool excluded = UsersExclude.Contains(rule.Account.DisplayName) || UsersExclude.Contains(rule.Account.UserName) || rule.Account.IsEnabled == false;
                    if (!excluded) yield return rule;
                    continue;
                }
                foreach (var subRule in rule.Expand())
                {
                    if (UsersExclude.Contains(subRule.Account.DisplayName) || UsersExclude.Contains(subRule.Account.UserName) || (subRule.Account.IsEnabled == false)) continue;
                    yield return subRule;
                }
            }
        }



    }
}
