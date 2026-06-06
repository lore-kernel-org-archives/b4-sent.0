From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 10:52:39 +1000
Subject: [PATCH 05/13] mach-snapdragon: enable BINMAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-android-binman-v1-5-c7a3c14b8a3d@samcday.com>
References: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
In-Reply-To: <20260606-android-binman-v1-0-c7a3c14b8a3d@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Denis Mukhin <dmukhin@ford.com>, Rasmus Villemoes <ravi@prevas.dk>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, Javier Tia <floss@jetm.me>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780707158; l=2049;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=E+/Np8Vg590y2jx5jnU8GbElSTFhQi505VgTF7MzPN0=;
 b=JxaGmXW06BaivUYwJUnvDkP75/76wFyVhph/4eLySNRQq1Toa28CCK/WsM2rgHdlqRoLNXHrH
 6i5Z/tjOo/NDADutszoI9p9LDEoCM6Z9Zq2aFBkXs4Je+hK352xC8xp
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that binman provides abootimg support and we've defined
configuration for it on a number of qcom devices, let's enable BINMAN
for *all* ARCH_SNAPDRAGON builds.

This is a pragmatic choice: BINMAN needs to be pulled in by an existing
Kconfig symbol so we can't just enable it in a .config fragment. Rather
than defining a new symbol that can be opted into, we just opt in
everywhere. There's plenty of prior art for ARCH_* symbols doing exactly
this.

Not necessarily all (though, I suspect, a vast majority) of qcom devices
need or can benefit from binman. Unfortunately, binman will choke if a
DEVICE_TREE= lacking the `binman{}` DT node is selected as the control
FDT. To accommodate this, we drop in a small globally-included .dtsi
fragment that defines an empty binman{} node, so that no builds are
broken.

Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/Kconfig       | 1 +
 arch/arm/dts/qcom.dtsi | 5 +++++
 configs/qcom_defconfig | 1 +
 3 files changed, 7 insertions(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 514bf2000b4..5816194721c 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1135,6 +1135,7 @@ config ARCH_RENESAS
 config ARCH_SNAPDRAGON
 	bool "Qualcomm Snapdragon SoCs"
 	select ARM64
+	select BINMAN
 	select DM
 	select DM_GPIO
 	select DM_SERIAL
diff --git a/arch/arm/dts/qcom.dtsi b/arch/arm/dts/qcom.dtsi
new file mode 100644
index 00000000000..9982e996993
--- /dev/null
+++ b/arch/arm/dts/qcom.dtsi
@@ -0,0 +1,5 @@
+// SPDX-License-Identifier: GPL-2.0
+/ {
+	binman {
+	};
+};
diff --git a/configs/qcom_defconfig b/configs/qcom_defconfig
index d0d54ec5a70..fe026189ee3 100644
--- a/configs/qcom_defconfig
+++ b/configs/qcom_defconfig
@@ -50,6 +50,7 @@ CONFIG_CMD_REGULATOR=y
 CONFIG_CMD_LOG=y
 CONFIG_OF_LIVE=y
 CONFIG_OF_UPSTREAM_BUILD_VENDOR=y
+CONFIG_DEVICE_TREE_INCLUDES="qcom.dtsi"
 CONFIG_ENV_USE_DEFAULT_ENV_TEXT_FILE=y
 CONFIG_ENV_DEFAULT_ENV_TEXT_FILE="board/qualcomm/default.env"
 CONFIG_BUTTON_QCOM_PMIC=y

-- 
2.54.0

