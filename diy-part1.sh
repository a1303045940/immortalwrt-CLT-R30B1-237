#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	# 处理克隆的仓库
		#find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;

		# 处理克隆的仓库
 	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
  	  # 修改后的 find 命令：覆盖深层目录（如 relevance/filebrowser）
  	  #find ./$REPO_NAME/ -maxdepth 10 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
	  find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
  	  rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
  	  # 原逻辑：直接重命名仓库目录（适用于插件与仓库同名的情况）
  	  mv -f $REPO_NAME $PKG_NAME
	fi
}
#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}


# 添加feed源函数
# 参数1: feed名称
# 参数2: feed URL
add_feed() {
    local name=$1
    local url=$2
    # 检查feeds.conf.default中是否已包含该源
    if ! grep -q "src-git $name $url" feeds.conf.default; then
        echo "添加feed源：$name，地址：$url"
        echo "src-git $name $url" >> feeds.conf.default
    else
        echo "ℹ️ feed源 $name 已存在，跳过添加"
    fi
}

# 添加istore和nas_luci源
add_feed "istore" "https://github.com/linkease/istore.git;main"
add_feed "nas_luci" "https://github.com/linkease/nas-packages-luci.git;main"
add_feed "nas_packages" "https://github.com/linkease/nas-packages.git;master"

# 克隆第三方包函数
# 参数1: 仓库URL
# 参数2: 目标目录
clone_package() {
    local repo=$1
    local dir=$2
    
    # 如果目录已存在，先删除（强制覆盖）
    if [ -d "$dir" ]; then
        echo "⚠️ 包 $dir 已存在，删除旧版本并重新克隆..."
        rm -rf "$dir" || {
            echo "❌ 删除旧版本 $dir 失败！"
            exit 1
        }
    fi
    
    # 执行克隆（无论之前是否存在目录）
GIT_CLONE_OUTPUT=$(git clone --depth 1 "$repo" "$dir" 2>&1)
CLONE_EXIT_CODE=$?
if [ $CLONE_EXIT_CODE -eq 0 ]; then
    echo -e "✅ 克隆包：$repo 到 $dir 成功！"
else
    echo -e "❌ 克隆包：$repo 到 $dir 失败！"
    echo -e "❌ 错误信息：$GIT_CLONE_OUTPUT"
    exit 1
fi
}

# 克隆所需第三方包
clone_package "https://github.com/gdy666/luci-app-lucky.git" "package/luci-app-lucky"
#clone_package "https://github.com/tty228/luci-app-wechatpush.git" "package/luci-app-wechatpush"
clone_package "https://github.com/rogueme/luci-app-adguardhome.git" "package/luci-app-adguardhome"
#clone_package "https://github.com/sirpdboy/luci-app-taskplan.git" "package/luci-app-taskplan"
# 克隆mentohust解决luci-app-airwhu缺失依赖的警告
#clone_package "https://github.com/KyleRicardo/MentoHUST-OpenWrt-ipk.git" "package/mentohust"
# istore商店
UPDATE_PACKAGE "luci-app-store" "shidahuilang/openwrt-package" "Immortalwrt" "pkg"
UPDATE_PACKAGE "lucky" "shidahuilang/openwrt-package" "Lede" "pkg"
UPDATE_PACKAGE "luci-app-lucky" "shidahuilang/openwrt-package" "Lede" "pkg"
# npc安装
UPDATE_PACKAGE "luci-app-npc" "kiddin9/kwrt-packages" "main" "pkg"
UPDATE_PACKAGE "luci-app-frpc" "kiddin9/kwrt-packages" "main" "pkg"
UPDATE_PACKAGE "luci-app-zerotier" "kiddin9/kwrt-packages" "main" "pkg"
#UPDATE_PACKAGE "luci-app-ssr-plus" "kiddin9/kwrt-packages" "main" "pkg"
UPDATE_PACKAGE "luci-theme-argon" "kiddin9/kwrt-packages" "main" "pkg"
#UPDATE_PACKAGE "luci-app-easymesh" "kiddin9/kwrt-packages" "main" "pkg"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "xiaorouji/openwrt-passwall2" "main" "pkg"

#UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

#UPDATE_PACKAGE "istore" "linkease/istore" "main" "pgk"
UPDATE_PACKAGE "quickstart" "kenzok8/small-package" "main" "pkg"
#UPDATE_PACKAGE "istorex" "kenzok8/small-package" "main" "pkg"
UPDATE_PACKAGE "ssr-plus" "fw876/helloworld" "master"


#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
#UPDATE_VERSION "sing-box"
UPDATE_VERSION "openclash"

#预置OpenClash内核和数据
if [ -d *"openclash"* ]; then
        echo "预置OpenClash内核和数据!"
	CORE_VER="https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/core_version"
	CORE_TYPE=$(echo $WRT_TARGET | grep -Eiq "64|86" && echo "amd64" || echo "arm64")
	CORE_TUN_VER=$(curl -sL $CORE_VER | sed -n "2{s/\r$//;p;q}")

	CORE_DEV="https://github.com/vernesong/OpenClash/raw/core/dev/dev/clash-linux-$CORE_TYPE.tar.gz"
	CORE_MATE="https://github.com/vernesong/OpenClash/raw/core/dev/meta/clash-linux-$CORE_TYPE.tar.gz"
	CORE_TUN="https://github.com/vernesong/OpenClash/raw/core/dev/premium/clash-linux-$CORE_TYPE-$CORE_TUN_VER.gz"

	GEO_MMDB="https://github.com/alecthw/mmdb_china_ip_list/raw/release/lite/Country.mmdb"
	GEO_SITE="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geosite.dat"
	GEO_IP="https://github.com/Loyalsoldier/v2ray-rules-dat/raw/release/geoip.dat"

	cd ./luci-app-openclash/root/etc/openclash/

	curl -sL -o Country.mmdb $GEO_MMDB && echo "Country.mmdb done!"
	curl -sL -o GeoSite.dat $GEO_SITE && echo "GeoSite.dat done!"
	#curl -sL -o GeoIP.dat $GEO_IP && echo "GeoIP.dat done!"

	mkdir ./core/ && cd ./core/

	curl -sL -o meta.tar.gz $CORE_MATE && tar -zxf meta.tar.gz && mv -f clash clash_meta && echo "meta done!"
	#curl -sL -o tun.gz $CORE_TUN && gzip -d tun.gz && mv -f tun clash_tun && echo "tun done!"
	#curl -sL -o dev.tar.gz $CORE_DEV && tar -zxf dev.tar.gz && echo "dev done!"

	chmod +x ./* && rm -rf ./*.gz

	cd $PKG_PATCH && echo "openclash date has been updated!"
fi
echo "✅ diy-part1.sh 执行完成"
