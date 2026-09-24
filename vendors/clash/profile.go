package clash

import (
	"github.com/metacubex/mihomo/adapter"
	"github.com/metacubex/mihomo/constant"
	"github.com/miaokobot/miaospeed/interfaces"
	"github.com/miaokobot/miaospeed/utils"
	"gopkg.in/yaml.v2"
)

func parseProxy(proxyName, proxyPayload string) constant.Proxy {
	var payload map[string]any
	yaml.Unmarshal([]byte(proxyPayload), &payload)
	if payload == nil {
		utils.DLogf("Vendor Parser | Parse clash profile error, empty payload")
		return nil
	}
	if _, ok := payload["name"]; !ok {
		payload["name"] = proxyName
	}
	proxy, err := adapter.ParseProxy(payload)

	if err != nil {
		utils.DLogf("Vendor Parser | Parse clash profile error, error=%v", err.Error())
	}

	return proxy
}

func extractFirstProxy(proxyName, proxyPayload string) constant.Proxy {
	proxy := parseProxy(proxyName, proxyPayload)

	if proxy != nil && interfaces.Parse(proxy.Type().String()) != interfaces.ProxyInvalid {
		return proxy
	}

	return nil
}
