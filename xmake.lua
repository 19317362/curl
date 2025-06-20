-- xmake.lua for libcurl
-- Supports: msvc, x64-linux, arm-linux, arm64-linux, arm32-android, arm64-android

-- 设置项目信息
set_project("test_add_defines")
set_version("8.5.0")
set_description("The multiprotocol file transfer library")
set_license("MIT/X derivate license")

-- 设置语言标准
set_languages("c99")

-- 设置警告级别
set_warnings("all")

-- 设置构建模式
add_rules("mode.debug", "mode.release")

-- 定义选项
option("shared")
    set_default(false)
    set_showmenu(true)
    set_description("Build shared library")
option_end()

option("static")
    set_default(true)
    set_showmenu(true)
    set_description("Build static library")
option_end()

option("curl_exe")
    set_default(true)
    set_showmenu(true)
    set_description("Build curl executable")
option_end()

option("ssl")
    set_default(true)
    set_showmenu(true)
    set_description("Enable SSL support")
option_end()

option("openssl")
    set_default(false)
    set_showmenu(true)
    set_description("Use OpenSSL")
option_end()

option("wolfssl")
    set_default(false)
    set_showmenu(true)
    set_description("Use wolfSSL")
option_end()

option("mbedtls")
    set_default(false)
    set_showmenu(true)
    set_description("Use mbedTLS")
option_end()

option("zlib")
    set_default(false)
    set_showmenu(true)
    set_description("Enable zlib support")
option_end()

option("brotli")
    set_default(false)
    set_showmenu(true)
    set_description("Enable brotli support")
option_end()

option("zstd")
    set_default(false)
    set_showmenu(true)
    set_description("Enable zstd support")
option_end()

option("ares")
    set_default(false)
    set_showmenu(true)
    set_description("Enable c-ares support")
option_end()

option("http2")
    set_default(false)
    set_showmenu(true)
    set_description("Enable HTTP/2 support")
option_end()

option("http3")
    set_default(false)
    set_showmenu(true)
    set_description("Enable HTTP/3 support")
option_end()

option("ipv6")
    set_default(true)
    set_showmenu(true)
    set_description("Enable IPv6 support")
option_end()

option("threads")
    set_default(true)
    set_showmenu(true)
    set_description("Enable threaded resolver")
option_end()

option("debug")
    set_default(false)
    set_showmenu(true)
    set_description("Enable debug features")
option_end()

option("verbose")
    set_default(false)
    set_showmenu(true)
    set_description("Enable verbose strings")
option_end()

-- 禁用功能选项
option("disable_altsvc")
    set_default(false)
    set_showmenu(true)
    set_description("Disable alt-svc support")
option_end()

option("disable_cookies")
    set_default(false)
    set_showmenu(true)
    set_description("Disable cookies support")
option_end()

option("disable_ftp")
    set_default(false)
    set_showmenu(true)
    set_description("Disable FTP")
option_end()

option("disable_http")
    set_default(false)
    set_showmenu(true)
    set_description("Disable HTTP")
option_end()

option("disable_ldap")
    set_default(false)
    set_showmenu(true)
    set_description("Disable LDAP")
option_end()

option("disable_proxy")
    set_default(false)
    set_showmenu(true)
    set_description("Disable proxy support")
option_end()

option("disable_rtsp")
    set_default(false)
    set_showmenu(true)
    set_description("Disable RTSP")
option_end()

option("disable_smb")
    set_default(false)
    set_showmenu(true)
    set_description("Disable SMB")
option_end()

option("disable_smtp")
    set_default(false)
    set_showmenu(true)
    set_description("Disable SMTP")
option_end()

option("disable_telnet")
    set_default(false)
    set_showmenu(true)
    set_description("Disable Telnet")
option_end()

option("disable_tftp")
    set_default(false)
    set_showmenu(true)
    set_description("Disable TFTP")
option_end()

-- 平台特定选项
if is_plat("windows") then
    option("unicode")
        set_default(false)
        set_showmenu(true)
        set_description("Use Unicode version of Windows API")
    option_end()
    
    option("static_crt")
        set_default(false)
        set_showmenu(true)
        set_description("Build with static CRT")
    option_end()
end

-- 添加依赖包
add_requires("openssl", {optional = true})
add_requires("wolfssl", {optional = true})
add_requires("mbedtls", {optional = true})
add_requires("zlib", {optional = true})
add_requires("brotli", {optional = true})
add_requires("zstd", {optional = true})
add_requires("cares", {optional = true})
add_requires("nghttp2", {optional = true})
add_requires("nghttp3", {optional = true})
add_requires("quiche", {optional = true})

-- libcurl 库目标
target("libcurl")
    set_kind("static")
    set_default(true)
    
    -- 设置语言标准
    set_languages("c99")
    
    -- 设置警告级别
    set_warnings("all")
    
    -- 添加编译定义
    add_defines("BUILDING_LIBCURL")
    add_defines("CURL_STATICLIB")
    
    if has_config("debug") then
        add_defines("DEBUGBUILD")
    end
    
    if has_config("verbose") then
        add_defines("CURL_DISABLE_VERBOSE_STRINGS")
    end
    
    -- 添加源文件
    add_files("lib/*.c")
    add_files("lib/vauth/*.c")
    add_files("lib/vtls/*.c")
    add_files("lib/vssh/*.c")
    add_files("lib/vquic/*.c")
    
    -- 添加头文件
    add_headerfiles("include/curl/*.h")
    add_headerfiles("lib/*.h")
    add_headerfiles("lib/vauth/*.h")
    add_headerfiles("lib/vtls/*.h")
    add_headerfiles("lib/vssh/*.h")
    add_headerfiles("lib/vquic/*.h")
    
    -- 添加包含目录
    add_includedirs("include")
    add_includedirs("lib")
    add_includedirs("$(builddir)")
    
    -- SSL 支持
    if has_config("ssl") then
        if has_config("openssl") then
            add_packages("openssl")
            add_defines("USE_OPENSSL")
        elseif has_config("wolfssl") then
            add_packages("wolfssl")
            add_defines("USE_WOLFSSL")
        elseif has_config("mbedtls") then
            add_packages("mbedtls")
            add_defines("USE_MBEDTLS")
        end
    end
    
    -- 压缩支持
    if has_config("zlib") then
        add_packages("zlib")
        add_defines("HAVE_LIBZ")
    end
    
    if has_config("brotli") then
        add_packages("brotli")
        add_defines("HAVE_BROTLI")
    end
    
    if has_config("zstd") then
        add_packages("zstd")
        add_defines("HAVE_ZSTD")
    end
    
    -- c-ares 支持
    if has_config("ares") then
        add_packages("cares")
        add_defines("USE_ARES")
    end
    
    -- HTTP/2 支持
    if has_config("http2") then
        add_packages("nghttp2")
        add_defines("USE_NGHTTP2")
    end
    
    -- HTTP/3 支持
    if has_config("http3") then
        add_packages("nghttp3")
        add_defines("USE_NGHTTP3")
    end
    
    -- IPv6 支持
    if has_config("ipv6") then
        add_defines("ENABLE_IPV6")
    end
    
    -- 线程支持
    if has_config("threads") then
        add_defines("USE_THREADS_POSIX")
    end
    
    -- 禁用功能
    if has_config("disable_altsvc") then
        add_defines("CURL_DISABLE_ALTSVC")
    end
    
    if has_config("disable_cookies") then
        add_defines("CURL_DISABLE_COOKIES")
    end
    
    if has_config("disable_ftp") then
        add_defines("CURL_DISABLE_FTP")
    end
    
    if has_config("disable_http") then
        add_defines("CURL_DISABLE_HTTP")
    end
    
    if has_config("disable_ldap") then
        add_defines("CURL_DISABLE_LDAP")
    end
    
    if has_config("disable_proxy") then
        add_defines("CURL_DISABLE_PROXY")
    end
    
    if has_config("disable_rtsp") then
        add_defines("CURL_DISABLE_RTSP")
    end
    
    if has_config("disable_smb") then
        add_defines("CURL_DISABLE_SMB")
    end
    
    if has_config("disable_smtp") then
        add_defines("CURL_DISABLE_SMTP")
    end
    
    if has_config("disable_telnet") then
        add_defines("CURL_DISABLE_TELNET")
    end
    
    if has_config("disable_tftp") then
        add_defines("CURL_DISABLE_TFTP")
    end
    
    -- 平台特定配置
    if is_plat("windows") then
        add_defines("WIN32")
        add_defines("_WIN32")
        add_syslinks("ws2_32", "bcrypt", "crypt32", "advapi32")
        if has_config("unicode") then
            add_defines("UNICODE")
            add_defines("_UNICODE")
        end
        if has_config("static_crt") then
            add_defines("_MT")
            add_defines("_DLL")
        end
    elseif is_plat("linux") then
        add_defines("HAVE_CONFIG_H")
        add_syslinks("pthread")
    elseif is_plat("android") then
        add_defines("HAVE_CONFIG_H")
        add_syslinks("log")
    end
    
    -- 安装配置
    on_install(function (target)
        os.cp(target:targetfile(), target:installdir("lib"))
        os.cp("include/curl/*.h", target:installdir("include/curl"))
    end)
target_end()

target("test")
    set_kind("binary")
    add_files("src/main.c")
    add_defines("TEST_DEFINE")

-- curl可执行文件目标
if has_config("curl_exe") then
    target("curl")
        set_kind("binary")
        set_default(false)
        
        -- 设置语言标准
        set_languages("c99")
        
        -- 设置警告级别
        set_warnings("all")
        
        -- 添加编译定义
        add_defines("BUILDING_CURL")
        
        if has_config("debug") then
            add_defines("DEBUGBUILD")
        end
        
        -- 添加源文件
        add_files("src/*.c")
        add_files("src/tool_*.c")
        
        -- 添加头文件
        add_headerfiles("src/*.h")
        
        -- 添加包含目录
        add_includedirs("include")
        add_includedirs("lib")
        add_includedirs("src")
        add_includedirs("$(builddir)")
        
        -- 添加依赖
        add_deps("libcurl")
        
        -- 平台特定库
        if is_plat("windows") then
            add_syslinks("ws2_32", "bcrypt")
            if has_config("unicode") then
                add_syslinks("kernel32")
            end
        elseif is_plat("linux") then
            add_syslinks("pthread")
        elseif is_plat("android") then
            add_syslinks("log")
        end
        
        -- 生成tool_hugehelp.c
        before_build(function (target)
            local hugehelp_c = path.join("$(builddir)", "tool_hugehelp.c")
            local hugehelp_content = [[
/* Generated by xmake - do not edit */
#include "tool_hugehelp.h"
]]
            io.writefile(hugehelp_c, hugehelp_content)
        end)
        
        -- 安装配置
        on_install(function (target)
            os.cp(target:targetfile(), target:installdir("bin"))
        end)
    target_end()
end 