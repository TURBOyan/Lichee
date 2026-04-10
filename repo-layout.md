# 项目结构与来源

本仓库顶层工作区由 `repo` 统一管理，不再使用 Git submodule。

在 Gitea 中浏览这个仓库时，可以按下面的方式理解主要目录：


| 目录                       | 用途                    | 来源                                                                                   |
| ------------------------ | --------------------- | ------------------------------------------------------------------------------------ |
| `linux/`                 | Linux 内核源码            | `https://github.com/TURBOyan/lichee_linux.git`，分支 `zero-5.2.y`                       |
| `Lichee-Pi_u-boot/`      | U-Boot 启动源码           | `https://gitea.turboyan.com/turboyan/Lichee-Pi_u-boot.git`，分支 `v3s-spi-experimental` |
| `buildroot-2024.02.5/`   | Buildroot 根文件系统与工具链配置 | `https://gitea.turboyan.com/turboyan/buildroot.git`，分支 `zero-2024.02.5`              |
| `toolchain/sunxi-tools/` | Allwinner 平台辅助工具      | `https://gitea.turboyan.com/turboyan/sunxi-tools.git`                                |
| `libs_src/evtest/`       | `evtest` 依赖源码         | `https://gitlab.freedesktop.org/libevdev/evtest.git`                                 |
| `libs_src/lirc/`         | `lirc` 依赖源码           | `git://git.code.sf.net/p/lirc/git`                                                   |
| `app/TBaseCode/`         | 应用侧代码                 | 本项目工作区内业务代码                                                                          |
| `Pack/`                  | 打包与镜像相关内容             | 本项目工作区内打包内容                                                                          |
| `publish/`               | 编译输出目录                | 本地构建产物目录                                                                             |
| `toolchain/`             | 交叉编译工具链与辅助工具          | 本地工具链目录                                                                              |


## 说明

- 顶层 `.gitignore` 已忽略这些由 `repo` 管理的外部源码目录，避免被顶层 Git 误判为普通跟踪文件。
- 原 `.gitmodules` 已移除，防止 Gitea 和 Git 客户端继续把这些目录识别成 submodule。
- `build.sh --pull` 现在应理解为同步 `repo` 工作区源码，而不是执行 `git submodule update`。

