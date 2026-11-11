From: =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
Date: Thu, 12 Nov 2026 00:42:01 +0300
Subject: [PATCH] platform/x86: huawei-wmi: Set battery charge thresholds
 through \SBCM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261112-huawei-wmi-charge-mode-v1-1-89974ab1e859@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqDMBAF0KsMf+2Ak4rSXKV0EZKJmYVaEloF8
 e4F3wHeiabVtMHTiao/a7at8CQdIZawzsqW4Amud6OIOC7fsKvxvhjHEuqsvGxJecpDjs9xkEe
 f0BE+VbMdd/x6X9cfbHNpbWgAAAA=
X-Change-ID: 20261112-huawei-wmi-charge-mode-7f4fc964130d
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Eren_=C3=96zen?= <erenozen@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794433329; l=8844;
 i=erenozen@protonmail.com; s=20261110; h=from:subject:message-id;
 bh=nxTo3yrgLY39Tbu/qZyO+niDlk6IopPlQicF8+c6U5M=;
 b=qt6MLNtiiC8TzEN0lqM6cRvjvS3dlAAcp3BQ6SCu3pKDkwNXypDRCE61VRGqVmmmVjxTXD1Sz
 J86/ulgdSe5AG7sfDiKazdSJpn8X4b/nZnhtiD5eJEtR6qUBfSSsFZb
X-Developer-Key: i=erenozen@protonmail.com; a=ed25519;
 pk=tPAwfVmIbYF3QziJ3LcoTIZDU12BsjVK+EkAB9nN1gA=
X-Endpoint-Received: by B4 Relay for erenozen@protonmail.com/20261110 with auth_id=1479
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Newer Huawei firmware implements \GBCM/\SBCM ("battery charge mode",
HWMI functions 0x1603 and 0x1503) next to \GBTT/\SBTT. Besides a pair
of thresholds, they hold a charge mode and a parameter byte of unknown
meaning.

On the HUAWEI MateBook 16 (CREM-WXX9, BIOS 2.32), the charge mode
decides whether the EC uses the thresholds returned by \GBTT. With the
charger connected and the battery above the end threshold, the battery
discharged in charge modes 1, 2 and 3, but charged in modes 0 and 4.

The driver disables the limit by writing 0/100 through \SBTT, which
stores it as 0/0. On this machine that switches the EC to charge mode 4
("smart charge" in Huawei's PC Manager), after which \GBTT reports
40/70 and so does the driver. In this mode, with the charger connected,
the battery charged from 75% to 87% in 20 minutes and was still
charging (at 81% it had not started charging).

A later \SBTT write does not necessarily leave charge mode 4. 40/70
switched the EC back to charge mode 1, but with 75/80, a pair UPower
writes on this machine, the EC stayed in charge mode 4 and the battery
kept charging at 88% while the driver reported 75/80. So once GNOME's
"Preserve Battery Health" setting has been turned off, turning it back
on can leave the battery charging past the limit.

When the firmware provides \GBCM and \SBCM, write the thresholds
through \SBCM in charge mode 1, keeping the parameter byte reported by
the firmware, and write 0/100 as 0/0. Thresholds set through \SBCM are
also reported by \GBTT, so keep reading them from there, but report
0/100 while the EC is in a charge mode other than 1 to 3, which may
have been set by another OS or an older kernel. Report an end threshold
of 0 as 100.

The new interface is only used if both methods exist and \GBCM returns
a zero status, so other firmware keeps using \GBTT/\SBTT unchanged.

Link: https://github.com/aymanbagabas/Huawei-WMI/issues/55
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Eren Özen <erenozen@protonmail.com>
---
Tested on a HUAWEI MateBook 16 (CREM-WXX9, AMD, BIOS 2.32) running
Fedora's 7.2.15 kernel. This huawei-wmi.c was built out of tree (W=1
and C=2 clean) and loaded in place of the in-tree module. The charger
was connected, the battery was at 83-84%, and the EC state was read
with raw HWMI calls:

  mode 1 or 2 with \GBTT 40/70             -> reads 40/70
  mode 0 or 4 with \GBTT 40/70             -> reads 0/100
  in-tree driver state (mode 1, 40/70 in
    \GBTT, 0/0 in \GBCM)                   -> reads 40/70
  mode 4, then write 75/80                 -> mode 1, discharging
  GNOME off (UPower)                       -> mode 1 0/0, charging
  GNOME on (UPower)                        -> mode 1 75/80, discharging

With the same write path in an earlier revision, I also tested writing
only the start or end attribute, 0/80, 40/100 (charging at 84%),
rejected invalid values, and a 4.5 minute s2idle with the limit kept.
In charge mode 1, a 1 hour lid-closed s2idle did not charge either.

The start threshold does not seem to be used by this EC: with 79/83, once
charging had stopped at 83%, unplugging until 82% and reconnecting the
charger made it charge back to 83% right away. This is not changed by
this patch. While connected, the EC holds the battery at the end
threshold ("Not charging", 0 A) or discharges it when it is above it.

Not tested: other models, and firmware without \GBCM. For the latter,
I only checked in this machine's AML that the HWMI dispatcher returns a
non-zero status for unknown functions. The acpi_has_method() checks
follow what the driver already does for \GFRS/\SFRS. The get-then-set
in the sysfs store callbacks predates this patch and is left alone.
Tested-by from other Huawei/Honor owners is welcome.

I found this because the battery kept charging to 100% with "Preserve
Battery Health" enabled. The ACPI/EC analysis, the test module used for
raw HWMI calls and this patch were done with an AI coding assistant
(Claude) under my direction, and tested on my machine. I reviewed the
change and can explain it.
---
 drivers/platform/x86/huawei-wmi.c | 94 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 94 insertions(+)

diff --git a/drivers/platform/x86/huawei-wmi.c b/drivers/platform/x86/huawei-wmi.c
index 96ee9a97c..917fb2fa8 100644
--- a/drivers/platform/x86/huawei-wmi.c
+++ b/drivers/platform/x86/huawei-wmi.c
@@ -36,6 +36,8 @@
 enum {
 	BATTERY_THRESH_GET		= 0x00001103, /* \GBTT */
 	BATTERY_THRESH_SET		= 0x00001003, /* \SBTT */
+	BATTERY_CHARGE_MODE_GET		= 0x00001603, /* \GBCM */
+	BATTERY_CHARGE_MODE_SET		= 0x00001503, /* \SBCM */
 	FN_LOCK_GET			= 0x00000604, /* \GFRS */
 	FN_LOCK_SET			= 0x00000704, /* \SFRS */
 	MICMUTE_LED_SET			= 0x00000b04, /* \SMLS */
@@ -61,6 +63,7 @@ struct huawei_wmi_debug {
 
 struct huawei_wmi {
 	bool battery_available;
+	bool charge_mode_available;
 	bool fn_lock_available;
 
 	struct huawei_wmi_debug debug;
@@ -324,11 +327,87 @@ static void huawei_wmi_leds_setup(struct device *dev)
 
 /* Battery protection */
 
+/*
+ * Newer firmware also implements \GBCM and \SBCM ("battery charge mode").
+ * \GBCM returns the charge mode in byte 1, a parameter of unknown meaning
+ * in byte 2 and a pair of thresholds in bytes 3 and 4, and \SBCM takes the
+ * same four values in bytes 2 to 5 of its argument. Thresholds set through
+ * \SBCM are also returned by \GBTT, but \SBTT does not update the ones
+ * returned by \GBCM.
+ *
+ * In charge modes 1 to 3 the EC does not charge above the end threshold
+ * returned by \GBTT, and a 0/0 pair means that charging is not limited.
+ * In charge modes 0 and 4 it charges past the end threshold. \SBTT,
+ * which turns a 0/100 request into 0/0, switches the EC to charge mode 4
+ * ("smart charge") in that case, and a later \SBTT write does not
+ * necessarily switch it back. So write the thresholds through \SBCM in
+ * charge mode 1 instead.
+ */
+#define HWMI_CHARGE_MODE_THRESHOLDS	1
+#define HWMI_CHARGE_MODE_PRESET_LAST	3
+
+static int huawei_wmi_charge_mode_get(u8 *mode, u8 *param)
+{
+	u8 ret[0x100] = {};
+	int err;
+
+	err = huawei_wmi_cmd(BATTERY_CHARGE_MODE_GET, ret, sizeof(ret));
+	if (err)
+		return err;
+
+	if (mode)
+		*mode = ret[1];
+	if (param)
+		*param = ret[2];
+
+	return 0;
+}
+
+static int huawei_wmi_charge_mode_set(int start, int end)
+{
+	union hwmi_arg arg;
+	u8 param;
+	int err;
+
+	err = huawei_wmi_charge_mode_get(NULL, &param);
+	if (err)
+		return err;
+
+	if (start == 0 && end == 100)
+		end = 0;
+
+	arg.cmd = BATTERY_CHARGE_MODE_SET;
+	arg.args[2] = HWMI_CHARGE_MODE_THRESHOLDS;
+	arg.args[3] = param;
+	arg.args[4] = start;
+	arg.args[5] = end;
+
+	return huawei_wmi_cmd(arg.cmd, NULL, 0);
+}
+
 static int huawei_wmi_battery_get(int *start, int *end)
 {
 	u8 ret[0x100];
 	int err, i;
 
+	if (huawei_wmi->charge_mode_available) {
+		u8 mode;
+
+		err = huawei_wmi_charge_mode_get(&mode, NULL);
+		if (err)
+			return err;
+
+		/* The thresholds are not used in the other charge modes. */
+		if (mode < HWMI_CHARGE_MODE_THRESHOLDS ||
+		    mode > HWMI_CHARGE_MODE_PRESET_LAST) {
+			if (start)
+				*start = 0;
+			if (end)
+				*end = 100;
+			return 0;
+		}
+	}
+
 	err = huawei_wmi_cmd(BATTERY_THRESH_GET, ret, sizeof(ret));
 	if (err)
 		return err;
@@ -342,6 +421,10 @@ static int huawei_wmi_battery_get(int *start, int *end)
 			*end = ret[i];
 	} while (i > 2 && !ret[i--]);
 
+	/* A 0/0 pair means that charging is not limited. */
+	if (huawei_wmi->charge_mode_available && end && !*end)
+		*end = 100;
+
 	return 0;
 }
 
@@ -353,6 +436,9 @@ static int huawei_wmi_battery_set(int start, int end)
 	if (start < 0 || end < 0 || start > 100 || end > 100)
 		return -EINVAL;
 
+	if (huawei_wmi->charge_mode_available)
+		return huawei_wmi_charge_mode_set(start, end);
+
 	arg.cmd = BATTERY_THRESH_SET;
 	arg.args[2] = start;
 	arg.args[3] = end;
@@ -507,6 +593,14 @@ static void huawei_wmi_battery_setup(struct device *dev)
 {
 	struct huawei_wmi *huawei = dev_get_drvdata(dev);
 
+	/*
+	 * Only trust the \GBCM status if the firmware actually implements the
+	 * methods, in case the HWMI dispatcher of some model reports success
+	 * for unknown functions.
+	 */
+	huawei->charge_mode_available = acpi_has_method(NULL, "\\GBCM") &&
+					acpi_has_method(NULL, "\\SBCM") &&
+					!huawei_wmi_charge_mode_get(NULL, NULL);
 	huawei->battery_available = true;
 	if (huawei_wmi_battery_get(NULL, NULL)) {
 		huawei->battery_available = false;

---
base-commit: a514d723595bd8e5ce926a7fea148ceb3c26915c
change-id: 20261112-huawei-wmi-charge-mode-7f4fc964130d

Best regards,
-- 
Eren Özen <erenozen@protonmail.com>

