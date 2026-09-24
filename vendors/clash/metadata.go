package clash

import (
	"net/url"
	"strconv"

	"github.com/metacubex/mihomo/constant"
)

func urlToMetadata(rawURL string, network constant.NetWork) (addr constant.Metadata, err error) {
	u, err := url.Parse(rawURL)
	if err != nil {
		return
	}

	port := u.Port()
	if port == "" {
		switch u.Scheme {
		case "https":
			port = "443"
		case "http":
			port = "80"
		default:
			return
		}
	}

	portNum, err := strconv.ParseUint(port, 10, 16)
	if err != nil {
		return
	}

	addr = constant.Metadata{
		NetWork: network,
		Host:    u.Hostname(),
		DstPort: uint16(portNum),
	}
	return
}
