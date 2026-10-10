From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:56 +0200
Subject: [PATCH 08/11] cmd: phonemenu: show PMIC PON status in the header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-8-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=4846;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=u1rUtxX6vWbMpiKwFd7SUmHwHmkYwGmjTNjSk2KAbiQ=;
 b=iSCrAwApJhluMQSO6VJAiB0J0sHhZpsWXtL6x2ATwphYNLZgy3XERkSaDe44xY3AJ9tg7DLh5
 t24LS8LrA+0CjA5gY1JKex52DAxUa1U0ZVa+MnVBf+p7RlrZT0gz0b5
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Show in the boot menu header the PMIC Power-On Notification trigger
from the QPNP-PON block of a PMIC, distinguishing cold vs. warm reset
and its cause.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/phonemenu.c      | 10 +++++++
 cmd/phonemenu_qcom.c | 84 ++++++++++++++++++++++++++++++++++++++++++++++++++++
 include/phonemenu.h  |  3 ++
 3 files changed, 97 insertions(+)

diff --git a/cmd/phonemenu.c b/cmd/phonemenu.c
index 8f29d8d704b..f031b891641 100644
--- a/cmd/phonemenu.c
+++ b/cmd/phonemenu.c
@@ -458,6 +458,12 @@ __weak int phonemenu_ab_slot(void)
 	return ab_select_slot(desc, &misc, false);
 }
 
+/* PMIC power-on trigger for the header, NULL if unknown */
+__weak const char *phonemenu_pon_status(void)
+{
+	return NULL;
+}
+
 static const char *pm_slot(void)
 {
 	int slot;
@@ -510,6 +516,7 @@ static int do_phonemenu(struct cmd_tbl *cmdtp, int flag, int argc,
 	static char slot_line[96];
 	const char *slot = pm_slot();
 	const char *reason = pm_reason();
+	const char *pon = phonemenu_pon_status();
 	const char *sub = (argc > 1) ? argv[1] : "main";
 	int n = 0;
 
@@ -519,6 +526,9 @@ static int do_phonemenu(struct cmd_tbl *cmdtp, int flag, int argc,
 	if (reason)
 		n += snprintf(slot_line + n, sizeof(slot_line) - n,
 			      "%s%s", n ? "  -  " : "", reason);
+	if (pon)
+		n += snprintf(slot_line + n, sizeof(slot_line) - n,
+			      "%s%s", n ? "  -  " : "", pon);
 
 	if (!strcmp(sub, "advanced"))
 		return pm_run(pm_advanced, ARRAY_SIZE(pm_advanced),
diff --git a/cmd/phonemenu_qcom.c b/cmd/phonemenu_qcom.c
index d8a295c10dc..20a1cced8d9 100644
--- a/cmd/phonemenu_qcom.c
+++ b/cmd/phonemenu_qcom.c
@@ -5,8 +5,12 @@
 
 #include <android_ab.h>
 #include <blk.h>
+#include <dm.h>
+#include <dm/ofnode.h>
+#include <dm/uclass.h>
 #include <part.h>
 #include <phonemenu.h>
+#include <power/pmic.h>
 #include <linux/errno.h>
 
 #if IS_ENABLED(CONFIG_ARCH_SNAPDRAGON)
@@ -25,4 +29,84 @@ int phonemenu_ab_slot(void)
 	return ab_select_slot(desc, &unused, false);
 }
 
+/*
+ * PMIC PON ("Power-On Notification") boot trigger from the QPNP-PON block
+ * in the primary PMIC. Two registers are interesting:
+ *
+ *   PON_REASON1 (PON base + 0x0c) - cold-reset trigger:
+ *     0x80 KPDPWR   = power button press
+ *     0x40 CBLPWR   = cable inserted while off
+ *     0x20 PON1     = generic PON
+ *     0x10 USB_CHG  = USB charger inserted
+ *     0x08 DC_CHG   = DC charger inserted
+ *     0x04 RTC      = RTC alarm
+ *     0x02 SMPL     = sudden mains power loss / auto-restart
+ *     0x01 HARDRST  = hard reset requested
+ *
+ *   WARM_RESET_REASON1 (PON base + 0x0a) - warm-reset trigger:
+ *     0x80 KPDPWR        = power-button reset
+ *     0x40 RESIN         = volume-down (or assigned) reset
+ *     0x20 KPDPWR_RESIN  = power + vol-down combo (force reset)
+ *     0x04 PMIC_WD       = PMIC watchdog
+ *     0x02 PS_HOLD       = SoC pulled PS_HOLD low (normal reboot)
+ *     0x01 SOFT          = soft reset request
+ *
+ * If WARM_RESET_REASON1 is non-zero this was a warm reboot and we use it;
+ * otherwise PON_REASON1 wins. Returned strings are short for the menu
+ * subtitle. NULL if we can't find a PM660-class PMIC at all.
+ */
+const char *phonemenu_pon_status(void)
+{
+	struct udevice *pmic;
+	int r;
+
+	for (uclass_first_device(UCLASS_PMIC, &pmic);
+	     pmic;
+	     uclass_next_device(&pmic)) {
+		if (ofnode_device_is_compatible(dev_ofnode(pmic),
+						"qcom,pm660"))
+			break;
+	}
+	if (!pmic)
+		return NULL;
+
+	r = pmic_reg_read(pmic, 0x80a);
+	if (r > 0) {
+		if (r & 0x20)
+			return "warm: pwr+vol-";
+		if (r & 0x80)
+			return "warm: pwr";
+		if (r & 0x40)
+			return "warm: vol-";
+		if (r & 0x04)
+			return "warm: wdog";
+		if (r & 0x02)
+			return "warm: reboot";
+		if (r & 0x01)
+			return "warm: soft";
+		return "warm";
+	}
+
+	r = pmic_reg_read(pmic, 0x80c);
+	if (r > 0) {
+		if (r & 0x80)
+			return "cold: pwr";
+		if (r & 0x40)
+			return "cold: cable";
+		if (r & 0x10)
+			return "cold: usb";
+		if (r & 0x08)
+			return "cold: dc";
+		if (r & 0x04)
+			return "cold: rtc";
+		if (r & 0x02)
+			return "cold: smpl";
+		if (r & 0x01)
+			return "cold: hardrst";
+		if (r & 0x20)
+			return "cold";
+	}
+	return NULL;
+}
+
 #endif /* CONFIG_ARCH_SNAPDRAGON */
diff --git a/include/phonemenu.h b/include/phonemenu.h
index 5d6ded84197..ad33e9511c1 100644
--- a/include/phonemenu.h
+++ b/include/phonemenu.h
@@ -11,4 +11,7 @@ struct blk_desc *phonemenu_storage_desc(void);
 /* Active A/B slot (0 = a, 1 = b) or a negative errno */
 int phonemenu_ab_slot(void);
 
+/* Short PMIC power-on trigger string, or NULL if unknown */
+const char *phonemenu_pon_status(void);
+
 #endif

-- 
2.55.0

