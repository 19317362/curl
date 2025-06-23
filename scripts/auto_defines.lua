--[[
    auto_defines.lua - 自动化处理 autotools/cmake 兼容性
    
    这个脚本分析 CMake 和 autotools 的配置文件，自动生成对应的 xmake 配置
    解决 BUILDING_LIBCURL 等宏定义缺失的问题
--]]

local auto_defines = {}

-- 平台特定的宏定义过滤
local platform_filters = {
    -- Windows 特定的宏，在非 Windows 平台上应该被过滤掉
    windows_only = {
        "HAVE_CLOSESOCKET",
        "HAVE_CLOSESOCKET_CAMEL", 
        "HAVE_IOCTLSOCKET",
        "HAVE_IOCTLSOCKET_CAMEL",
        "HAVE_IOCTLSOCKET_CAMEL_FIONBIO",
        "HAVE_IOCTLSOCKET_FIONBIO",
        "HAVE_WINSOCK2_H",
        "HAVE_WINDOWS_H",
        "USE_WINSOCK",
        "WIN32",
        "_WIN32",
        "_WIN32_WINNT",
        "WIN32_LEAN_AND_MEAN"
    },
    
    -- Unix/Linux 特定的宏，在 Windows 平台上应该被过滤掉
    unix_only = {
        "HAVE_UNISTD_H",
        "HAVE_SYS_TIME_H",
        "HAVE_SYS_SOCKET_H",
        "HAVE_SYS_SELECT_H",
        "HAVE_SYS_IOCTL_H",
        "HAVE_SYS_STAT_H",
        "HAVE_SYS_TYPES_H",
        "HAVE_NETDB_H",
        "HAVE_NETINET_IN_H",
        "HAVE_ARPA_INET_H",
        "HAVE_FCNTL_H",
        "HAVE_UTIME_H",
        "HAVE_PTHREAD_H",
        "USE_THREADS_POSIX"
    }
}

-- 检查当前平台
function auto_defines.get_platform()
    if os.host() == "windows" then
        return "windows"
    elseif os.host() == "linux" then
        return "linux"
    elseif os.host() == "macosx" then
        return "macosx"
    else
        return "unknown"
    end
end

-- 过滤平台特定的宏定义
function auto_defines.filter_platform_defines(defines)
    local platform = auto_defines.get_platform()
    local filtered = {}
    
    for _, def in ipairs(defines) do
        local should_include = true
        
        if platform == "windows" then
            -- 在 Windows 上，过滤掉 Unix 特定的宏
            for _, unix_def in ipairs(platform_filters.unix_only) do
                if def == unix_def then
                    should_include = false
                    break
                end
            end
        else
            -- 在非 Windows 平台上，过滤掉 Windows 特定的宏
            for _, win_def in ipairs(platform_filters.windows_only) do
                if def == win_def then
                    should_include = false
                    break
                end
            end
        end
        
        if should_include then
            table.insert(filtered, def)
        end
    end
    
    return filtered
end

-- 从 CMake 文件中提取 add_definitions
function auto_defines.extract_cmake_defines()
    local defines = {}
    
    -- 从主 CMakeLists.txt 提取
    local cmake_content = io.readfile("CMakeLists.txt")
    if cmake_content then
        for line in cmake_content:gmatch("[^\r\n]+") do
            local def = line:match('add_definitions%("?%-D([^"]+)"?%)')
            if def then
                table.insert(defines, def)
            end
        end
    end
    
    -- 从 lib/CMakeLists.txt 提取
    local lib_cmake_content = io.readfile("lib/CMakeLists.txt")
    if lib_cmake_content then
        for line in lib_cmake_content:gmatch("[^\r\n]+") do
            local def = line:match('add_definitions%("?%-D([^"]+)"?%)')
            if def then
                table.insert(defines, def)
            end
        end
    end
    
    -- 从 src/CMakeLists.txt 提取
    local src_cmake_content = io.readfile("src/CMakeLists.txt")
    if src_cmake_content then
        for line in src_cmake_content:gmatch("[^\r\n]+") do
            local def = line:match('add_definitions%("?%-D([^"]+)"?%)')
            if def then
                table.insert(defines, def)
            end
        end
    end
    
    return defines
end

-- 从 curl_config.h.cmake 提取 cmakedefine
function auto_defines.extract_cmake_config_defines()
    local defines = {}
    local config_content = io.readfile("lib/curl_config.h.cmake")
    
    if config_content then
        for line in config_content:gmatch("[^\r\n]+") do
            local def = line:match('#cmakedefine ([^%s]+)')
            if def then
                -- 排除一些特殊的 cmakedefine
                if not def:match("^CURL_") and not def:match("^USE_") then
                    table.insert(defines, def)
                end
            end
        end
    end
    
    return defines
end

-- 从 configure.ac 提取 AC_DEFINE
function auto_defines.extract_autotools_defines()
    local defines = {}
    local configure_content = io.readfile("configure.ac")
    
    if configure_content then
        for line in configure_content:gmatch("[^\r\n]+") do
            local def = line:match('AC_DEFINE%([^,]+,\\s*([^,]+)')
            if def then
                -- 清理引号
                def = def:gsub('"', '')
                if def ~= "1" and def ~= "0" then
                    table.insert(defines, def)
                end
            end
        end
    end
    
    return defines
end

-- 从现有的 curl_config.h 提取已定义的宏
function auto_defines.extract_existing_config_defines()
    local defines = {}
    local config_content = io.readfile("lib/curl_config.h")
    
    if config_content then
        for line in config_content:gmatch("[^\r\n]+") do
            local def = line:match('#define ([^%s]+)')
            if def then
                -- 排除一些特殊的定义
                if not def:match("^CURL_") and not def:match("^USE_") and not def:match("^_") then
                    table.insert(defines, def)
                end
            end
        end
    end
    
    return defines
end

-- 生成 xmake 配置
function auto_defines.generate_xmake_config()
    local all_defines = {}
    
    -- 收集所有来源的宏定义
    local cmake_defines = auto_defines.extract_cmake_defines()
    local cmake_config_defines = auto_defines.extract_cmake_config_defines()
    local autotools_defines = auto_defines.extract_autotools_defines()
    local existing_defines = auto_defines.extract_existing_config_defines()
    
    -- 合并所有定义
    for _, def in ipairs(cmake_defines) do
        all_defines[def] = true
    end
    
    for _, def in ipairs(cmake_config_defines) do
        all_defines[def] = true
    end
    
    for _, def in ipairs(autotools_defines) do
        all_defines[def] = true
    end
    
    for _, def in ipairs(existing_defines) do
        all_defines[def] = true
    end
    
    -- 转换为列表
    local define_list = {}
    for def, _ in pairs(all_defines) do
        table.insert(define_list, def)
    end
    
    -- 应用平台特定的过滤
    define_list = auto_defines.filter_platform_defines(define_list)
    
    -- 排序
    table.sort(define_list)
    
    return define_list
end

-- 生成 xmake.lua 片段
function auto_defines.generate_xmake_snippet()
    local defines = auto_defines.generate_xmake_config()
    local platform = auto_defines.get_platform()
    local snippet = "-- Auto-generated defines for autotools/cmake compatibility\n"
    snippet = snippet .. "-- Generated by scripts/auto_defines.lua\n"
    snippet = snippet .. "-- Platform: " .. platform .. "\n\n"
    
    for _, def in ipairs(defines) do
        snippet = snippet .. 'add_defines("' .. def .. '")\n'
    end
    
    return snippet
end

-- 主函数
function auto_defines.main()
    local platform = auto_defines.get_platform()
    print("Analyzing CMake and autotools configurations for platform: " .. platform)
    
    local defines = auto_defines.generate_xmake_config()
    print("Found " .. #defines .. " defines (after platform filtering):")
    
    for i, def in ipairs(defines) do
        print(string.format("%3d. %s", i, def))
    end
    
    print("\n" .. auto_defines.generate_xmake_snippet())
    
    -- 保存到文件
    local snippet = auto_defines.generate_xmake_snippet()
    io.writefile("auto_defines.lua", snippet)
    print("\nAuto-generated defines saved to auto_defines.lua")
end

return auto_defines 