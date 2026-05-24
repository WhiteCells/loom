# LOOM

LOOM 是一个用于管理本地 AI Agent 配置。

# 构建

```sh
cmake -B build
cmake --build build
```

# 打包

```sh
bash ./script/package-linux.sh
bash ./script/package-windows.cmd
bash ./script/package-macos.sh
```

# TODO

- [ ] Token 统计优化
- [ ] API 可用性检查
- [ ] 支持 Claude Code 配置
- [ ] 支持 Skills 管理
- [ ] 小窗模式, 支持 cli 模式
- [ ] 多节点配置
- [ ] 负载均衡
- [ ] 跨平台打包
