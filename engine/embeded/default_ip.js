// Default exit-IP resolver. Returns an array of egress IP strings,
// IPv4 and IPv6 (when available) detected through the active vendor.
function __ip_resolve_fetch(url) {
    try {
        var resp = fetch(url, { timeout: 3000, retry: 1 });
        if (!resp || resp.statusCode !== 200 || !resp.body) return '';
        return String(resp.body).trim();
    } catch (err) {
        return '';
    }
}

function ip_resolve_default() {
    var ips = [];
    var seen = {};

    var sources = [
        'https://api.ipify.org/',
        'https://api4.ipify.org/',
        'https://ifconfig.me/ip'
    ];
    for (var i = 0; i < sources.length; i++) {
        var v4 = __ip_resolve_fetch(sources[i]);
        if (v4 && v4.indexOf('.') >= 0 && !seen[v4]) {
            seen[v4] = true;
            ips.push(v4);
        }
        if (ips.length > 0) break;
    }

    var v6 = __ip_resolve_fetch('https://api6.ipify.org/');
    if (v6 && v6.indexOf(':') >= 0 && !seen[v6]) {
        seen[v6] = true;
        ips.push(v6);
    }

    return ips;
}
