From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:48 +1000
Subject: [PATCH RESEND 07/16] configs: introduce qcom_armv7_defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-7-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=2157;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=mxwycB2A5GwzFMwdIjogaHy0a126Zo0vOB3W8d6mYkk=;
 b=qDOyuYXOpZ83YNvm+F7hI6hnRKxfhNmdB5Ft2rCdY7+Ku76rndA8oKv2cqupHY7enJkajZxoM
 UQ8A7RGPIoqBvWwXNWsE7CVfrIczk+CqFd7CAE6g64A1/Jogz7g8DgE
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This new config aims to be analogous to qcom_defconfig, but for armv7
devices. It can compose with qcom-phone.config.

Signed-off-by: Sam Day <me@samcday.com>
---
 configs/qcom_armv7_defconfig | 59 ++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 59 insertions(+)

diff --git a/configs/qcom_armv7_defconfig b/configs/qcom_armv7_defconfig
new file mode 100644
index 00000000000..7d64ee68ecd
--- /dev/null
+++ b/configs/qcom_armv7_defconfig
@@ -0,0 +1,59 @@
+CONFIG_ARM=y
+CONFIG_SKIP_LOWLEVEL_INIT=y
+CONFIG_SYS_ICACHE_OFF=y
+CONFIG_SYS_DCACHE_OFF=y
+CONFIG_ARCH_SNAPDRAGON=y
+CONFIG_TEXT_BASE=0x80208000
+CONFIG_NR_DRAM_BANKS=24
+CONFIG_HAS_CUSTOM_SYS_INIT_SP_ADDR=y
+CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x88FE0000
+CONFIG_DEFAULT_DEVICE_TREE="qcom/qcom-msm8960-cdp"
+CONFIG_SYS_LOAD_ADDR=0x82000000
+CONFIG_ARCH_SNAPDRAGON_ARM32=y
+CONFIG_EFI_RUNTIME_UPDATE_CAPSULE=y
+CONFIG_EFI_CAPSULE_ON_DISK=y
+CONFIG_EFI_CAPSULE_FIRMWARE_RAW=y
+# CONFIG_ANDROID_BOOT_IMAGE is not set
+CONFIG_BOOTSTD_FULL=y
+CONFIG_BOOTDELAY=1
+CONFIG_SYS_CBSIZE=512
+# CONFIG_DISPLAY_CPUINFO is not set
+CONFIG_DISPLAY_BOARDINFO_LATE=y
+CONFIG_CMD_BOOTMENU=y
+CONFIG_CMD_MEMINFO=y
+CONFIG_CMD_MEMINFO_MAP=y
+# CONFIG_CMD_BIND is not set
+CONFIG_CMD_CLK=y
+CONFIG_CMD_GPIO=y
+CONFIG_CMD_MMC=y
+CONFIG_CMD_USB_MASS_STORAGE=y
+CONFIG_CMD_CAT=y
+CONFIG_CMD_BMP=y
+CONFIG_CMD_LOG=y
+CONFIG_OF_UPSTREAM_BUILD_VENDOR=y
+CONFIG_ENV_USE_DEFAULT_ENV_TEXT_FILE=y
+CONFIG_ENV_DEFAULT_ENV_TEXT_FILE="board/qualcomm/default.env"
+CONFIG_CLK=y
+CONFIG_USB_FUNCTION_FASTBOOT=y
+CONFIG_FASTBOOT_BUF_ADDR=0x0
+CONFIG_FASTBOOT_FLASH=y
+CONFIG_FASTBOOT_FLASH_MMC_DEV=0
+CONFIG_FASTBOOT_MMC_USER_SUPPORT=y
+CONFIG_MSM_GPIO=y
+CONFIG_DM_KEYBOARD=y
+CONFIG_BUTTON_KEYBOARD=y
+CONFIG_PINCTRL=y
+CONFIG_MSM_SERIAL=y
+CONFIG_SYSRESET_QCOM_PSHOLD=y
+CONFIG_TIMER=y
+CONFIG_QCOM_KPSS_TIMER=y
+CONFIG_USB=y
+# CONFIG_DM_USB_GADGET is not set
+CONFIG_USB_EHCI_HCD=y
+CONFIG_USB_EHCI_MSM=y
+CONFIG_USB_GADGET=y
+CONFIG_CI_UDC=y
+CONFIG_VIDEO=y
+CONFIG_SYS_WHITE_ON_BLACK=y
+CONFIG_NO_FB_CLEAR=y
+CONFIG_VIDEO_SIMPLE=y

-- 
2.54.0

