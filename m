From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:58 +0200
Subject: [PATCH 10/11] cmd: phone_util: fix "Cannot set reboot flag" on
 fastboot reboot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-10-bfa23de6eb0b@protonmail.com>
References: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
In-Reply-To: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Peter Robinson <pbrobinson@gmail.com>, Brian Sune <briansune@gmail.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, Petr Pavlata <petr@acrux.cz>, 
 David Heidelberg <david@ixit.cz>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=1899;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=U+FeA8s5R7chNO8f+vErw4D3wV1XAzTW15uszADFsZM=;
 b=Hk0i+6tTHAEPTIgrBL1w5c976hxRz6SIzcG2O1qegJ73+7Eg6x+YH9ANZlxpTfuTYtk8SyBQC
 PmeETXK7737AFvlfkQcT6x2DtZd1DAh91pgkIW3+0NO25RJcGCpVE8F
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Select the correct storage media based on the 'storage' env to access
the BCB partition.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/phone_util.c | 36 ++++++++++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/cmd/phone_util.c b/cmd/phone_util.c
index 1389b2ca6cd..8367e5729c0 100644
--- a/cmd/phone_util.c
+++ b/cmd/phone_util.c
@@ -1,14 +1,18 @@
 // SPDX-License-Identifier: GPL-2.0+
 
+#include <bcb.h>
 #include <button.h>
 #include <command.h>
 #include <cyclic.h>
 #include <dfu.h>
+#include <env.h>
+#include <fastboot.h>
 #include <g_dnl.h>
 #include <net-common.h>
 #include <stdio.h>
 #include <asm/system.h>
 #include <linux/delay.h>
+#include <linux/errno.h>
 
 #if CONFIG_IS_ENABLED(USB_ETHER)
 static int do_usbether(struct cmd_tbl *cmdtp, int flag, int argc,
@@ -110,3 +114,35 @@ U_BOOT_CMD(dfu_pwr, 1, 0, do_dfu_pwr,
 	   "    - Run the `dfu` env alias with a cyclic that triggers a\n"
 	   "      gadget detach when the power button is pressed.");
 #endif /* CMD_DFU */
+
+#if IS_ENABLED(CONFIG_FASTBOOT)
+/*
+ * Pick the BCB partition on the correct storags media
+ */
+int fastboot_set_reboot_flag(enum fastboot_reboot_reason reason)
+{
+	static const char * const boot_cmds[] = {
+		[FASTBOOT_REBOOT_REASON_BOOTLOADER] = "bootonce-bootloader",
+		[FASTBOOT_REBOOT_REASON_FASTBOOTD] = "boot-fastboot",
+		[FASTBOOT_REBOOT_REASON_RECOVERY] = "boot-recovery"
+	};
+	const char *storage = env_get("storage");
+	int ret;
+
+	if (reason >= FASTBOOT_REBOOT_REASONS_COUNT)
+		return -EINVAL;
+
+	ret = bcb_find_partition_and_load(storage ?: "scsi", 0, "misc");
+	if (ret)
+		goto out;
+
+	ret = bcb_set(BCB_FIELD_COMMAND, boot_cmds[reason]);
+	if (ret)
+		goto out;
+
+	ret = bcb_store();
+out:
+	bcb_reset();
+	return ret;
+}
+#endif /* CONFIG_FASTBOOT */

-- 
2.55.0

