# Flutter Pet

这是电子宠物的 Flutter 版本，目标是做成一只可以在 `macOS` 上运行、后续可扩展后台悬浮窗的数码宠物 App。

当前已经包含：

- 原创可爱像素宠物
- 多分支成长与隐藏分支
- 时间制孵化
- 行动冷却与次数恢复
- 秘码系统
- Web 与桌面双存档兼容
- 主界面与“后台悬浮窗预览”UI
- 运行、打包、测试脚本

## 快速开始

```bash
cd /Users/chenyuming/Desktop/cym/电子宠物/flutter_pet
make setup
make run-web-server
```

打开:

- [http://localhost:8080](http://localhost:8080)

如果要跑桌面版:

```bash
make run-macos
```

## 常用命令

```bash
make analyze
make test
make run-web-server
make run-macos
make build-web
make build-macos
make build-apk
make build-aab
make build-ios
```

## 脚本入口

项目已经内置这些脚本:

- `tool/run_web.sh`
- `tool/run_macos.sh`
- `tool/run_ios.sh`
- `tool/run_android.sh`
- `tool/build_web.sh`
- `tool/build_macos.sh`
- `tool/build_apk.sh`
- `tool/build_aab.sh`
- `tool/build_ios.sh`

如果你的 Flutter 不在 PATH，可以这样指定:

```bash
FLUTTER_BIN="$HOME/fvm/cache.git/bin/flutter" make run-web-server
```

## 文档

- [运行与打包](./docs/RUN_AND_BUILD.md)
- [游戏规则](./docs/GAME_RULES.md)

## 当前状态说明

现在已经能：

- Web 跑起来试玩
- macOS 运行主界面
- 保存本地养成状态
- 体验孵化、训练、探索、战斗、秘码

还没完全做完的部分：

- 真正的 macOS 后台悬浮小窗
- 菜单栏常驻
- always-on-top 独立宠物窗口
- 开机自启

这些属于下一阶段的桌面集成能力，不是 Flutter 界面本身的问题。
