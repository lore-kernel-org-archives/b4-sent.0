From: Sam Day <me@samcday.com>
Date: Sat, 06 Jun 2026 18:47:39 +1000
Subject: [PATCH 08/11] mach-snapdragon: Integrate reboot-mode handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260606-pm8916-pon-v1-8-170c9cbe5099@samcday.com>
References: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
In-Reply-To: <20260606-pm8916-pon-v1-0-170c9cbe5099@samcday.com>
To: u-boot@lists.denx.de, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Peng Fan <peng.fan@nxp.com>, 
 Leo Yu-Chi Liang <ycliang@andestech.com>, Anshul Dalal <anshuld@ti.com>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Justin Klaassen <justin@tidylabs.net>, 
 Jamie Gibbons <jamie.gibbons@microchip.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Mateus Lima Alves <mateuslima.ti@gmail.com>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Ariel D'Alessandro <ariel.dalessandro@collabora.com>, 
 Dmitrii Merkurev <dimorinny@google.com>, Sam Day <me@samcday.com>, 
 Simon Glass <sjg@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780735669; l=3020;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=0WlTT8AEvmN650XdUlk6qx9h2kaVLx+Xcz/Pldn7PFw=;
 b=6ze8RW6YjXGlwejPD/sDVaBRBQxicAWkG8g9TZQcaTl3SJ3MGEDnaJVH1X1J4DFZjetarkLW1
 SK+stPbj+krCb3c9uSacHIsMZlMXpaSBvTeoHKWvNO0/I74qThV7YBI
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Aswin Murugan <aswin.murugan@oss.qualcomm.com>

Add reboot-mode detection and automatic fastboot entry to Qualcomm board
initialization. This enables 'reboot bootloader' functionality on
platforms with reboot-mode device tree configuration.

Changes:
- Add qcom_handle_reboot_mode() call in board_late_init()
- Conditionally compile with CONFIG_DM_REBOOT_MODE
- Reorganize header includes

Signed-off-by: Aswin Murugan <aswin.murugan@oss.qualcomm.com>
Reviewed-by: Simon Glass <sjg@chromium.org>
---
 arch/arm/mach-snapdragon/board.c | 56 ++++++++++++++++++++++++++++++++--------
 1 file changed, 45 insertions(+), 11 deletions(-)

diff --git a/arch/arm/mach-snapdragon/board.c b/arch/arm/mach-snapdragon/board.c
index 829a0109ac7..c37195def57 100644
--- a/arch/arm/mach-snapdragon/board.c
+++ b/arch/arm/mach-snapdragon/board.c
@@ -9,6 +9,15 @@
 #define LOG_CATEGORY LOGC_BOARD
 #define pr_fmt(fmt) "QCOM: " fmt
 
+#include <command.h>
+#include <env.h>
+#include <fdt_support.h>
+#include <init.h>
+#include <lmb.h>
+#include <malloc.h>
+#include <sort.h>
+#include <time.h>
+#include <usb.h>
 #include <asm/armv8/mmu.h>
 #include <asm/gpio.h>
 #include <asm/io.h>
@@ -16,22 +25,14 @@
 #include <asm/system.h>
 #include <dm/device.h>
 #include <dm/pinctrl.h>
-#include <dm/uclass-internal.h>
 #include <dm/read.h>
-#include <power/regulator.h>
-#include <env.h>
-#include <fdt_support.h>
-#include <init.h>
+#include <dm/uclass-internal.h>
 #include <linux/arm-smccc.h>
 #include <linux/bug.h>
 #include <linux/psci.h>
 #include <linux/sizes.h>
-#include <lmb.h>
-#include <malloc.h>
-#include <fdt_support.h>
-#include <usb.h>
-#include <sort.h>
-#include <time.h>
+#include <power/regulator.h>
+#include <reboot-mode/reboot-mode.h>
 
 #include "qcom-priv.h"
 
@@ -506,6 +507,33 @@ void qcom_show_boot_source(void)
 	env_set("boot_source", name);
 }
 
+/**
+ * qcom_handle_reboot_mode() - Process reboot-mode detection and handle fastboot entry
+ *
+ * This function detects the reboot reason from PMIC registers and automatically
+ * enters fastboot mode if the reboot reason was "bootloader".
+ */
+static void qcom_handle_reboot_mode(void)
+{
+	struct udevice *reboot_dev;
+	const char *reboot_mode;
+	int ret;
+
+	ret = uclass_first_device_err(UCLASS_REBOOT_MODE, &reboot_dev);
+	if (ret)
+		return;
+
+	ret = dm_reboot_mode_update(reboot_dev);
+	if (ret)
+		return;
+
+	reboot_mode = env_get("reboot-mode");
+	if (reboot_mode && !strcmp(reboot_mode, "bootloader")) {
+		printf("Entering fastboot mode due to reboot reason...\n");
+		run_command("run fastboot", 0);
+	}
+}
+
 void __weak qcom_late_init(void)
 {
 }
@@ -575,6 +603,12 @@ int board_late_init(void)
 	qcom_late_init();
 
 	qcom_show_boot_source();
+
+	/* Handle reboot-mode detection and fastboot entry */
+#if IS_ENABLED(CONFIG_DM_REBOOT_MODE)
+	qcom_handle_reboot_mode();
+#endif
+
 	/* Configure the dfu_string for capsule updates */
 	qcom_configure_capsule_updates();
 

-- 
2.54.0

