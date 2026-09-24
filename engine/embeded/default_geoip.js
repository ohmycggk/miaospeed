// Default GeoIP resolver backed by ip-api.com (no key required).
// Called with an egress IP string and must return an object shaped
// like interfaces.GeoInfo (json tags).
function handler(ip) {
    try {
        var resp = fetch(
            'http://ip-api.com/json/' + ip + '?fields=status,message,country,countryCode,continent,lat,lon,timezone,isp,org,as,query',
            { timeout: 3000, retry: 1 }
        );
        if (!resp || resp.statusCode !== 200 || !resp.body) return {};
        var data = safeParse(resp.body);
        if (get(data, 'status') !== 'success') return {};

        var asn = 0;
        var asnOrg = '';
        var m = /^AS(\d+)\s*(.*)$/.exec(get(data, 'as', ''));
        if (m) {
            asn = parseInt(m[1], 10) || 0;
            asnOrg = m[2] || '';
        }

        return {
            ip: get(data, 'query', ip),
            country: get(data, 'country', ''),
            country_code: get(data, 'countryCode', ''),
            continent_code: get(data, 'continent', ''),
            organization: get(data, 'org', ''),
            isp: get(data, 'isp', ''),
            asn: asn,
            asn_organization: asnOrg,
            latitude: get(data, 'lat', 0),
            longitude: get(data, 'lon', 0),
            timezone: get(data, 'timezone', '')
        };
    } catch (err) {
        return {};
    }
}
