# XMake 构建系统 - autotools/cmake 兼容性自动化处理

## 概述

本项目提供了自动化工具来处理 autotools/cmake 与 xmake 之间的兼容性问题，特别是宏定义缺失导致的编译错误。

## 问题背景

在使用 xmake 构建 libcurl 时，可能会遇到以下问题：
- `BUILDING_LIBCURL` 宏未定义
- `Curl_dyn_addn` 等函数参数不匹配
- 其他 autotools/cmake 特有的宏定义缺失

## 自动化解决方案

### 1. 运行自动分析脚本

```bash
# 分析 CMake 和 autotools 配置，生成对应的 xmake 宏定义
xmake l scripts/run_auto_defines.lua
```

这个脚本会：
- 分析 `CMakeLists.txt` 中的 `add_definitions`
- 分析 `lib/curl_config.h.cmake` 中的 `#cmakedefine`
- 分析 `configure.ac` 中的 `AC_DEFINE`
- 分析现有的 `lib/curl_config.h` 中的 `#define`
- 生成 `auto_defines.lua` 文件

### 2. 自动加载生成的配置

`xmake.lua` 已经配置为自动加载生成的宏定义：

```lua
-- Auto-load generated defines if available
local auto_defines_file = "auto_defines.lua"
if os.isfile(auto_defines_file) then
    print("Loading auto-generated defines from " .. auto_defines_file)
    dofile(auto_defines_file)
end
```

### 3. 手动添加关键宏定义

如果自动分析不够完整，可以手动添加关键宏定义：

```lua
-- 在 xmake.lua 的 add_defines 区域添加
add_defines("BUILDING_LIBCURL")  -- 解决 Curl_dyn_addn 宏问题
add_defines("HAVE_CONFIG_H")     -- 启用配置头文件
-- 其他需要的宏定义...
```

## 常见问题解决

### 问题 1: Curl_dyn_addn 参数不匹配

**错误信息：**
```
error: macro "Curl_dyn_addn" requires 3 arguments, but only 2 given
```

**解决方案：**
确保 `BUILDING_LIBCURL` 宏被定义：
```lua
add_defines("BUILDING_LIBCURL")
```

### 问题 2: 找不到类型或函数

**错误信息：**
```
error: 'xxx' undeclared
```

**解决方案：**
运行自动分析脚本，或手动添加对应的 `HAVE_XXX` 宏定义。

### 问题 3: 编译选项不匹配

**解决方案：**
检查 autotools/cmake 的编译选项，在 xmake.lua 中添加对应的配置。

## 脚本功能说明

### auto_defines.lua

主要功能模块：
- `extract_cmake_defines()`: 从 CMake 文件提取 `add_definitions`
- `extract_cmake_config_defines()`: 从 `curl_config.h.cmake` 提取 `#cmakedefine`
- `extract_autotools_defines()`: 从 `configure.ac` 提取 `AC_DEFINE`
- `extract_existing_config_defines()`: 从现有配置头文件提取 `#define`
- `generate_xmake_config()`: 生成最终的 xmake 配置
- `generate_xmake_snippet()`: 生成 xmake.lua 代码片段

### run_auto_defines.lua

运行脚本，执行自动分析并生成配置文件。

## 使用建议

1. **首次使用**：运行自动分析脚本生成基础配置
2. **遇到编译错误**：检查是否缺少宏定义，运行脚本重新生成
3. **更新依赖**：当 CMake 或 autotools 配置更新时，重新运行脚本
4. **手动调整**：根据具体需求手动调整生成的配置

## 注意事项

- 自动生成的配置可能包含一些不需要的宏定义
- 建议在生成后检查 `auto_defines.lua` 文件内容
- 某些平台特定的宏可能需要手动调整
- 定期更新自动生成的配置以保持与上游同步

## 故障排除

如果自动分析脚本无法正常工作：

1. 检查文件路径是否正确
2. 确认 CMake 和 autotools 配置文件存在
3. 手动添加已知的关键宏定义
4. 查看 xmake 构建日志获取更多错误信息 