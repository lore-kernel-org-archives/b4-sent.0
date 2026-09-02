From: George Kokolakis <george.kokolakis.ece@gmail.com>
Date: Wed, 02 Sep 2026 20:14:01 +0300
Subject: [PATCH RFC v2] ACPI: PM: Use EFI power off on Lenovo ThinkPad T14
 Gen 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-fix-thinkpad-t14-gen5-efi-poweroff-v2-1-c7bb29c91832@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFhZmGoC/5WNTQqDMBBGryKz7hTjv10VCj1At8VFSCY6tCaSi
 LWId2/wBl2+78H3NgjkmQJckg08LRzY2QjZKQE1SNsTso4MWZpVaZsKNLziPLB9TVLjLArsyZZ
 IhnFyH/LOGGzqRuaq0LKUJcSjyUe9HpEnPO436OI4cJid/x7hRRzqn8YiUGBt6qrSSuRE7bUfJ
 b/Pyo3Q7fv+A+IotRzZAAAA
To: rafael@kernel.org
Cc: lenb@kernel.org, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 George Kokolakis <george.kokolakis.ece@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788369240; l=4295;
 i=george.kokolakis.ece@gmail.com; s=kernel-20260901;
 h=from:subject:message-id; bh=SNEEUPIgMfmYyvsyn9AZanB8keYappwqTWEzg+lMawE=;
 b=2DkAo9p8UxluXuemZ8Anbc+0+NDw1b/m5Eay1BxZ33k/2HrEVmCbXpdDWWiFM2ItLx+nUDmg2
 MM1sxzFMD7UDtx9WjRHr6UnnVKcxRO+PNPoo+vAdIosfKBZHUyNM4xY
X-Developer-Key: i=george.kokolakis.ece@gmail.com; a=ed25519;
 pk=vZ27t8agUnF5GcuvLoIUzClMG59D0bvQE7GXXdwXJ9I=
X-Endpoint-Received: by B4 Relay for george.kokolakis.ece@gmail.com/kernel-20260901 with auth_id=995
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Lenovo ThinkPad T14 Gen 5 (type 21ML) powers back on immediately
after an orderly ACPI S5 shutdown. This was reproduced with BIOS
N47ET29W 1.18 and Ubuntu kernel 7.0.0-30-generic.

A standalone UEFI application invoking ResetSystem(EfiResetShutdown)
left the same machine powered off, and an out-of-tree DMI-scoped
module implementing this same approach also succeeded on its first
real shutdown test.

Update: on subsequent independent shutdown attempts with the same
out-of-tree module active, the machine intermittently powered back
on again despite the EFI power-off handler running. Disabling the
Intel Wi-Fi ACPI wake source (CNVW) for one boot did not change the
outcome, ruling that out as the variable. The underlying trigger is
not yet identified and may be a firmware/EC race rather than a fixed
choice between ACPI S5 and EFI ResetSystem.

Sending as RFC: the EFI path is a real improvement in most observed
cases, but is not yet confirmed reliable enough for stable/mainline
inclusion. Posting the updated data so review isn't based on the
single-success report in v1, and to ask whether EC-side conditions
(e.g. AC/dock/Thunderbolt wake arming) are known to affect this on
other Meteor Lake ThinkPads.

Link: https://bugs.launchpad.net/bugs/2162837
Cc: stable@vger.kernel.org
Signed-off-by: George Kokolakis <george.kokolakis.ece@gmail.com>
---
Changes in v2:
- Additional real-world shutdown attempts on the same hardware showed
  the EFI power-off path does not reliably prevent the reboot-on-
  poweroff behavior: it succeeded on the first two independent tests
  but failed on two subsequent ones with the same handlers active.
- Disabling the Intel Wi-Fi ACPI wake source (CNVW) for one boot did
  not change the outcome, ruling it out as the variable.
- Re-posting as RFC with this data rather than letting v1's single
  success stand unqualified; asking whether EC-side conditions (AC/
  dock/Thunderbolt wake arming) are known to matter here.
- Link to v1: https://lore.kernel.org/r/20260901-fix-thinkpad-t14-gen5-efi-poweroff-v1-1-7f766dc13ee9@gmail.com
---
 drivers/acpi/sleep.c | 30 +++++++++++++++++++++++-------
 1 file changed, 23 insertions(+), 7 deletions(-)

diff --git a/drivers/acpi/sleep.c b/drivers/acpi/sleep.c
index 132a9df984..d14833eb59 100644
--- a/drivers/acpi/sleep.c
+++ b/drivers/acpi/sleep.c
@@ -27,7 +27,7 @@
 #include "sleep.h"
 
 /*
- * Some HW-full platforms do not have _S5, so they may need
+ * Some HW-full platforms do not have a usable _S5, so they may need
  * to leverage efi power off for a shutdown.
  */
 bool acpi_no_s5;
@@ -173,6 +173,12 @@ static int __init init_default_s3(const struct dmi_system_id *d)
 	return 0;
 }
 
+static int __init init_no_s5(const struct dmi_system_id *d)
+{
+	acpi_no_s5 = true;
+	return 0;
+}
+
 static const struct dmi_system_id acpisleep_dmi_table[] __initconst = {
 	{
 	.callback = init_old_suspend_ordering,
@@ -407,6 +413,14 @@ static const struct dmi_system_id acpisleep_dmi_table[] __initconst = {
 		DMI_MATCH(DMI_PRODUCT_NAME, "20GGA00L00"),
 		},
 	},
+	{
+	.callback = init_no_s5,
+	.ident = "Lenovo ThinkPad T14 Gen 5 (21ML)",
+	.matches = {
+		DMI_MATCH(DMI_SYS_VENDOR, "LENOVO"),
+		DMI_MATCH(DMI_PRODUCT_NAME, "21ML"),
+		},
+	},
 	{},
 };
 
@@ -1117,13 +1131,15 @@ int __init acpi_sleep_init(void)
 	if (acpi_sleep_state_supported(ACPI_STATE_S5)) {
 		sleep_states[ACPI_STATE_S5] = 1;
 
-		register_sys_off_handler(SYS_OFF_MODE_POWER_OFF_PREPARE,
-					 SYS_OFF_PRIO_FIRMWARE,
-					 acpi_power_off_prepare, NULL);
+		if (!acpi_no_s5) {
+			register_sys_off_handler(SYS_OFF_MODE_POWER_OFF_PREPARE,
+						 SYS_OFF_PRIO_FIRMWARE,
+						 acpi_power_off_prepare, NULL);
 
-		register_sys_off_handler(SYS_OFF_MODE_POWER_OFF,
-					 SYS_OFF_PRIO_FIRMWARE,
-					 acpi_power_off, NULL);
+			register_sys_off_handler(SYS_OFF_MODE_POWER_OFF,
+						 SYS_OFF_PRIO_FIRMWARE,
+						 acpi_power_off, NULL);
+		}
 
 		/*
 		 * Windows uses S5 for reboot, so some BIOSes depend on it to

---
base-commit: 786262be6048deab760f68c8acc2c85607165894
change-id: 20260901-fix-thinkpad-t14-gen5-efi-poweroff-878a3c4da5a5

Best regards,
-- 
George Kokolakis <george.kokolakis.ece@gmail.com>

