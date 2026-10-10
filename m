From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:53 +0200
Subject: [PATCH 05/11] cmd: phonemenu: show active A/B slot in the header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-5-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=3838;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ffiAIQgf+1ESPQh1EhoikIjDmBW6G4txlkiotAmYsPQ=;
 b=UuFGBJ1m73byWwiVymNi8i2dqsjPMkHoZyOg/AO70SSVDTUC7SQPlJ97/0YH3Ag38n/P1e9/i
 WUFGWbmm9h/AUl/9YGjbxAN2rIAjOXk4bSTv0wFHtMPFwuIv4QIuM44
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Show the active A/B slot in the boot menu header, read via
ab_select_slot() without decrementing tries.

Pick the block device from the "storage" env var.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS         |  1 +
 cmd/phonemenu.c     | 57 ++++++++++++++++++++++++++++++++++++++++++++++++++---
 include/phonemenu.h | 14 +++++++++++++
 3 files changed, 69 insertions(+), 3 deletions(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 696abefa1e6..8734a683221 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -689,6 +689,7 @@ S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
 F:	cmd/phone_util.c
 F:	cmd/phonemenu.c
+F:	include/phonemenu.h
 F:	configs/qcm6490_defconfig
 F:	configs/qcs9100_defconfig
 F:	drivers/*/*/pm8???-*
diff --git a/cmd/phonemenu.c b/cmd/phonemenu.c
index e83394714c3..7478661d049 100644
--- a/cmd/phonemenu.c
+++ b/cmd/phonemenu.c
@@ -1,6 +1,8 @@
 // SPDX-License-Identifier: GPL-2.0+
 
+#include <android_ab.h>
 #include <ansi.h>
+#include <blk.h>
 #include <cli.h>
 #include <command.h>
 #include <dm.h>
@@ -10,11 +12,14 @@
 #include <log.h>
 #include <malloc.h>
 #include <menu.h>
+#include <part.h>
 #include <stdio.h>
 #include <stdio_dev.h>
 #include <video.h>
 #include <video_console.h>
 #include <version.h>
+#include <phonemenu.h>
+#include <linux/errno.h>
 #include <linux/string.h>
 
 /* Layout (pixels) */
@@ -427,21 +432,67 @@ static const char *pm_codename(void)
 	return buf;
 }
 
+/*
+ * Block device the real storage chosen by the "storage" env
+ */
+struct blk_desc *phonemenu_storage_desc(void)
+{
+	const char *storage = env_get("storage");
+
+	return blk_get_devnum_by_uclass_id(storage && !strcmp(storage, "mmc") ?
+					   UCLASS_MMC : UCLASS_SCSI, 0);
+}
+
+/*
+ * Active A/B slot via ab_select_slot(), read-only
+ */
+__weak int phonemenu_ab_slot(void)
+{
+	struct blk_desc *desc = phonemenu_storage_desc();
+	struct disk_partition misc = { 0 };
+
+	if (!desc || part_get_info_by_name(desc, "misc", &misc) < 0)
+		return -ENODEV;
+
+	return ab_select_slot(desc, &misc, false);
+}
+
+static const char *pm_slot(void)
+{
+	int slot;
+
+	if (!IS_ENABLED(CONFIG_ANDROID_AB))
+		return NULL;
+
+	slot = phonemenu_ab_slot();
+	if (slot < 0)
+		return NULL;
+
+	return slot == 0 ? "_a" : "_b";
+}
+
 static int do_phonemenu(struct cmd_tbl *cmdtp, int flag, int argc,
 			char *const argv[])
 {
+	static char slot_line[96];
+	const char *slot = pm_slot();
 	const char *sub = (argc > 1) ? argv[1] : "main";
+	int n = 0;
+
+	if (slot)
+		n += snprintf(slot_line + n, sizeof(slot_line) - n,
+			      "slot %s", slot);
 
 	if (!strcmp(sub, "advanced"))
 		return pm_run(pm_advanced, ARRAY_SIZE(pm_advanced),
-			      "Advanced menu", NULL, U_BOOT_VERSION);
+			      "Advanced menu", slot_line, U_BOOT_VERSION);
 
 	if (!strcmp(sub, "diag"))
 		return pm_run(pm_diag, ARRAY_SIZE(pm_diag),
-			      "Diagnostics", NULL, U_BOOT_VERSION);
+			      "Diagnostics", slot_line, U_BOOT_VERSION);
 
 	return pm_run(pm_main, ARRAY_SIZE(pm_main),
-		      pm_codename(), NULL, U_BOOT_VERSION);
+		      pm_codename(), slot_line, U_BOOT_VERSION);
 }
 
 U_BOOT_CMD(phonemenu, 2, 0, do_phonemenu,
diff --git a/include/phonemenu.h b/include/phonemenu.h
new file mode 100644
index 00000000000..5d6ded84197
--- /dev/null
+++ b/include/phonemenu.h
@@ -0,0 +1,14 @@
+/* SPDX-License-Identifier: GPL-2.0+ */
+
+#ifndef _PHONEMENU_H
+#define _PHONEMENU_H
+
+struct blk_desc;
+
+/* Block device of the real storage, selected by the "storage" env var */
+struct blk_desc *phonemenu_storage_desc(void);
+
+/* Active A/B slot (0 = a, 1 = b) or a negative errno */
+int phonemenu_ab_slot(void);
+
+#endif

-- 
2.55.0

