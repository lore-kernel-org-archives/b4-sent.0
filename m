From: George Kokolakis <george.kokolakis.ece@gmail.com>
Date: Tue, 01 Sep 2026 21:24:14 +0300
Subject: [PATCH] ACPI: PM: Use EFI power off on Lenovo ThinkPad T14 Gen 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260901-fix-thinkpad-t14-gen5-efi-poweroff-v1-1-7f766dc13ee9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAE0Yl2oC/x2NywqEMAwAf0VyNtC61tevLHsINtUgtKUVVxD/3
 eJxGJi5IHMSzjBVFyQ+JEvwBXRdwbySXxjFFoZGNZ0alUYnJ+6r+C2SxV23uLA3yE4whj+n4Bw
 O/UCfubVkyEAJxVT0+U6+v/t+AEHMSI90AAAA
To: rafael@kernel.org
Cc: lenb@kernel.org, linux-acpi@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788287057; l=3071;
 i=george.kokolakis.ece@gmail.com; s=kernel-20260901;
 h=from:subject:message-id; bh=eB+R26itJ2JkTVFa+VyNE4Mw+wr0JpISWwRbkykFcQw=;
 b=aSci7cGWGfRq3MarVunw1Msq3HGDWZbbRiXQRA3urKl1v3DbiAHzC4FBhgvUbWczAKlBytAdU
 Lz8Shk+Jny/Ax6FZsxQ/UjkLuAKUTR/95kAdax752IRfkyvJn34lvEc
X-Developer-Key: i=george.kokolakis.ece@gmail.com; a=ed25519;
 pk=vZ27t8agUnF5GcuvLoIUzClMG59D0bvQE7GXXdwXJ9I=
X-Endpoint-Received: by B4 Relay for george.kokolakis.ece@gmail.com/kernel-20260901 with auth_id=995
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Lenovo ThinkPad T14 Gen 5 (type 21ML) powers back on immediately
after an orderly ACPI S5 shutdown.  This was reproduced with BIOS
N47ET29W 1.18 and Ubuntu kernel 7.0.0-30-generic.

A standalone UEFI application invoking ResetSystem(EfiResetShutdown)
leaves the same machine powered off.  A DMI-scoped test module that
skips the ACPI S5 power-off preparation handler and invokes ResetSystem
at the final sys-off stage also leaves it off during an ordinary
userspace shutdown.

Mark ACPI S5 unusable for power-off on this model.  This makes the
existing x86 EFI code register its higher-priority EFI shutdown handler.
Do not register the two ACPI power-off handlers when the quirk is active,
but retain ACPI S5 preparation for restart.

Link: https://bugs.launchpad.net/bugs/2162837
Cc: stable@vger.kernel.org
Signed-off-by: George Kokolakis <george.kokolakis.ece@gmail.com>
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

