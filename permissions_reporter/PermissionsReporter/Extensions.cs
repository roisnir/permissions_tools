using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PermissionsReporter
{
    static class Extensions
    {

        public static TValue GetValueOrDefault<TKey, TValue>(this IDictionary<TKey, TValue> dictionary, TKey key)
        {
            var value = dictionary.TryGetValue(key, out var ret) ? ret : default;
            return dictionary[key] = value;
        }

        public static TValue GetValueOrDefault<TKey, TValue>(this IDictionary<TKey, TValue> dictionary, TKey key, Func<TValue> getDefault)
        {
            if (dictionary.TryGetValue(key, out var ret))
                return ret;
            return dictionary[key] = getDefault();
        }

    }
}
