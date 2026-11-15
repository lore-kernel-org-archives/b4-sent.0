From: Igor Velkov <iav@iav.lv>
Date: Sun, 15 Nov 2026 03:50:31 +0000
Subject: [PATCH 2/3] board: amlogic: odroid-n2: tell BL301 whether to wake
 on LAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-meson-scp-wol-v1-2-80c3e9f4deda@iav.lv>
References: <20261115-b4-meson-scp-wol-v1-0-80c3e9f4deda@iav.lv>
In-Reply-To: <20261115-b4-meson-scp-wol-v1-0-80c3e9f4deda@iav.lv>
To: Neil Armstrong <neil.armstrong@linaro.org>, u-boot-amlogic@groups.io
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2297; i=iav@iav.lv;
 h=from:subject:message-id; bh=3fdHEF8KsKvIXWDttHsUdkfsf3IxMKZP/SPsXxR+yF8=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk/ddgrvZ5c3qqfNlXL84eRfNaWsMXqt990WF07sLU07
 LGV1m+djlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjAR+WJGhpdMOzQ+TuTJeit5
 O2bTveeTveS/r3a5lbHh5PGCaTppW1gY/scLaTJNu7s/Wun6xicHl7P9cVnl8yF2Wpnsj2pL+2U
 XKxgA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unless SCPI client 7 has been set to a non-zero value, the Hardkernel
BL301 for ODROID-C4/HC4 switches VCCK_B and the 3.3 V rail off in
suspend and does not add the PHY interrupt (GPIOZ_14) to its wake
sources.

With CONFIG_MESON_G12A_SCPI, send 1 when the Ethernet PHY in the device
tree passed to the OS has wakeup-source, and 0 otherwise. BL301 keeps
the last value, so it is sent on every fixup and the last fixup before
the OS starts wins.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 board/amlogic/odroid-n2/odroid-n2.c | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/board/amlogic/odroid-n2/odroid-n2.c b/board/amlogic/odroid-n2/odroid-n2.c
index ae953d0e4ba..94aaa6ca9ad 100644
--- a/board/amlogic/odroid-n2/odroid-n2.c
+++ b/board/amlogic/odroid-n2/odroid-n2.c
@@ -7,6 +7,7 @@
 #include <dm.h>
 #include <adc.h>
 #include <env.h>
+#include <fdtdec.h>
 #include <init.h>
 #include <net.h>
 #include <asm/io.h>
@@ -14,6 +15,7 @@
 #include <asm/arch/sm.h>
 #include <asm/arch/eth.h>
 #include <asm/arch/boot.h>
+#include <asm/arch/scpi.h>
 
 #define EFUSE_MAC_OFFSET	20
 #define EFUSE_MAC_SIZE		12
@@ -24,6 +26,9 @@
 #define MESON_SOC_ID_G12B	0x29
 #define MESON_SOC_ID_SM1	0x2b
 
+/* Hardkernel BL301 client: 1 = stay powered in suspend and wake on the PHY */
+#define SCPI_CL_WOL		7
+
 int mmc_get_env_dev(void)
 {
 	if (meson_get_boot_device() == BOOT_DEVICE_EMMC)
@@ -138,3 +143,29 @@ int misc_init_r(void)
 	odroid_detect_variant();
 	return 0;
 }
+
+/*
+ * BL301 keeps the last value sent, so we send one on every fixup: the last
+ * fixup before the OS starts wins.
+ */
+int meson_ft_board_setup(void *blob, struct bd_info *bd)
+{
+	bool wol = false;
+	int node, phy, ret;
+
+	if (!IS_ENABLED(CONFIG_MESON_G12A_SCPI))
+		return 0;
+
+	node = fdt_node_offset_by_compatible(blob, -1,
+					     "amlogic,meson-g12a-dwmac");
+	if (node >= 0 && fdtdec_get_is_enabled(blob, node)) {
+		phy = fdtdec_lookup_phandle(blob, node, "phy-handle");
+		wol = phy >= 0 && fdtdec_get_bool(blob, phy, "wakeup-source");
+	}
+
+	ret = meson_scpi_set_usr_data(SCPI_CL_WOL, wol);
+	if (ret)
+		printf("SCP: setting Wake-on-LAN to %d failed: %d\n", wol, ret);
+
+	return 0;
+}

-- 
2.43.0

