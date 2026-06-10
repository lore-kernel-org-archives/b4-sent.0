From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:48 +1000
Subject: [PATCH v3 10/10] configs: exynos-mobile: pull in binman
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-10-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=1768;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=NRBHpe34CND7n6voXLMnN6rRvIFMkJs8mIzyqLmR+Uk=;
 b=C9Z4cucraCqjuataCkCM/TVL3trF5h3nVX46fAmkzi/DEFe8qWoDuW+DzeCMo1vBIy62CzJyE
 j8pgu6JS32YBIfQRDTncga7FfmJCKruP+DsXB0zOdsb0hMFvw9u/3pN
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All Exynos7 mobile devices need abootimg+DTBH wrapping to be bootable
from the fused S-BOOT bootloader. So we enable binman everywhere.
Ideally we'll have full coverage of these devices with binman configs in
the overlay DTSIs but, for now, we ensure there's a placeholder node.
That way no existing devices will regress their cleanly buildable state.

Reviewed-by: Simon Glass <sjg@chromium.org>
Signed-off-by: Sam Day <me@samcday.com>
---
 arch/arm/dts/exynos-mobile.dtsi | 5 +++++
 arch/arm/mach-exynos/Kconfig    | 1 +
 configs/exynos-mobile_defconfig | 1 +
 3 files changed, 7 insertions(+)

diff --git a/arch/arm/dts/exynos-mobile.dtsi b/arch/arm/dts/exynos-mobile.dtsi
new file mode 100644
index 00000000000..9982e996993
--- /dev/null
+++ b/arch/arm/dts/exynos-mobile.dtsi
@@ -0,0 +1,5 @@
+// SPDX-License-Identifier: GPL-2.0
+/ {
+	binman {
+	};
+};
diff --git a/arch/arm/mach-exynos/Kconfig b/arch/arm/mach-exynos/Kconfig
index b084b7284aa..d4ae182030d 100644
--- a/arch/arm/mach-exynos/Kconfig
+++ b/arch/arm/mach-exynos/Kconfig
@@ -255,6 +255,7 @@ endif
 config TARGET_EXYNOS_MOBILE
 	bool "Samsung Exynos Generic Boards (for mobile devices)"
 	select ARM64
+	select BINMAN
 	select BOARD_EARLY_INIT_F
 	select CLK_EXYNOS
 	select LINUX_KERNEL_IMAGE_HEADER
diff --git a/configs/exynos-mobile_defconfig b/configs/exynos-mobile_defconfig
index 45ab998bb45..fcaff3d1608 100644
--- a/configs/exynos-mobile_defconfig
+++ b/configs/exynos-mobile_defconfig
@@ -32,6 +32,7 @@ CONFIG_EFI_PARTITION=y
 CONFIG_OF_UPSTREAM=y
 CONFIG_OF_UPSTREAM_BUILD_VENDOR=y
 CONFIG_OF_BOARD=y
+CONFIG_DEVICE_TREE_INCLUDES="exynos-mobile.dtsi"
 CONFIG_BLKMAP=y
 CONFIG_BUTTON_REMAP_PHONE_KEYS=y
 CONFIG_CLK_EXYNOS7870=y

-- 
2.54.0

