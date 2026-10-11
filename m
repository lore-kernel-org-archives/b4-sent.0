From: Igor Velkov <iav@iav.lv>
Date: Sun, 11 Oct 2026 05:17:43 +0000
Subject: [PATCH] arm: mvebu: helios4: derive MAC address from SPI NOR
 unique ID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-helios4-flash-uid-mac-v1-1-203cd429f46c@iav.lv>
X-B4-Tracking: v=1; b=H4sIAPYby2oC/x3MSwqAMAwA0atI1gZMERWvIi5CTW3AHw2KIN7d4
 vItZh4wSSoGffFAkktN9y2DygJ85G0W1CkbXOUaqogwyqK71RgWtoinTriyRwqOW+o8+44gt0e
 SoPf/Hcb3/QASykgYZwAAAA==
To: Stefan Roese <stefan.roese@mailbox.org>, 
 Dennis Gilmore <dgilmore@redhat.com>
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3621; i=iav@iav.lv;
 h=from:subject:message-id; bh=2niEr8NMC8m66WbZMz5U4o5Kw4aoSUy4WocltDuWjeo=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFmnpX9wtHUfKj024ZDMwpYz3eu59u81cmqcXlLOa1lf3
 1nM2Pego5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEyk2YHhr8DRGKuTOitcNXQ4
 yg/3lOjf3Dm7enYVB5epDMdaxr8hDxkZJpX+avt2dOYz/cm6udO/exkfzZ/7JyJhZ0vqtUcq+6v
 /sgIA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios4 has no factory MAC address, so without a saved eth1addr it
gets a random one on every boot. Derive a stable, locally administered
address from the SHA-256 of the 64-bit unique ID of the SPI NOR on the
SoM, the way rockchip_setup_macaddr() does with the CPU ID. A saved
eth1addr still takes precedence.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios4: two power cycles give the same address and DHCP
uses it. With the same change on v2026.07, Linux gets the address
through the device tree and a saved eth1addr is left untouched.
---
 board/kobol/helios4/helios4.c | 58 +++++++++++++++++++++++++++++++++++++++++++
 configs/helios4_defconfig     |  3 +++
 2 files changed, 61 insertions(+)

diff --git a/board/kobol/helios4/helios4.c b/board/kobol/helios4/helios4.c
index 7714076edf1..342a3cb3c73 100644
--- a/board/kobol/helios4/helios4.c
+++ b/board/kobol/helios4/helios4.c
@@ -5,15 +5,21 @@
  */
 
 #include <config.h>
+#include <env.h>
 #include <i2c.h>
 #include <init.h>
 #include <miiphy.h>
 #include <net.h>
 #include <netdev.h>
+#include <spi-mem.h>
+#include <spi_flash.h>
 #include <asm/global_data.h>
 #include <asm/io.h>
 #include <asm/arch/cpu.h>
 #include <asm/arch/soc.h>
+#include <dm/device.h>
+#include <linux/string.h>
+#include <u-boot/sha256.h>
 
 #include "../drivers/ddr/marvell/a38x/ddr3_init.h"
 #include <../serdes/a38x/high_speed_env_spec.h>
@@ -133,3 +139,55 @@ int board_eth_init(struct bd_info *bis)
 	cpu_eth_init(bis); /* Built in controller(s) come first */
 	return pci_eth_init(bis);
 }
+
+#define SPINOR_OP_RDUID		0x4b
+#define SPINOR_UID_LEN		8
+
+static int helios4_read_flash_uid(u8 *uid)
+{
+	struct spi_mem_op op =
+		SPI_MEM_OP(SPI_MEM_OP_CMD(SPINOR_OP_RDUID, 1),
+			   SPI_MEM_OP_NO_ADDR,
+			   SPI_MEM_OP_DUMMY(4, 1),
+			   SPI_MEM_OP_DATA_IN(SPINOR_UID_LEN, uid, 1));
+	struct spi_flash *flash;
+	struct udevice *dev;
+	int ret;
+
+	ret = spi_flash_probe_bus_cs(CONFIG_SF_DEFAULT_BUS,
+				     CONFIG_SF_DEFAULT_CS, &dev);
+	if (ret)
+		return ret;
+
+	flash = dev_get_uclass_priv(dev);
+	ret = spi_mem_exec_op(flash->spi, &op);
+	if (ret)
+		return ret;
+
+	if (!memchr_inv(uid, 0x00, SPINOR_UID_LEN) ||
+	    !memchr_inv(uid, 0xff, SPINOR_UID_LEN))
+		return -ENODATA;
+
+	return 0;
+}
+
+/*
+ * The board has no factory MAC address, so derive a stable one from the
+ * unique ID of the SPI NOR on the SoM.
+ */
+int misc_init_r(void)
+{
+	u8 uid[SPINOR_UID_LEN];
+	u8 mac[SHA256_SUM_LEN];
+
+	/* ethernet@70000 is aliased as ethernet1 */
+	if (env_get("eth1addr") || helios4_read_flash_uid(uid))
+		return 0;
+
+	sha256_csum_wd(uid, sizeof(uid), mac, CHUNKSZ_SHA256);
+	mac[0] &= 0xfe;	/* unicast */
+	mac[0] |= 0x02;	/* locally administered */
+	eth_env_set_enetaddr("eth1addr", mac);
+
+	return 0;
+}
diff --git a/configs/helios4_defconfig b/configs/helios4_defconfig
index c78a41058c8..328e9e92727 100644
--- a/configs/helios4_defconfig
+++ b/configs/helios4_defconfig
@@ -33,6 +33,7 @@ CONFIG_USE_PREBOOT=y
 CONFIG_SYS_CONSOLE_INFO_QUIET=y
 # CONFIG_DISPLAY_BOARDINFO is not set
 CONFIG_DISPLAY_BOARDINFO_LATE=y
+CONFIG_MISC_INIT_R=y
 CONFIG_SPL_MAX_SIZE=0x22fd0
 CONFIG_SPL_SYS_MALLOC_SIMPLE=y
 CONFIG_SPL_I2C=y
@@ -80,3 +81,5 @@ CONFIG_SYS_NS16550=y
 CONFIG_KIRKWOOD_SPI=y
 CONFIG_USB=y
 CONFIG_USB_XHCI_HCD=y
+CONFIG_SHA256=y
+# CONFIG_SPL_SHA256 is not set

---
base-commit: 5e3b01c8466dbe45cd6a06299f8f4c7e8c1c2363
change-id: 20261011-helios4-flash-uid-mac-1f2a718cac81

Best regards,
-- 
Igor Velkov <iav@iav.lv>

