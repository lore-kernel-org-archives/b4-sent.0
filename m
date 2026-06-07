From: Sam Day <me@samcday.com>
Date: Mon, 08 Jun 2026 09:37:17 +1000
Subject: [PATCH v2 8/8] configs: exynos-mobile: pull in BINMAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260608-android-binman-v2-8-b8203682507f@samcday.com>
References: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
In-Reply-To: <20260608-android-binman-v2-0-b8203682507f@samcday.com>
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
 Henrik Grimler <henrik@grimler.se>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780875433; l=1723;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=AwJf3/zy873wIvJbnCoM+ZN4PCzMAP0EqTx9xh5hUOY=;
 b=9qSkJDMOVXU+kWOgKNVuzZnmQnL2idHgGf0XOWFyLkH7Ra4M2yPghtRn9+CJuLwn4EQbDS8te
 cPej9kv3/KEA8U9vlyfzfJ2M0hauDRA1xx4HVWaspyXzkquLULoZvwp
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

All Exynos7 mobile devices need abootimg+DTBH wrapping to be bootable
from the fused S-BOOT bootloader. So we enable BINMAN everywhere.
Ideally we'll have full coverage of these devices with binman configs in
the overlay DTSIs but, for now, we ensure there's a placeholder node.
That way no existing devices will regress their cleanly buildable state.

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

