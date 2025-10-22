#!/bin/bash

# 确保编译目录为/mnt/openwrt，设置权限
OPENWRT_DIR="/mnt/openwrt"
PACKAGE_DIR="${OPENWRT_DIR}/package"
mkdir -p ${PACKAGE_DIR}
sudo chmod -R 777 ${OPENWRT_DIR}  # 解决权限问题
cd ${OPENWRT_DIR} || exit  # 切换到OpenWrt源码根目录

# 修改默认IP（按需启用）
# sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh（按需启用）
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录（按需启用）
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 移除要替换的包
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan

# Git稀疏克隆函数（优化路径处理）
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  repo_name=$(echo "$repourl" | awk -F '/' '{print $(NF)}' | sed 's/\.git$//')  # 提取仓库名
  git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl" "${PACKAGE_DIR}/${repo_name}"
  cd "${PACKAGE_DIR}/${repo_name}" && git sparse-checkout set "$@"
  # 将指定目录移动到package根目录，删除临时仓库
  for dir in "$@"; do
    mv -f "$dir" "${PACKAGE_DIR}/"
  done
  cd ${OPENWRT_DIR} && rm -rf "${PACKAGE_DIR}/${repo_name}"
}

# 添加额外插件（保留核心，注释部分插件减少空间占用）
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome ${PACKAGE_DIR}/luci-app-adguardhome
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush ${PACKAGE_DIR}/luci-app-serverchan
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff ${PACKAGE_DIR}/luci-app-poweroff
# git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy ${PACKAGE_DIR}/luci-app-ikoolproxy  # 可选
# git clone --depth=1 https://github.com/destan19/OpenAppFilter ${PACKAGE_DIR}/OpenAppFilter  # 可选
# git clone --depth=1 https://github.com/Jason6111/luci-app-netdata ${PACKAGE_DIR}/luci-app-netdata  # 可选
git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server
git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos

# 科学上网插件（按需保留，避免全部启用占用空间）
git clone --depth=1 -b main https://github.com/fw876/helloworld ${PACKAGE_DIR}/luci-app-ssr-plus
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages ${PACKAGE_DIR}/openwrt-passwall  # 可选
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall ${PACKAGE_DIR}/luci-app-passwall  # 可选
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 ${PACKAGE_DIR}/luci-app-passwall2  # 可选
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
git clone --depth=1 -b main https://github.com/nikkinikki-org/OpenWrt-nikki.git ${PACKAGE_DIR}/OpenWrt-nikki
git clone --depth=1 -b main https://github.com/nikkinikki-org/OpenWrt-momo.git ${PACKAGE_DIR}/OpenWrt-momo

# 主题（保留1-2个核心主题，减少空间）
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon ${PACKAGE_DIR}/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config ${PACKAGE_DIR}/luci-app-argon-config
# git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge ${PACKAGE_DIR}/luci-theme-edge  # 可选
# git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom ${PACKAGE_DIR}/luci-theme-infinityfreedom  # 可选
# git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear  # 可选

# 更改 Argon 主题背景（确保图片存在）
if [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ]; then
  mkdir -p ${PACKAGE_DIR}/luci-theme-argon/htdocs/luci-static/argon/img/
  cp -f "$GITHUB_WORKSPACE/images/bg1.jpg" ${PACKAGE_DIR}/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# 晶晨宝盒（核心功能保留）
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/haiibo/OpenWrt'|g" ${PACKAGE_DIR}/luci-app-amlogic/root/etc/config/amlogic
sed -i "s|ARMv8|ARMv8_PLUS|g" ${PACKAGE_DIR}/luci-app-amlogic/root/etc/config/amlogic

# 网络工具（保留1-2个，避免全部启用）
git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns ${PACKAGE_DIR}/luci-app-smartdns
git clone --depth=1 https://github.com/pymumu/openwrt-smartdns ${PACKAGE_DIR}/smartdns
# git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite ${PACKAGE_DIR}/luci-app-msd_lite  # 可选
# git clone --depth=1 https://github.com/ximiTech/msd_lite ${PACKAGE_DIR}/msd_lite  # 可选
# git clone --depth=1 https://github.com/sbwml/luci-app-mosdns ${PACKAGE_DIR}/luci-app-mosdns  # 可选

# 存储相关（按需保留）
# git clone --depth=1 https://github.com/sbwml/luci-app-alist ${PACKAGE_DIR}/luci-app-alist  # 可选

# 其他工具（按需保留）
# git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto  # 可选
# git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto  # 可选
# git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui  # 可选
# git_sparse_clone main https://github.com/linkease/istore luci  # 可选

# 在线用户（核心功能保留）
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
# 修复nlbwmon配置路径（避免文件不存在错误）
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
  sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
  sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings
fi
chmod 755 ${PACKAGE_DIR}/luci-app-onliner/root/usr/share/onliner/setnlbw.sh 2>/dev/null

# x86 型号只显示 CPU 型号（避免文件不存在错误）
if [ -f "package/lean/autocore/files/x86/autocore" ]; then
  sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore
fi

# 修改本地时间格式（避免文件不存在错误）
find package/lean/autocore/files -name "index.htm" -exec sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' {} \;

# 修改版本为编译日期（避免文件不存在错误）
if [ -f "package/lean/default-settings/files/zzz-default-settings" ]; then
  date_version=$(date +"%y.%m.%d")
  orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
  sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings
fi

# 修复 hostapd 报错（确保补丁文件存在）
if [ -f "$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch" ]; then
  mkdir -p package/network/services/hostapd/patches/
  cp -f "$GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch" package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch
fi

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile 2>/dev/null

# 修改 Makefile 路径（避免路径错误）
find ${PACKAGE_DIR}/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find ${PACKAGE_DIR}/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find ${PACKAGE_DIR}/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find ${PACKAGE_DIR}/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find ${PACKAGE_DIR}/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \; 2>/dev/null

# 更新 feeds（确保在OpenWrt根目录执行）
./scripts/feeds update -a
./scripts/feeds install -a
