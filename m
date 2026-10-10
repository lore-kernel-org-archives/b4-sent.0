From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:49 +0200
Subject: [PATCH 01/11] cmd: phone_util: add poweroff, dfu_pwr and USB
 Ethernet commands
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-1-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=5321;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ipns/rRhdwFduSLrtTa8xA4XHuqDuWoshEjGFZzNTqc=;
 b=WFSlL3FK83EoBqSQp68T+zXQCw/iQo4o9im0mAQl43aZ9EOyJXY7H35h7GIPYwndvhNXewZYO
 Ct/+yUCB643D1aRgoYhJEA9DcVdswFTibAqUj2QCDHcMHIizh5zkFyK
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add CONFIG_CMD_PHONEMENU for cmd/phone_util.c which adds two
commands to be used as menu actions:

- qcom_poweroff: power off via PSCI SYSTEM_OFF
- usbether: bind and probe the USB Ethernet (RNDIS) gadget on demand
- dfu_pwr command which handles power button press to exit the DFU mode
  without board reboot

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS      |   1 +
 cmd/Kconfig      |  11 ++++++
 cmd/Makefile     |   1 +
 cmd/phone_util.c | 112 +++++++++++++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 125 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 45e9076de67..4b0b0b2f3a5 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -687,6 +687,7 @@ R:	Sumit Garg <sumit.garg@kernel.org>
 L:	u-boot-qcom@groups.io
 S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
+F:	cmd/phone_util.c
 F:	configs/qcm6490_defconfig
 F:	configs/qcs9100_defconfig
 F:	drivers/*/*/pm8???-*
diff --git a/cmd/Kconfig b/cmd/Kconfig
index c71c6824a19..09dbf73afdc 100644
--- a/cmd/Kconfig
+++ b/cmd/Kconfig
@@ -521,6 +521,17 @@ config CMD_BOOTMENU
 	help
 	  Add an ANSI terminal boot menu command.
 
+config CMD_PHONEMENU
+	bool "Boot menu for devices with high resolution display"
+	depends on VIDEO && ARM
+	select MENU
+	select CMD_BOOTMENU
+	help
+	  ANSI-styled boot menu laid out in labelled sections, intended for
+	  devices with high resolution displays. Navigation reuses the bootmenu
+	  key handler, so volume up/down and power work through
+	  BUTTON_REMAP_PHONE_KEYS.
+
 config CMD_ADTIMG
 	bool "adtimg"
 	help
diff --git a/cmd/Makefile b/cmd/Makefile
index bbbdfcc4ded..762572156cd 100644
--- a/cmd/Makefile
+++ b/cmd/Makefile
@@ -36,6 +36,7 @@ obj-$(CONFIG_CMD_BMP) += bmp.o
 obj-$(CONFIG_CMD_BOOTCOUNT) += bootcount.o
 obj-$(CONFIG_CMD_BOOTEFI) += bootefi.o
 obj-$(CONFIG_CMD_BOOTMENU) += bootmenu.o
+obj-$(CONFIG_CMD_PHONEMENU) += phone_util.o
 obj-$(CONFIG_CMD_BOOTSTAGE) += bootstage.o
 obj-$(CONFIG_CMD_BOOTZ) += bootz.o
 obj-$(CONFIG_CMD_BOOTI) += booti.o
diff --git a/cmd/phone_util.c b/cmd/phone_util.c
new file mode 100644
index 00000000000..1389b2ca6cd
--- /dev/null
+++ b/cmd/phone_util.c
@@ -0,0 +1,112 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <button.h>
+#include <command.h>
+#include <cyclic.h>
+#include <dfu.h>
+#include <g_dnl.h>
+#include <net-common.h>
+#include <stdio.h>
+#include <asm/system.h>
+#include <linux/delay.h>
+
+#if CONFIG_IS_ENABLED(USB_ETHER)
+static int do_usbether(struct cmd_tbl *cmdtp, int flag, int argc,
+		       char *const argv[])
+{
+	int ret = usb_ether_init();
+
+	if (ret < 0) {
+		printf("usb_ether init failed: %d\n", ret);
+		return CMD_RET_FAILURE;
+	}
+	return CMD_RET_SUCCESS;
+}
+
+U_BOOT_CMD(usbether, 1, 0, do_usbether,
+	   "start USB Ethernet (RNDIS) gadget for tftp/pxe boot",
+	   "\n"
+	   "    - Bind the USB Ethernet gadget driver. After running, set");
+#endif
+
+static int do_phone_poweroff(struct cmd_tbl *cmdtp, int flag, int argc,
+			     char *const argv[])
+{
+	if (!CONFIG_IS_ENABLED(PSCI_RESET)) {
+		printf("PSCI not enabled on this board - cannot power off\n");
+		return CMD_RET_FAILURE;
+	}
+
+	puts("\nPowering off via PSCI SYSTEM_OFF\n");
+	mdelay(50);
+	psci_system_off();
+	return CMD_RET_FAILURE;
+}
+
+U_BOOT_CMD(phone_poweroff, 1, 0, do_phone_poweroff,
+	   "power off the device via PSCI SYSTEM_OFF",
+	   "\n"
+	   "    - Invoke PSCI 0.2 SYSTEM_OFF. TZ handles the PMIC sequencing");
+
+#if CONFIG_IS_ENABLED(CMD_DFU)
+/*
+ * DFU with a power-button exit. The stock DFU loop in common/dfu.c polls
+ * g_dnl_detach() and ctrlc() on every iteration so a call to
+ * g_dnl_trigger_detach() will return us back to the menu.
+ */
+static bool dfu_pwr_pressed;
+static bool dfu_pwr_exit_requested;
+static struct udevice *dfu_pwr_btn;
+static struct cyclic_info dfu_pwr_cyc;
+
+bool dfu_usb_get_reset(void)
+{
+	return !dfu_pwr_exit_requested;
+}
+
+static void dfu_pwr_poll(struct cyclic_info *c)
+{
+	if (dfu_pwr_pressed)
+		return;
+	if (button_get_state(dfu_pwr_btn) == BUTTON_ON) {
+		dfu_pwr_pressed = true;
+		dfu_pwr_exit_requested = true;
+		g_dnl_trigger_detach();
+	}
+}
+
+static int do_dfu_pwr(struct cmd_tbl *cmdtp, int flag, int argc,
+		      char *const argv[])
+{
+	int ret;
+
+	ret = button_get_by_label("Power Button", &dfu_pwr_btn);
+	if (ret) {
+		printf("Power Button not found (err=%d)\n", ret);
+		return CMD_RET_FAILURE;
+	}
+
+	puts("\nDFU mode active. Press the power button to exit.\n");
+
+	dfu_pwr_pressed = false;
+	dfu_pwr_exit_requested = false;
+	cyclic_register(&dfu_pwr_cyc, dfu_pwr_poll,
+			50 * 1000, "dfu_pwr_exit");
+
+	ret = run_command("run dfu", 0);
+
+	cyclic_unregister(&dfu_pwr_cyc);
+
+	/* Debounce release so the press doesn't cascade into the menu. */
+	while (button_get_state(dfu_pwr_btn) == BUTTON_ON)
+		mdelay(20);
+
+	return ret;
+}
+
+U_BOOT_CMD(dfu_pwr, 1, 0, do_dfu_pwr,
+	   "enter DFU mode; exit on power-button press",
+	   "\n"
+	   "    - Run the `dfu` env alias with a cyclic that triggers a\n"
+	   "      gadget detach when the power button is pressed.");
+#endif /* CMD_DFU */

-- 
2.55.0

