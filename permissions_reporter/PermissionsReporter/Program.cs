using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.AccessControl;
using System.Text;
using ShellProgressBar;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace PermissionsReporter
{
    class Program
    {
        private const int DefaultMaxDepth = 0;

        static void Main(string[] args)
        {
            List<string> excludedUsers = new List<string>();
            SetParams(args, out string baseDirPath, out int? _level, excludedUsers);
            if (_level == null)
                return;
            int level = (int)_level;
            DirectoryPermissions.UsersExclude.AddRange(excludedUsers);
            WriteLine($"Fetching directories...");
            var directoriesPaths = (level == -1 ? Directory.GetDirectories(baseDirPath, "*", SearchOption.AllDirectories) : RecursiveGlob(baseDirPath, level)).ToList();
            WriteLine($"Found {directoriesPaths.Count()} directories");
            WriteLine("Checking permissions...");

            // A
            var dirs = GetDirPerm(directoriesPaths);
            // // B
//            var totalDirs = directoriesPaths.Count;
//            int dirCount = 0;
//            var dirs = new List<DirectoryPermissions>();
            //            foreach (var dirPath in directoriesPaths)
            //            {
            //                dirs.Add(new DirectoryPermissions(dirPath));
            //                if (dirCount % (totalDirs / 10) == 0)
            //                    WriteLine($"{Math.Round((double)dirCount / totalDirs * 100)}% {dirCount} out of {totalDirs}");
            //                dirCount++;
            //            }
            WriteLine($"Checked {directoriesPaths.Count} directories");
            WriteLine("Writing directories report...");
            WriteLine($"Saved {WriteReport(dirs)}");
            using (var pBar = new ProgressBar(directoriesPaths.Count, "", ConsoleColor.White))
            {
                var dir = DirTree(baseDirPath, level, 0, pBar);
                WriteLine($"Saved {WriteJson(dir)}");
            }
            //            WriteLine("Writing directories report...");
            //            WriteLine($"Saved {WriteDirsReport(dirs)}");
            //            WriteLine("Writing users report...");
            //            WriteLine($"Saved {WriteUsersReport(dirs)}");
            WriteLine("Done!");
            WriteLine("press any key to exit");
            Console.ReadKey();
        }

        private static IEnumerable<DirectoryPermissions> GetDirPerm(List<string> dirsPaths)
        {
            var totalDirs = dirsPaths.Count;
            using (var pBar = new ProgressBar(totalDirs, "", ConsoleColor.White))
                foreach (var dirPath in dirsPaths)
                {
                    pBar.Tick($"{pBar.CurrentTick + 1} out of {pBar.MaxTicks}");
                    yield return new DirectoryPermissions(dirPath);
                }
        }

        private static IEnumerable<string> RecursiveGlob(string baseDir, int maxDepth, int curDepth = 0)
        {
            if (curDepth > maxDepth)
            {
                yield return baseDir;
                yield break;
            }

            yield return baseDir;
            foreach (string dir in Directory.EnumerateDirectories(baseDir))
            {
                foreach (string subDir in RecursiveGlob(dir, maxDepth, curDepth + 1))
                {
                    yield return subDir;
                }
            }
        }

        private static Dictionary<string, object> DirTree(string baseDir, int maxDepth, int curDepth = 0, ProgressBar pBar = null)
        {
            var children = new List<Dictionary<string, object>>();
            if (curDepth <= maxDepth)
                foreach (string dir in Directory.EnumerateDirectories(baseDir))
                    children.Add(DirTree(dir, maxDepth, curDepth + 1, pBar));
            var rules = new List<Dictionary<string, object>>();
            foreach (AccessRule rule in new DirectoryPermissions(baseDir).AccessRules)
            {
                rules.Add(new Dictionary<string, object> {
                    {"dirPath", rule.DirPath},
                    {"username", rule.Account.UserName},
                    {"displayName", rule.Account.DisplayName},
                    {"rights", (int)rule.Rights},
                    {"type", rule.Type.ToString()},
                    {"isInherited", rule.IsInherited},
                });
            }
            pBar?.Tick($"{pBar.CurrentTick + 1} out of {pBar.MaxTicks}");
            return new Dictionary<string, object>() {
                {"path", baseDir},
                {"children", children},
                {"permissions", rules}
            };
        }

        private static string GetCsvLine<T>(IEnumerable<T> line)
        {
            return String.Join(",", line.Select(s => $"\"{s}\""));
        }
        private static List<string> GetDirLine(DirectoryPermissions dir)
        {
            List<string> fields = new List<string> {dir.DirPath};
            foreach (var rule in dir.AccessRules)
                fields.Add(rule.ToStringDir());
            return fields;
        }

        private static List<string> GetUserLine(Entity user, List<AccessRule> rules)
        {
            var fields = new List<string>() {user.DisplayName};
            foreach (var rule in rules)
                fields.Add(rule.ToStringUser());
            return fields;
        }

        private static List<string> GetRuleLine(AccessRule rule)
        {
            return new List<string>() {
                rule.Dir.DirPath,
                rule.Account.DisplayName,
                (rule.Type == AccessControlType.Deny ? "Deny " : "") + rule.SimpleRights
            };
        }

        private static string WriteDirsReport(IEnumerable<DirectoryPermissions> dirs)
        {
            var today = DateTime.Today.ToString("yyyy_MM_dd");
            string filePath = Path.GetFullPath(today + "_directories_permissions_report.csv");
            using (var writer = new StreamWriter(filePath, false, Encoding.UTF8))
                foreach (var dir in dirs)
                    writer.WriteLine(GetCsvLine(GetDirLine(dir)));
            return filePath;
        }
        private static string WriteReport(IEnumerable<DirectoryPermissions> dirs)
        {
            var today = DateTime.Today.ToString("yyyy_MM_dd");
            string filePath = Path.GetFullPath(today + "_permissions_report.csv");
            using (var writer = new StreamWriter(filePath, false, Encoding.UTF8))
            {
                writer.WriteLine($"Permission Report {today}");
                writer.WriteLine(GetCsvLine(new string[] {"Directory Path", "Display Name", "Rights"}));
                foreach (var dir in dirs)
                {
                    foreach (var rule in dir.AccessRules)
                        writer.WriteLine(GetCsvLine(GetRuleLine(rule)));
                }
            }

            return filePath;
        }
        private static string WriteJson(Dictionary<string, object> dirTree)
        {
            var today = DateTime.Today.ToString("yyyy_MM_dd");
            string filePath = Path.GetFullPath(today + "_permissions.json");
            using (var writer = new StreamWriter(filePath, false, Encoding.UTF8))
            {
                string json = JsonSerializer.Serialize(dirTree);
                writer.Write(json);
            }

            return filePath;
        }

        private static string WriteUsersReport(IEnumerable<DirectoryPermissions> dirs)
        {
            var usersDict = new Dictionary<Entity, List<AccessRule>>();
            foreach (var dir in dirs)
                foreach (var rule in dir.AccessRules)
                {
                    var userRules = usersDict.GetValueOrDefault(rule.Account, () => new List<AccessRule>());
                    userRules.Add(rule);
                }
            var today = DateTime.Today.ToString("yyyy_MM_dd");
            string filePath = Path.GetFullPath(today + "_users_permissions_report.csv");
            using (var writer = new StreamWriter(filePath, false, Encoding.UTF8))
                foreach (var userPermissions in usersDict)
                    writer.WriteLine(GetCsvLine(GetUserLine(userPermissions.Key, userPermissions.Value)));
            return filePath;
        }

        private static void SetParams(IReadOnlyList<string> args, out string dirPath, out int? level, List<string> excludedUsers)
        {
            if (args.Count == 0)
            {
                dirPath = GetParam("Enter path:");
                var levelTemp = GetIntParam($"Enter max depth (-1 for None):", DefaultMaxDepth);
                level = levelTemp;
                return;
            }
            dirPath = args[0];
            if (args.Count == 1)
            {
                level = DefaultMaxDepth;
                return;
            }
            level = int.Parse(args[1]);
            for (int i = 2; i < args.Count; i++)
                excludedUsers.Add(args[i]);
        }

        private static string GetParam(string msg)
        {
            WriteLine(msg);
            Console.Write("> ");
            return Console.ReadLine();
        }

        private static void WriteLine(string msg)
        {
            Console.WriteLine(">>> " + msg);
        }

        private static int? GetIntParam(string msg, int? defaultValue)
        {
            var value = GetParam(msg);
            if (string.IsNullOrWhiteSpace(value) && defaultValue != null)
                return (int)defaultValue;
            int retVal;
            if (int.TryParse(value, out retVal))
                return retVal;
            Console.WriteLine("invalid value has been entered");
            return null;
        }

        private static void PrintDirPermissions(string dirPath)
        {
            DirectoryInfo dInfo = new DirectoryInfo(dirPath);
            DirectorySecurity dSecurity = dInfo.GetAccessControl();
            var accessRules = dSecurity.GetAccessRules(true, true, typeof(System.Security.Principal.NTAccount));
            string tabs = "\t";
            foreach (FileSystemAccessRule ace in accessRules)
            {
                Console.WriteLine("{0}Account: {1}", tabs, ace.IdentityReference.Value);
                Console.WriteLine("{0}Type: {1}", tabs, ace.AccessControlType);
                Console.WriteLine("{0}Rights: {1}", tabs, ace.FileSystemRights);
                Console.WriteLine("{0}Inherited: {1}", tabs, ace.IsInherited);
                Console.WriteLine();
            }
        }
    }
}
