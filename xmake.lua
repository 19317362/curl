--[[
    xmake.lua for libcurl
    
    This file provides cross-platform build configuration for libcurl using xmake.
    Supports: MSVC, x64-linux, arm-linux, arm64-linux, arm32-android, arm64-android
    
    Based on the original CMakeLists.txt configuration.
--]]

-- Set minimum xmake version
set_xmakever("2.7.3")

-- Set project information
set_project("curl")
set_version("8.11.1")
set_languages("c99")

-- Include directories
add_includedirs("include", "lib", {public = true})

-- Platform-specific configurations
if is_plat("windows") then
    add_defines("WIN32", "_WIN32_WINNT=0x0601")
    add_syslinks("ws2_32", "bcrypt", "advapi32", "crypt32")
    if is_mode("debug") then
        set_runtimes("MDd")
    else
        set_runtimes("MD")
    end
elseif is_plat("linux", "android") then
    add_defines("_GNU_SOURCE")
    -- Add large file support for Linux
    add_defines("_FILE_OFFSET_BITS=64")
    if is_plat("android") then
        add_defines("ANDROID")
    end
elseif is_plat("macosx", "iphoneos") then
    add_frameworks("CoreFoundation", "Security", "SystemConfiguration")
end

-- Architecture-specific settings
if is_arch("arm.*") then
    add_defines("CURL_ARCH_ARM")
elseif is_arch("x86_64", "x64") then
    add_defines("CURL_ARCH_X64")
end

-- Essential curl configuration defines
add_defines("HAVE_CONFIG_H")
add_defines("STDC_HEADERS")
add_defines("HAVE_STRUCT_TIMEVAL")
add_defines("HAVE_STRUCT_SOCKADDR_STORAGE")
add_defines("HAVE_BOOL_T")
add_defines("HAVE_STDBOOL_H")

-- Socket and I/O support
add_defines("HAVE_FCNTL_O_NONBLOCK")

-- Disable optional features that require additional dependencies
add_defines("CURL_DISABLE_LDAP")
add_defines("CURL_DISABLE_LDAPS")

-- For tool compilation (src/ directory)
add_defines("BUILDING_CURL")

-- Auto-load generated defines if available
local auto_defines_file = "auto_defines.lua"
if os.isfile(auto_defines_file) then
    print("Loading auto-generated defines from " .. auto_defines_file)
    dofile(auto_defines_file)
end

-- Type size definitions (based on typical 64-bit systems)
add_defines("SIZEOF_CURL_OFF_T=8")
add_defines("SIZEOF_OFF_T=8")
add_defines("SIZEOF_LONG=8")
add_defines("SIZEOF_LONG_LONG=8")
add_defines("SIZEOF_SIZE_T=8")
add_defines("SIZEOF_TIME_T=8")
add_defines("SIZEOF_INT=4")
add_defines("SIZEOF_CURL_SOCKET_T=4")

-- Network and socket related defines
add_defines("HAVE_RECV")
add_defines("HAVE_SEND")
add_defines("HAVE_SELECT")
add_defines("HAVE_GETADDRINFO")
add_defines("HAVE_FREEADDRINFO")
add_defines("HAVE_GAI_STRERROR")
add_defines("HAVE_SOCKET")
add_defines("HAVE_CONNECT")
add_defines("HAVE_ACCEPT")
add_defines("HAVE_BIND")
add_defines("HAVE_LISTEN")
add_defines("HAVE_GETSOCKNAME")
add_defines("HAVE_GETPEERNAME")
add_defines("HAVE_SETSOCKOPT")
add_defines("HAVE_GETSOCKOPT")
add_defines("HAVE_CLOSESOCKET")
add_defines("HAVE_FCNTL")
add_defines("HAVE_IOCTL")
add_defines("HAVE_IOCTLSOCKET")

-- File system related defines
add_defines("HAVE_FSEEKO")
add_defines("HAVE_DECL_FSEEKO")
add_defines("HAVE_FTRUNCATE")
add_defines("HAVE_UTIME")
add_defines("HAVE_UTIMES")

-- Time related defines
add_defines("HAVE_CLOCK_GETTIME_MONOTONIC")
add_defines("HAVE_GETTIMEOFDAY")
add_defines("HAVE_TIME_H")
add_defines("HAVE_SYS_TIME_H")

-- System headers
add_defines("HAVE_SYS_TYPES_H")
add_defines("HAVE_SYS_SOCKET_H")
add_defines("HAVE_SYS_IOCTL_H")
add_defines("HAVE_SYS_SELECT_H")
add_defines("HAVE_SYS_STAT_H")
add_defines("HAVE_UNISTD_H")
add_defines("HAVE_STDLIB_H")
add_defines("HAVE_STRING_H")
add_defines("HAVE_STRINGS_H")
add_defines("HAVE_ERRNO_H")
add_defines("HAVE_STDIO_H")
add_defines("HAVE_FCNTL_H")
add_defines("HAVE_NETDB_H")
add_defines("HAVE_NETINET_IN_H")
add_defines("HAVE_ARPA_INET_H")
add_defines("HAVE_UTIME_H")

-- Threading support
add_defines("HAVE_PTHREAD_H")
add_defines("USE_THREADS_POSIX")

-- DNS resolution
add_defines("USE_THREADED_RESOLVER")

-- Configure options
option("ssl_backend")
    set_default("auto")
    set_values("auto", "openssl", "mbedtls", "schannel", "sectransp")
    set_description("SSL/TLS backend to use")
option_end()

option("enable_shared")
    set_default(true)
    set_description("Build shared library")
option_end()

option("enable_static")
    set_default(false)
    set_description("Build static library")
option_end()

option("enable_curl_exe")
    set_default(true)
    set_description("Build curl executable")
option_end()

option("disable_protocols")
    set_default("")
    set_description("Disable specific protocols (comma-separated)")
option_end()

-- Function to generate curl_config.h
-- Note: curl_config.h is pre-generated in lib/ directory
-- For dynamic generation based on build options, it can be implemented
-- using xmake's on_config() hooks in target definitions

-- SSL/TLS configuration based on platform  
local ssl_backend = get_config("ssl_backend")
if ssl_backend == "auto" then
    if is_plat("windows") then
        ssl_backend = "schannel"
    elseif is_plat("macosx", "iphoneos") then
        ssl_backend = "sectransp"
    else
        ssl_backend = "openssl"
    end
end

-- Define common source files
local LIB_VAUTH_CFILES = {
    "lib/vauth/cleartext.c",
    "lib/vauth/cram.c", 
    "lib/vauth/digest.c",
    "lib/vauth/digest_sspi.c",
    "lib/vauth/gsasl.c",
    "lib/vauth/krb5_gssapi.c",
    "lib/vauth/krb5_sspi.c",
    "lib/vauth/ntlm.c",
    "lib/vauth/ntlm_sspi.c",
    "lib/vauth/oauth2.c",
    "lib/vauth/spnego_gssapi.c",
    "lib/vauth/spnego_sspi.c",
    "lib/vauth/vauth.c"
}

local LIB_VTLS_CFILES = {
    "lib/vtls/bearssl.c",
    "lib/vtls/cipher_suite.c",
    "lib/vtls/gtls.c",
    "lib/vtls/hostcheck.c",
    "lib/vtls/keylog.c",
    "lib/vtls/mbedtls.c",
    "lib/vtls/mbedtls_threadlock.c",
    "lib/vtls/openssl.c",
    "lib/vtls/rustls.c",
    "lib/vtls/schannel.c",
    "lib/vtls/schannel_verify.c",
    "lib/vtls/sectransp.c",
    "lib/vtls/vtls.c",
    "lib/vtls/vtls_scache.c",
    "lib/vtls/wolfssl.c",
    "lib/vtls/x509asn1.c"
}

local LIB_VQUIC_CFILES = {
    "lib/vquic/curl_msh3.c",
    "lib/vquic/curl_ngtcp2.c",
    "lib/vquic/curl_osslq.c",
    "lib/vquic/curl_quiche.c",
    "lib/vquic/vquic.c",
    "lib/vquic/vquic-tls.c"
}

local LIB_VSSH_CFILES = {
    "lib/vssh/libssh.c",
    "lib/vssh/libssh2.c",
    "lib/vssh/curl_path.c",
    "lib/vssh/wolfssh.c"
}

local LIB_CFILES = {
    "lib/altsvc.c",
    "lib/amigaos.c",
    "lib/asyn-ares.c",
    "lib/asyn-thread.c",
    "lib/base64.c",
    "lib/bufq.c",
    "lib/bufref.c",
    "lib/cf-h1-proxy.c",
    "lib/cf-h2-proxy.c",
    "lib/cf-haproxy.c",
    "lib/cf-https-connect.c",
    "lib/cf-socket.c",
    "lib/cfilters.c",
    "lib/conncache.c",
    "lib/connect.c",
    "lib/content_encoding.c",
    "lib/cookie.c",
    "lib/curl_addrinfo.c",
    "lib/curl_des.c",
    "lib/curl_endian.c",
    "lib/curl_fnmatch.c",
    "lib/curl_get_line.c",
    "lib/curl_gethostname.c",
    "lib/curl_gssapi.c",
    "lib/curl_memrchr.c",
    "lib/curl_multibyte.c",
    "lib/curl_ntlm_core.c",
    "lib/curl_range.c",
    "lib/curl_rtmp.c",
    "lib/curl_sasl.c",
    "lib/curl_sha512_256.c",
    "lib/curl_sspi.c",
    "lib/curl_threads.c",
    "lib/curl_trc.c",
    "lib/cw-out.c",
    "lib/dict.c",
    "lib/doh.c",
    "lib/dynbuf.c",
    "lib/dynhds.c",
    "lib/easy.c",
    "lib/easygetopt.c",
    "lib/easyoptions.c",
    "lib/escape.c",
    "lib/file.c",
    "lib/fileinfo.c",
    "lib/fopen.c",
    "lib/formdata.c",
    "lib/ftp.c",
    "lib/ftplistparser.c",
    "lib/getenv.c",
    "lib/getinfo.c",
    "lib/gopher.c",
    "lib/hash.c",
    "lib/headers.c",
    "lib/hmac.c",
    "lib/hostasyn.c",
    "lib/hostip.c",
    "lib/hostip4.c",
    "lib/hostip6.c",
    "lib/hostsyn.c",
    "lib/hsts.c",
    "lib/http.c",
    "lib/http1.c",
    "lib/http2.c",
    "lib/http_aws_sigv4.c",
    "lib/http_chunks.c",
    "lib/http_digest.c",
    "lib/http_negotiate.c",
    "lib/http_ntlm.c",
    "lib/http_proxy.c",
    "lib/idn.c",
    "lib/if2ip.c",
    "lib/imap.c",
    "lib/inet_ntop.c",
    "lib/inet_pton.c",
    "lib/krb5.c",
    "lib/ldap.c",
    "lib/llist.c",
    "lib/macos.c",
    "lib/md4.c",
    "lib/md5.c",
    "lib/memdebug.c",
    "lib/mime.c",
    "lib/mprintf.c",
    "lib/mqtt.c",
    "lib/multi.c",
    "lib/netrc.c",
    "lib/nonblock.c",
    "lib/noproxy.c",
    "lib/openldap.c",
    "lib/parsedate.c",
    "lib/pingpong.c",
    "lib/pop3.c",
    "lib/progress.c",
    "lib/psl.c",
    "lib/rand.c",
    "lib/rename.c",
    "lib/request.c",
    "lib/rtsp.c",
    "lib/select.c",
    "lib/sendf.c",
    "lib/setopt.c",
    "lib/sha256.c",
    "lib/share.c",
    "lib/slist.c",
    "lib/smb.c",
    "lib/smtp.c",
    "lib/socketpair.c",
    "lib/socks.c",
    "lib/socks_gssapi.c",
    "lib/socks_sspi.c",
    "lib/speedcheck.c",
    "lib/splay.c",
    "lib/strcase.c",
    "lib/strdup.c",
    "lib/strerror.c",
    "lib/strparse.c",
    "lib/strtok.c",
    "lib/strtoofft.c",
    "lib/system_win32.c",
    "lib/telnet.c",
    "lib/tftp.c",
    "lib/timediff.c",
    "lib/timeval.c",
    "lib/transfer.c",
    "lib/url.c",
    "lib/urlapi.c",
    "lib/version.c",
    "lib/version_win32.c",
    "lib/warnless.c",
    "lib/ws.c"
}

-- Platform-specific source files
if is_plat("windows") then
    table.insert(LIB_CFILES, "lib/dllmain.c")
end

-- Combine all source files
local ALL_LIB_SOURCES = {}
for _, src in ipairs(LIB_VAUTH_CFILES) do
    table.insert(ALL_LIB_SOURCES, src)
end
for _, src in ipairs(LIB_VTLS_CFILES) do
    table.insert(ALL_LIB_SOURCES, src)
end
for _, src in ipairs(LIB_VQUIC_CFILES) do
    table.insert(ALL_LIB_SOURCES, src)
end
for _, src in ipairs(LIB_VSSH_CFILES) do
    table.insert(ALL_LIB_SOURCES, src)
end
for _, src in ipairs(LIB_CFILES) do
    table.insert(ALL_LIB_SOURCES, src)
end

-- SSL/TLS dependencies
if ssl_backend == "openssl" then
    add_requires("openssl")
elseif ssl_backend == "mbedtls" then
    add_requires("mbedtls")
end

-- Static library target
if get_config("enable_static") then
    target("libcurl_static")
        set_kind("static")
        add_files(table.unpack(ALL_LIB_SOURCES))
        
        -- Add BUILDING_LIBCURL for library compilation
        add_defines("BUILDING_LIBCURL")
        
        -- Platform-specific configurations
        if is_plat("windows") then
            set_basename("libcurl_a")
            if ssl_backend == "schannel" then
                add_defines("USE_SCHANNEL", "USE_WINDOWS_SSPI")
            end
        else
            set_basename("curl")
            if ssl_backend == "openssl" then
                add_packages("openssl")
                add_defines("USE_OPENSSL")
            elseif ssl_backend == "mbedtls" then
                add_packages("mbedtls") 
                add_defines("USE_MBEDTLS")
            end
        end
        
        -- Cross-compilation settings
        if is_plat("cross") then
            if is_arch("arm.*") then
                set_toolchains("cross", {cross = "arm-linux-gnueabihf-"})
            elseif is_arch("aarch64", "arm64") then
                set_toolchains("cross", {cross = "aarch64-linux-gnu-"})
            end
        end
        
        if is_plat("android") then
            if is_arch("armeabi-v7a") then
                set_toolchains("ndk", {arch = "armeabi-v7a"})
            elseif is_arch("arm64-v8a") then
                set_toolchains("ndk", {arch = "arm64-v8a"})
            end
        end
        
        add_headerfiles("include/curl/*.h", {prefixdir = "curl"})
    target_end()
end

-- Shared library target
if get_config("enable_shared") then
    target("libcurl_shared")
        set_kind("shared")
        add_files(table.unpack(ALL_LIB_SOURCES))
        
        -- Add BUILDING_LIBCURL for library compilation
        add_defines("BUILDING_LIBCURL")
        
        -- Platform-specific configurations
        if is_plat("windows") then
            set_basename("libcurl")
            add_files("lib/libcurl.rc")
            if ssl_backend == "schannel" then
                add_defines("USE_SCHANNEL", "USE_WINDOWS_SSPI")
            end
        else
            set_basename("curl")
            if ssl_backend == "openssl" then
                add_packages("openssl")
                add_defines("USE_OPENSSL")
            elseif ssl_backend == "mbedtls" then
                add_packages("mbedtls")
                add_defines("USE_MBEDTLS")
            end
        end
        
        -- Cross-compilation settings
        if is_plat("cross") then
            if is_arch("arm.*") then
                set_toolchains("cross", {cross = "arm-linux-gnueabihf-"})
            elseif is_arch("aarch64", "arm64") then
                set_toolchains("cross", {cross = "aarch64-linux-gnu-"})
            end
        end
        
        if is_plat("android") then
            if is_arch("armeabi-v7a") then
                set_toolchains("ndk", {arch = "armeabi-v7a"})
            elseif is_arch("arm64-v8a") then
                set_toolchains("ndk", {arch = "arm64-v8a"})
            end
        end
        
        add_headerfiles("include/curl/*.h", {prefixdir = "curl"})
    target_end()
end

-- curl executable target
if get_config("enable_curl_exe") then
    target("curl")
        set_kind("binary")
        add_files("src/*.c")
        
        -- Add include directories for tool compilation
        add_includedirs("lib", "include")
        
        -- Add necessary defines for tool compilation
        -- Note: Only define BUILDING_CURL, not BUILDING_LIBCURL
        -- This allows tool code to use curlx_dynbuf instead of dynbuf
        add_defines("BUILDING_CURL")
        add_defines("HAVE_CONFIG_H")
        
        -- Link against the appropriate libcurl
        if get_config("enable_shared") then
            add_deps("libcurl_shared")
        elseif get_config("enable_static") then
            add_deps("libcurl_static")
        end
        
        -- Cross-compilation settings
        if is_plat("cross") then
            if is_arch("arm.*") then
                set_toolchains("cross", {cross = "arm-linux-gnueabihf-"})
            elseif is_arch("aarch64", "arm64") then
                set_toolchains("cross", {cross = "aarch64-linux-gnu-"})
            end
        end
        
        if is_plat("android") then
            if is_arch("armeabi-v7a") then
                set_toolchains("ndk", {arch = "armeabi-v7a"})
            elseif is_arch("arm64-v8a") then
                set_toolchains("ndk", {arch = "arm64-v8a"})
            end
        end
    target_end()
end

-- Usage examples in comments:
--[[

# Build for Windows with MSVC (x64)
xmake f -p windows -a x64 --ssl_backend=schannel
xmake

# Build for Linux x64
xmake f -p linux -a x86_64 --ssl_backend=openssl
xmake

# Cross-compile for ARM Linux
xmake f -p cross -a arm --sdk=/path/to/arm-toolchain --ssl_backend=openssl
xmake

# Cross-compile for ARM64 Linux
xmake f -p cross -a arm64 --sdk=/path/to/arm64-toolchain --ssl_backend=openssl
xmake

# Build for Android ARM32
xmake f -p android -a armeabi-v7a --ndk=/path/to/android-ndk
xmake

# Build for Android ARM64
xmake f -p android -a arm64-v8a --ndk=/path/to/android-ndk
xmake

# Configure build options
xmake f --enable_static=true --enable_shared=false --enable_curl_exe=true
xmake

--]]
