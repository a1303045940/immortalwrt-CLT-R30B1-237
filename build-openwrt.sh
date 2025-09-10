# ======================================================
# 函数列表 - 所有需要导出的函数
# ======================================================
ALL_FUNCTIONS=(log_info log_error log_warn log_success log_separator log_highlight log_debug init_env prepare_source load_custom_feeds update_install_feeds load_custom_config download_packages compile_firmware)
# ======================================================
# 日志函数 - 添加颜色支持
# ======================================================
# 参数1: 颜色代码(r:红色, g:绿色, y:黄色, b:蓝色, z:紫色, l:青色)
# 参数2: 日志内容
function echo_color() {
case "$1" in
    r) local Color="\033[0;31m";; # 红色
    g) local Color="\033[0;32m";; # 绿色
    y) local Color="\033[0;33m";; # 黄色
    b) local Color="\033[0;34m";; # 蓝色
    z) local Color="\033[0;35m";; # 紫色
    l) local Color="\033[0;36m";; # 青色
    *) local Color="\033[0;0m";;  # 默认色
esac
if [ "$NO_COLOR" != "true" ]; then
    echo -e "${Color}${2}\033[0m"
else
    echo -e "${2}"
fi
}

# 信息日志函数
# 参数1: 日志内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_info() {
local show_time=${2:-1}
if [ "$show_time" -eq 1 ]; then
    echo_color "l" "[$(date +'%m-%d %H:%M:%S')] $1"
else
    echo_color "l" "$1"
fi
}

# 错误日志函数
# 参数1: 错误内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
# 返回值: 1 (表示错误)
function log_error() {
local show_time=${2:-1}
if [ "$show_time" -eq 1 ]; then
    echo_color "r" "[$(date +'%m-%d %H:%M:%S')] ❌ $1" >&2
else
    echo_color "r" "❌ $1" >&2
fi
return 1
}

# 警告日志函数
# 参数1: 警告内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_warn() {
local show_time=${2:-1}
if [ "$show_time" -eq 1 ]; then
    echo_color "y" "[$(date +'%m-%d %H:%M:%S')] ⚠️ $1"
else
    echo_color "y" "⚠️ $1"
fi
}

# 成功提示函数
# 参数1: 成功内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_success() {
local show_time=${2:-1}
if [ "$show_time" -eq 1 ]; then
    echo_color "g" "[$(date +'%m-%d %H:%M:%S')] ✅ $1"
else
    echo_color "g" "✅ $1"
fi
}

# 分隔线输出函数
# 参数1: 标题内容(可选)
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_separator() {
local title="$1"
local show_time=${2:-1}
if [ -n "$title" ]; then
    if [ "$show_time" -eq 1 ]; then
        echo_color "b" "\n===== $title $(date +'%m-%d %H:%M:%S') ====="
    else
        echo_color "b" "\n========== $title =========="
    fi
else
    echo_color "b" "\n======================================="
fi
}

# 调试信息输出函数(默认不显示，通过DEBUG环境变量控制)
# 参数1: 调试内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_debug() {
if [ "$DEBUG" = "true" ]; then
    local show_time=${2:-1}
    if [ "$show_time" -eq 1 ]; then
        echo_color "z" "[DEBUG $(date +'%m-%d %H:%M:%S')] $1"
    else
        echo_color "z" "[DEBUG] $1"
    fi
fi
}

# 突出提示日志函数
# 参数1: 提示内容
# 参数2: 可选，时间显示控制(0=不显示时间, 1=显示时间，默认1)
function log_highlight() {
local show_time=${2:-1}
if [ "$show_time" -eq 1 ]; then
    echo_color "z" "[$(date +'%m-%d %H:%M:%S')] $1"
else
    echo_color "z" "$1"
fi
}

# ======================================================
# 初始化环境函数（仅主机编译使用）
# 功能: 安装编译依赖、设置时区、创建工作目录
# ======================================================
init_env() {
log_info "开始初始化编译环境..."
# 更新系统并安装依赖
sudo -E apt-get -qq update
# sudo -E apt-get -qq install \
#     ack antlr3 aria2 asciidoc autoconf automake autopoint binutils bison \
#     build-essential bzip2 ccache cmake cpio curl device-tree-compiler \
#     fastjar flex gawk gettext gcc-multilib g++-multilib git gperf haveged \
#     help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev \
#     libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev \
#     libncursesw5-dev libreadline-dev libssl-dev libtool lrzsz mkisofs msmtp \
#     nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 \
#     python3-pyelftools python3-setuptools libpython3-dev qemu-utils rsync \
#     scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip \
#     vim wget xmlto xxd zlib1g-dev
sudo -E apt-get -qq install -y --no-install-recommends \
        build-essential gcc-multilib g++-multilib binutils \
        autoconf automake autopoint bison flex gettext gawk \
        libc6-dev-i386 libelf-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev \
        libncurses5-dev libncursesw5-dev libreadline-dev libssl-dev zlib1g-dev zstd \
        git wget ca-certificates ccache cmake curl device-tree-compiler pkgconf \
        rsync unzip file \
        python2.7 python3 python3-distutils python3-pyelftools
# 清理系统
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
# 设置时区
sudo timedatectl set-timezone "$TZ"
# 设置工作目录权限
sudo mkdir -p "$WORK_DIR"
sudo chown -R $USER:$GROUPS "$WORK_DIR"
log_success "编译环境初始化完成！"
log_info "当前目录：$PWD"
log_info "项目目录：$WORK_DIR"
log_info "源码目录：$SOURCE_DIR"
}

# ======================================================
# 克隆源码函数
# 功能: 从远程仓库克隆源码并验证完整性
# ======================================================
# 参数: 最小源码大小(MB，可选)
prepare_source() {
local min_src_size_mb=${1:-150}

log_info "开始准备源码..."
sudo mkdir -p "$SOURCE_DIR"
# 获取远程源码哈希
log_info "获取远程源码哈希：$REPO_URL ($REPO_BRANCH)"
REMOTE_COMMIT=$(git ls-remote $REPO_URL $REPO_BRANCH | awk '{print $1}')
if [ -z "$REMOTE_COMMIT" ]; then
    log_error "无法获取远程仓库哈希值"
    return 1
fi

# 克隆源码，带重试机制
rm -rf "$SOURCE_DIR"
for i in {1..3};
do
    git clone --depth 1 --single-branch -b $REPO_BRANCH $REPO_URL "$SOURCE_DIR" && break
    log_error "克隆失败，重试第$i次..." && sleep 5
done

# 检查克隆是否成功
if [ ! -d "$SOURCE_DIR/.git" ]; then
    log_error "源码克隆失败，未找到.git目录"
    return 1
fi

# 校验源码完整性
log_info "校验源码完整性..."
log_info "远程Commit: $REMOTE_COMMIT"
LOCAL_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
log_info "本地Commit: $LOCAL_COMMIT"

if [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
    log_error "源码哈希不一致 (本地: $LOCAL_COMMIT, 远程: $REMOTE_COMMIT)"
    return 1
fi

# 校验源码体积
SRC_SIZE_MB=$(du -sm "$SOURCE_DIR" | awk '{print $1}')
log_info "源码体积: $SRC_SIZE_MB MB"
if [ $SRC_SIZE_MB -lt $min_src_size_mb ]; then
    log_error "源码体积过小 ($SRC_SIZE_MB MB < $min_src_size_mb MB)，可能不完整"
    return 1
fi

log_success "源码准备完成: $(du -sh "$SOURCE_DIR" | cut -f1)"
}

# ======================================================
# 加载自定义feeds
# 功能: 替换feeds配置文件并执行diy-part1.sh脚本
# ======================================================
load_custom_feeds() {
log_info "开始加载自定义feeds..."
# 检查并替换feeds配置文件
if [ -e "$WORK_DIR/feeds.conf.default" ]; then
    cp -f "$WORK_DIR/feeds.conf.default" "$SOURCE_DIR/feeds.conf.default" && \
        log_success "已替换feeds配置文件"
    if [ $? -ne 0 ]; then
        log_error "复制feeds配置文件失败！"
        return 1
    fi
fi
# 执行diy-part1.sh并进行错误处理
if [ -f "$WORK_DIR/$DIY_P1_SH" ]; then
    chmod +x "$WORK_DIR/$DIY_P1_SH" && log_info "执行diy-part1.sh..."
    WORKDIR=$(pwd)
    cd "$SOURCE_DIR"
    "$WORKDIR/$DIY_P1_SH"
    if [ $? -ne 0 ]; then
        log_error "diy-part1.sh执行失败！"
        return 1
    fi
else
    log_error "diy-part1.sh脚本不存在"
    return 1
fi
log_success "加载自定义feeds完成！"
}

# ======================================================
# 更新并安装feeds
# 功能: 更新OpenWrt源码的feeds并安装所有包
# ======================================================
update_install_feeds() {
log_info "开始更新并安装feeds..."

# 更新feeds，带重试机制
cd "$SOURCE_DIR"
for i in {1..3}; do 
    ./scripts/feeds update -a && break || (log_error "更新feeds失败，重试第$i次" && sleep 10 && if [ $i -eq 3 ]; then log_error "更新$i次feeds仍然失败，退出编译" && exit 1; fi)
done
# 安装feeds
./scripts/feeds install -a -j$(nproc)

log_success "feeds安装完成！"
}

# ======================================================
# 加载自定义配置
# 功能: 加载自定义配置文件并执行diy-part2.sh脚本
# ======================================================
load_custom_config() {
log_info "开始加载自定义配置..."
if [ -d "$WORK_DIR/files" ]; then
    cp -r "$WORK_DIR/files" "$SOURCE_DIR/files" && log_success "已复制自定义files目录"
fi
WORKDIR=$(pwd)
cd "$SOURCE_DIR"
if [ -f "$WORKDIR/$DIY_P2_SH" ]; then
    log_info "执行diy-part2.sh..."
    chmod +x "$WORKDIR/$DIY_P2_SH"
    "$WORKDIR/$DIY_P2_SH"
    if [ $? -ne 0 ]; then
        log_error "diy-part2.sh执行失败！"
        return 1
    fi
else
    log_error "diy-part2.sh脚本不存在"
    return 1
fi
# 检查配置文件是否存在
if [ ! -f ".config" ]; then
    log_error "未找到配置文件 .config，终止编译！"
    return 1
fi
log_info ".config配置行数: $(wc -l ".config" | awk '{print $1}')"
if grep -q '^CONFIG_PACKAGE_luci-app-adguardhome=y' .config; then
    download_adguardhome
fi
if grep -q '^CONFIG_PACKAGE_luci-app-v2raya=y' .config; then
    log_info "下载v2raya的geoip.dat和geosite.dat文件"
    mkdir -p ./files/usr/share/xray
    curl -L -k --retry 2 --connect-timeout 20 -o "./files/usr/share/xray/geoip.dat" "https://github.com/v2fly/geoip/releases/latest/download/geoip.dat" 2>/dev/null
    if [ -f "./files/usr/share/xray/geoip.dat" ]; then
        log_success "v2raya的geoip.dat文件下载完成"
        chmod 755 "./files/usr/share/xray/geoip.dat"
    else
        log_error "v2raya的geoip.dat文件下载失败"
    fi
    curl -L -k --retry 2 --connect-timeout 20 -o "./files/usr/share/xray/geosite.dat" "https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat" 2>/dev/null
    if [ -f "./files/usr/share/xray/geosite.dat" ]; then
        log_success "v2raya的geosite.dat文件下载完成"
        chmod 755 "./files/usr/share/xray/geosite.dat"
    else
        log_error "v2raya的geosite.dat文件下载失败"
    fi
fi
# 设置用户输入的参数
if [ -n "$LAN_IP" ]; then
    log_info "设置LAN IP地址为: $LAN_IP"
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/${LAN_IP}/g" $(find "./feeds/luci/modules/luci-mod-system" -type f -name 'flash.js')
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/${LAN_IP}/g" "./package/base-files/files/bin/config_generate"
fi
if [ -n "$DEFAULT_THEME" ]; then
    log_info "设置默认主题为: $DEFAULT_THEME"
    sed -i "s/luci-theme-bootstrap/luci-theme-${DEFAULT_THEME}/g" "./feeds/luci/collections/luci/Makefile"
fi
if [ -n "$HOSTNAME" ]; then
    log_info "设置默认主机名为: $HOSTNAME"
    # 使用更安全的sed命令格式，避免特殊字符问题
    sed -i "s|set system.@system\[-1\].hostname='ImmortalWrt'|set system.@system[-1].hostname='${HOSTNAME}'|g" "./package/base-files/files/bin/config_generate"
    if [ $? -ne 0 ]; then
        log_warn "修改config_generate文件中的主机名失败，尝试备选方法..."
        # 备选方法：直接添加主机名设置
        echo "set system.@system[-1].hostname='${HOSTNAME}'" >> "./package/base-files/files/bin/config_generate"
    fi
    sed -i "s|'hostname:string:OpenWrt'|'hostname:string:${HOSTNAME}'|g" "./package/base-files/files/etc/init.d/system"
    if [ $? -ne 0 ]; then
        log_warn "修改init.d/system文件中的主机名失败，尝试备选方法..."
        # 备选方法：直接添加主机名设置
        echo "hostname:string:${HOSTNAME}" >> "./package/base-files/files/etc/init.d/system"
    fi
    sed -i "s|echo OpenWrt-failsafe|echo ${HOSTNAME}-failsafe|g" "./package/base-files/files/lib/preinit/10_indicate_failsafe"
    if [ $? -ne 0 ]; then
        log_warn "修改10_indicate_failsafe文件中的主机名失败，尝试备选方法..."
        # 备选方法：直接添加failsafe主机名设置
        echo "echo ${HOSTNAME}-failsafe" >> "./package/base-files/files/lib/preinit/10_indicate_failsafe"
    fi
fi
# 设置WIFI名称
log_info "设置2.4G和5G WiFi名称为: $WIFINAME_2G, $WIFINAME_5G"
MTWIFI_SH="./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh"
if [ -f "$MTWIFI_SH" ]; then
    OLD_COUNT_2G=$(grep -c "ssid=\"ImmortalWrt-2.4G\"" "$MTWIFI_SH")
    sed -i "s/ssid=\"ImmortalWrt-2.4G\"/ssid=\"$WIFINAME_2G\"/g" "$MTWIFI_SH"
    NEW_COUNT_2G=$(grep -c "ssid=\"$WIFINAME_2G\"" "$MTWIFI_SH")
    REMAIN_OLD_2G=$(grep -c "ssid=\"ImmortalWrt-2.4G\"" "$MTWIFI_SH")
    if [ "$REMAIN_OLD_2G" -eq 0 ] && [ "$NEW_COUNT_2G" -ge "$OLD_COUNT_2G" ]; then
        log_success "2.4G WiFi名称设置成功，当前为：$WIFINAME_2G"
    else
        log_error "2.4G WiFi名称设置失败（未找到原始配置或替换异常）"
    fi
    OLD_COUNT_5G=$(grep -c "ssid=\"ImmortalWrt-5G\"" "$MTWIFI_SH")
    sed -i "s/ssid=\"ImmortalWrt-5G\"/ssid=\"$WIFINAME_5G\"/g" "$MTWIFI_SH"
    NEW_COUNT_5G=$(grep -c "ssid=\"$WIFINAME_5G\"" "$MTWIFI_SH")
    REMAIN_OLD_5G=$(grep -c "ssid=\"ImmortalWrt-5G\"" "$MTWIFI_SH")
    EXPECT_NEW_5G=$OLD_COUNT_5G
    if [ "$WIFINAME_2G" == "$WIFINAME_5G" ]; then
        EXPECT_NEW_5G=$((OLD_COUNT_5G + (NEW_COUNT_2G - OLD_COUNT_2G)))
    fi
    if [ "$REMAIN_OLD_5G" -eq 0 ] && [ "$NEW_COUNT_5G" -ge "$EXPECT_NEW_5G" ]; then
        log_success "5G WiFi名称设置成功，当前为：$WIFINAME_5G"
    else
        log_error "5G WiFi名称设置失败（未找到原始配置或替换异常）"
    fi
else
    log_warn "未找到 $MTWIFI_SH 文件，WIFI名称设置跳过修改（可能设备不适用）"
fi
if [ "$HIGH_POWER_5G" = "true" ] || [ "$HIGH_POWER_5G" = true ] || [ "$HIGH_POWER_5G" = "1" ]; then
# 2025-9-6经过分析，package/mtk/drivers/mt_wifi/files/目录下的2个二进制文件e2p和MT7981_iPAiLNA_EEPROM.bin的数据其实是完全一致
log_info "5G高功率25db设置中..."
CORE_EEPROM_BIN="package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/MT7981_iPAiLNA_EEPROM.bin"
CORE_EEPROM_E2P="package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p"
FIRMWARE_LINK_DIR="files/lib/firmware"
FIRMWARE_EEPROM_E2P="$FIRMWARE_LINK_DIR/e2p"
FIRMWARE_EEPROM_BIN="MT7981_iPAiLNA_EEPROM.bin"

if [ ! -f "$CORE_EEPROM_BIN" ]; then
    log_error "错误：核心EEPROM文件不存在 → $CORE_EEPROM_BIN"
    exit 1
fi
if ! file "$CORE_EEPROM_BIN" | grep -q "data"; then
    log_error "错误：核心EEPROM文件非二进制格式 → $CORE_EEPROM_BIN（当前类型：$(file -b "$CORE_EEPROM_BIN")）"
    exit 1
fi
log_success "核心EEPROM文件校验通过（存在且为二进制）"
rm -f "$CORE_EEPROM_E2P"
if [ $? -eq 0 ]; then
    log_success "已删除e2p文件 → $CORE_EEPROM_E2P"
else
    log_error "错误：删除e2p文件失败 → $CORE_EEPROM_E2P"
    exit 1
fi

EXPECTED_CONTENT=$(printf '\x2B%.0s' {1..20})
CURRENT_CONTENT_RAW=$(dd if="$CORE_EEPROM_BIN" bs=1 skip=$((0x445)) count=20 2>&1)
READ_EXIT_CODE=$?
printf '%s' "$CURRENT_CONTENT_RAW" | grep -E 'records (in|out)|bytes copied' | while IFS= read -r line; do
    [ -n "$line" ] && log_info "$line"
done
if [ $READ_EXIT_CODE -ne 0 ]; then
    log_error "错误：读取核心EEPROM文件失败 → $CORE_EEPROM_BIN"
    exit 1
fi
ACTUAL_EEPROM_DATA=$(printf '%s' "$CURRENT_CONTENT_RAW" | tail -c 20)
if [ "$ACTUAL_EEPROM_DATA" != "$EXPECTED_CONTENT" ]; then
    DD_WRITE_OUTPUT=$(echo -n "$EXPECTED_CONTENT" | dd of="$CORE_EEPROM_BIN" bs=1 seek=$((0x445)) count=20 conv=notrunc 2>&1)
    WRITE_EXIT_CODE=$?
    printf '%s' "$DD_WRITE_OUTPUT" | while IFS= read -r line; do
        [ -n "$line" ] && log_info "$line"
    done

    if [ $WRITE_EXIT_CODE -eq 0 ]; then
        CURRENT_CONTENT_RAW=$(dd if="$CORE_EEPROM_BIN" bs=1 skip=$((0x445)) count=20 2>&1)
        READ_EXIT_CODE=$?
        printf '%s' "$CURRENT_CONTENT_RAW" | grep -E 'records (in|out)|bytes copied' | while IFS= read -r line; do
            [ -n "$line" ] && log_info "$line"
        done
        log_success "成功：核心EEPROM文件已写入5G高功率25db配置 → $CORE_EEPROM_BIN"
    else
        log_error "错误：核心EEPROM文件写入失败 → $CORE_EEPROM_BIN"
        exit 1
    fi
else
    log_success "无需修改：核心EEPROM文件已包含5G高功率25db配置 → $CORE_EEPROM_BIN"
fi
mkdir -p "$FIRMWARE_LINK_DIR"
if [ $? -ne 0 ]; then
    log_error "错误：创建固件链接目录失败 → $FIRMWARE_LINK_DIR"
    exit 1
fi
rm -f "$FIRMWARE_EEPROM_E2P"
ln -sf "$FIRMWARE_EEPROM_BIN" "$FIRMWARE_EEPROM_E2P"
LINK_EXIT_CODE=$?
# 4. 优化校验逻辑：只判断“链接文件是否存在且是符号链接”，不校验目标文件
if [ $LINK_EXIT_CODE -eq 0 ] && [ -L "$FIRMWARE_EEPROM_E2P" ]; then
    # 仅验证链接的“指向字符串”是否正确（不关心目标文件是否存在）
    LINK_TARGET=$(readlink "$FIRMWARE_EEPROM_E2P")
    if [ "$LINK_TARGET" = "$FIRMWARE_EEPROM_BIN" ]; then
        log_success "固件目录e2p链接创建成功（编译后生效）"
        log_info "提示：目标文件会在编译时自动同步到该目录"
        log_info "$(ls -l "$FIRMWARE_EEPROM_E2P" | awk '{print "链接属性：" $0}')"
    else
        log_error "错误：链接指向错误 → 实际指向 '$LINK_TARGET'，预期 '$FIRMWARE_EEPROM_BIN'"
        exit 1
    fi
else
    log_error "错误：符号链接创建失败"
    log_info "ℹ️  调试信息："
    echo "   链接命令：ln -sf '$FIRMWARE_EEPROM_BIN' '$FIRMWARE_EEPROM_E2P'"
    echo "   固件目录内容：$(ls -la "$FIRMWARE_LINK_DIR" 2>/dev/null || echo '空目录')"
    exit 1
fi
log_success "5G高功率25db设置全部完成！"
fi
#添加编译日期
COMPILE_DATE=$(date +"%Y.%m.%d")
log_success "添加编译日期:${COMPILE_DATE}"
sed -i "s/%C/\/ Complied on ${COMPILE_DATE}/g" package/base-files/files/usr/lib/os-release
sed -i "s/%C/\/ Complied on ${COMPILE_DATE}/g" package/base-files/files/etc/openwrt_release
log_success "自定义配置加载完成！"
}

# ======================================================
# 下载软件包
# 功能: 下载编译所需的软件包
# ======================================================
download_packages() {
cd "$SOURCE_DIR"
log_info "执行make defconfig进行配置的验证与补全，会改变.config配置文件，如果编译比原.config配置文件少东西可以尝试删掉这个命令"
make defconfig
log_success "make defconfig执行完成"
# 下载软件包，带重试机制
log_info "开始下载软件包..."
for i in {1..3}; do 
    make download -j$(nproc) && break || (log_info "下载失败，重试第$i次" && sleep 10)
done

log_info "清理不完整的下载文件..."
small_files_count=$(find dl -size -1024c | wc -l)
if [ $small_files_count -gt 0 ]; then
    log_info "找到 $small_files_count 个小于1KB的文件，开始清理..."
    find dl -size -1024c -exec rm -f {} \;
    log_success "清理完成"
else
    log_success "没有发现不完整的下载文件"
fi

log_info "已下载软件包大小: $(du -sh dl | cut -f1)"
log_success "软件包下载完成！"
}

# ======================================================
# 编译固件
# 功能: 使用多线程编译OpenWrt固件，仅返回编译结果状态码
# 返回值: 0表示成功
# ======================================================
compile_firmware() {
    cd "$SOURCE_DIR"
    log_info "开始编译固件（使用$(nproc)线程）..."
    (make -j$(nproc))
    local make_exit_code=$?
    if [ $make_exit_code -eq 0 ]; then
        log_success "固件编译完成！"
        return 0
    else
        log_error "多线程编译失败，尝试单线程编译..."
        (make -j1 V=s)
        local make_single_exit_code=$?
        if [ $make_single_exit_code -eq 0 ]; then
            log_success "单线程编译完成！"
            return 0
        else
            log_error "固件编译失败，编译退出码：$make_single_exit_code"
            exit 1
        fi
    fi
}

update_config_option() {
    local option_name=$1
    local desired_value=$2
    local config_file=$3
    if [ ! -f "$config_file" ]; then
        log_error "错误：配置文件不存在 → $config_file"
        return 1
    fi
    # 根据OpenWrt配置文件规则处理引号
    # 检查值是否是纯数字、y、n或m，这些情况不需要引号
    if [[ "$desired_value" =~ ^[0-9]+$ ]] || [[ "$desired_value" == "y" ]] || [[ "$desired_value" == "n" ]] || [[ "$desired_value" == "m" ]]; then
        local formatted_value="$desired_value"
    else
        # 如果值已经包含引号，则不再添加
        if [[ "$desired_value" == \"* ]]; then
            local formatted_value="$desired_value"
        else
            local formatted_value="\"$desired_value\""
        fi
    fi
    
    if grep -q "^$option_name=" "$config_file"; then
        current_value=$(grep "^$option_name=" "$config_file" | cut -d'=' -f2)
        if [ "$current_value" != "$formatted_value" ]; then
            log_info "更新 $option_name 从 '$current_value' 到 '$formatted_value'"
            sed -i "s|^$option_name=.*|$option_name=$formatted_value|" "$config_file"
        else
            log_info "$option_name 已经设置为 '$formatted_value'"
        fi
    elif grep -q "^# $option_name is not set" "$config_file"; then
        log_info "启用 $option_name 设置为 '$formatted_value'"
        sed -i "s|^# $option_name is not set|$option_name=$formatted_value|" "$config_file"
    else
        log_info "添加 $option_name 设置为 '$formatted_value'"
        echo "$option_name=$formatted_value" >> "$config_file"
    fi
}

get_latest_version() {
    local ver=$(curl -L -k --retry 2 --connect-timeout 20 -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>/dev/null | grep -E 'tag_name' | grep -E 'v[0-9.]+' -o)
    if [ -z "$ver" ]; then
        log_error "警告：获取最新版本号失败，跳过核心下载" >&2
        return 1
    fi
    echo "$ver"
}

get_architecture() {
    local arch_pkg=$(grep '^CONFIG_TARGET_ARCH_PACKAGES=' .config 2>/dev/null | cut -d'"' -f2)
    if [ -z "$arch_pkg" ]; then
        log_error "警告：在.config中未找到CONFIG_TARGET_ARCH_PACKAGES配置，跳过核心下载" >&2
        return 1
    fi
    case "$arch_pkg" in
        i386*|i686*) echo "386" ;;
        x86_64*|amd64*) echo "amd64" ;;
        mipsel*) echo "mipsle" ;;
        mips64el*) echo "mipsle" ;;
        mips*|mips64*) echo "mips" ;;
        arm*) echo "arm" ;;
        aarch64*) echo "arm64" ;;
        *) log_error "警告：不支持的架构包 $arch_pkg，跳过核心下载" >&2; return 1 ;;
    esac
}

download_adguardhome() {
    local latest_ver=$(get_latest_version) || return
    local Arch=$(get_architecture) || return
    log_info "开始下载AdGuard Home核心，最新版本：$latest_ver，架构：$Arch"
    mkdir -p /tmp/AdGuardHomeupdate
    links=(
        "https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_ver}/AdGuardHome_linux_${Arch}.tar.gz"
        "https://static.adguard.com/adguardhome/release/AdGuardHome_linux_${Arch}.tar.gz"
    )
    success=0
    filename=""
    link=""
    for link in "${links[@]}"; do
        filename="${link##*/}"
        curl -L -k --retry 2 --connect-timeout 20 -o "/tmp/AdGuardHomeupdate/$filename" "$link" 2>/dev/null
        if [ $? -eq 0 ]; then
            success=1
            break
        else
            rm -f "/tmp/AdGuardHomeupdate/$filename"
        fi
    done
    if [ $success -eq 0 ]; then
        log_error "警告：所有下载链接均失败，跳过核心下载"
        rm -rf /tmp/AdGuardHomeupdate
        return
    fi
    local downloadbin
    if [ "${filename##*.}" = "gz" ]; then
        if ! tar -zxf "/tmp/AdGuardHomeupdate/$filename" -C "/tmp/AdGuardHomeupdate/" 2>/dev/null; then
            log_error "警告：解压gz文件失败，跳过核心下载"
            rm -rf /tmp/AdGuardHomeupdate
            return
        fi
        downloadbin="/tmp/AdGuardHomeupdate/AdGuardHome/AdGuardHome"
    else
        downloadbin="/tmp/AdGuardHomeupdate/$filename"
    fi
    if [ ! -f "$downloadbin" ]; then
        log_error "警告：下载后未找到核心文件，跳过核心下载"
        rm -rf /tmp/AdGuardHomeupdate
        return
    fi
    chmod 755 "$downloadbin"
    mkdir -p ./files/usr/bin/AdGuardHome/
    mv -f "$downloadbin" ./files/usr/bin/AdGuardHome/
    rm -rf /tmp/AdGuardHomeupdate
    log_success "AdGuard Home核心下载完成"
}

export -f "${ALL_FUNCTIONS[@]}"
# ======================================================
# 主函数（如果直接运行脚本时使用）
# ======================================================
main() {
echo "请通过GitHub Actions工作流运行此脚本"
exit 0
}

# 如果脚本被直接运行，则执行main函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
download_adguardhome
main
fi

