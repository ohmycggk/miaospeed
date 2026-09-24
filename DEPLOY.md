# MiaoSpeed 部署文档

本文档介绍 miaospeed 测速后端的部署与运维方式。镜像由 GitHub Actions 自动构建并推送到 GHCR。

## 1. Docker 部署（推荐）

### 1.1 镜像地址与标签

镜像发布在 GitHub Container Registry：

```
ghcr.io/ohmycggk/miaospeed
```

| 标签 | 说明 |
| --- | --- |
| `latest` | master 分支最新构建 |
| `master` | master 分支构建 |
| `sha-<commit>` | 指定提交的构建 |
| `v1.2.3` / `1.2` | 打 git tag 后生成的语义化版本 |

架构：`linux/amd64`、`linux/arm64`。

### 1.2 快速启动

```bash
docker run -d \
  --name miaospeed \
  --restart unless-stopped \
  -p 8080:8080 \
  -e TOKEN=请换成强随机串 \
  ghcr.io/ohmycggk/miaospeed:latest
```

> `TOKEN` 是「启动TOKEN」，用于对请求结构体做 SHA512 签名验证（见 README「对接」一节）。
> 不设置 `-token` 则任何能连到端口的人都能下发测速任务，**公网部署务必设置**。

等效的完整命令行写法（显式参数优先于环境变量）：

```bash
docker run -d --name miaospeed --restart unless-stopped -p 8080:8080 \
  ghcr.io/ohmycggk/miaospeed:latest \
  server -bind 0.0.0.0:8080 -token 请换成强随机串
```

### 1.3 docker-compose

```yaml
services:
  miaospeed:
    image: ghcr.io/ohmycggk/miaospeed:latest
    container_name: miaospeed
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      TOKEN: 请换成强随机串
      # BIND: 0.0.0.0:8080
    # 可选：挂载本地 MaxMind mmdb 以离线查询 GeoIP
    # volumes:
    #   - ./mmdb:/data:ro
    # command: ["server", "-mmdb", "/data/GeoLite2-City.mmdb"]
```

启动：`docker compose up -d`

### 1.4 私有镜像登录

若 Package 可见性为 private，拉取前需要登录（使用有 `read:packages` 权限的 PAT）：

```bash
echo $GITHUB_PAT | docker login ghcr.io -u 你的GitHub用户名 --password-stdin
```

想让镜像可匿名拉取：GitHub → Packages → miaospeed → Package settings → Change visibility → Public。

## 2. 环境变量与参数

### 2.1 容器环境变量

| 变量 | 对应参数 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `TOKEN` | `-token` | 空 | 请求签名用的启动TOKEN |
| `BIND` | `-bind` | `0.0.0.0:8080` | 监听地址，也支持 unix socket（如 `/tmp/miao.sock`） |

### 2.2 `server` 子命令全部参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `-bind` | 空 | 监听地址，`0.0.0.0:8080` 或 unix socket 路径 |
| `-token` | 空 | 启动TOKEN，用于请求签名校验 |
| `-connthread` | `64` | 普通连通性任务的并行线程数 |
| `-speedlimit` | `0` | 测速限速（字节/秒），0 为不限速 |
| `-pausesecond` | `0` | 每次测速任务后暂停的秒数（限流保护） |
| `-mtls` | `false` | 启用内嵌自签证书的 TLS（wss） |
| `-nospeed` | `false` | 拒绝所有测速请求（只做连通性/流媒体测试） |
| `-mmdb` | 空 | 本地 MaxMind mmdb 路径，多个用英文逗号分隔，设置后 GeoIP 优先走本地库 |
| `-whitelist` | 空 | bot id 白名单，逗号分隔，如 `1111,2222` |

示例（限速 100MB/s、只测连通性、带白名单）：

```bash
docker run -d --name miaospeed -p 8080:8080 ghcr.io/ohmycggk/miaospeed:latest \
  server -bind 0.0.0.0:8080 -token xxx -speedlimit 104857600 -nospeed -whitelist 1111,2222
```

## 3. 验证与对接

### 3.1 服务验证

miaospeed 是 WebSocket 服务，没有 HTTP 健康检查端点。用普通 HTTP 访问会返回 `400 Bad Request`，**这是正常现象**，说明端口已存活：

```bash
curl -i http://127.0.0.1:8080/
# HTTP/1.1 400 Bad Request
```

WS 端点接受任意路径的升级请求，对接地址为 `ws://<IP>:8080/`（启用 `-mtls` 时为 `wss://`）。

### 3.2 客户端对接

对接流程（构建请求结构体 → 签名 → 通过 WS 发送 → 接收结果）见 [README.md](README.md)「如何对接」一节。签名需要两个 TOKEN：

- **启动TOKEN**：部署时通过 `-token` / `TOKEN` 设置；
- **编译TOKEN**：构建镜像时通过 GitHub Secret `BUILDTOKEN` 注入（未设置则使用占位值 `miaospeed|docker`）。若你的客户端需要校验编译TOKEN，请在仓库 Settings → Secrets and variables → Actions 中创建 `BUILDTOKEN`（多段用 `|` 分隔），重新触发构建后使用相同值对接。

## 4. 运维

### 4.1 升级

```bash
docker pull ghcr.io/ohmycggk/miaospeed:latest
docker rm -f miaospeed
# 重新执行 1.2 的 docker run（compose 则 docker compose up -d）
```

### 4.2 日志与排障

```bash
docker logs -f miaospeed        # 跟踪日志
docker stats miaospeed          # 观察带宽/CPU/内存
```

常见问题：

- **测速结果偏低**：默认测速文件走动态选择（见 `preconfigs/network.go`），也可在请求配置里用 `downloadURL` 指定；检查节点本身带宽与 `-speedlimit`。
- **GeoIP 全为空**：未配置 `-mmdb` 时使用内置默认脚本查询 ip-api.com，确认宿主机/节点出口能访问 `ip-api.com`（免费版仅 HTTP）；或挂载 mmdb 离线查询。
- **HTTPS 延迟测试失败**：镜像已内置 CA 根证书，若仍失败请检查节点本身。

### 4.3 TLS（可选）

`-mtls` 使用构建时生成的自签证书提供 wss。更推荐的做法是前置反代终止 TLS，例如 Caddy：

```
speed.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

此时容器端口只需绑定到本地：`-p 127.0.0.1:8080:8080`。

## 5. 自行构建镜像

```bash
git clone https://github.com/ohmycggk/miaospeed.git
cd miaospeed
docker build -t miaospeed:local .
# 注入编译TOKEN（可选）
docker build --secret id=buildtoken,src=./BUILDTOKEN.key -t miaospeed:local .
```

Dockerfile 会在构建期自动生成所需的嵌入文件（CA 根证书复用构建镜像的系统证书包、自签 miaoko 证书、默认 JS 脚本），无需手工准备。

## 6. CI/CD 说明

工作流：`.github/workflows/docker.yml`

- 触发：push 到 `master`、推送 `v*` 标签、手动 `workflow_dispatch`；PR 仅构建不推送。
- 推送目标：`ghcr.io/ohmycggk/miaospeed`，使用 `GITHUB_TOKEN` 认证，无需额外凭证。
- 可选 Secret：`BUILDTOKEN`（编译TOKEN，见 3.2）。
