From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:55 +0200
Subject: [PATCH 07/11] cmd: phonemenu: show Android boot reason in the
 header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-7-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=2309;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=3uGxjR5xccjqyRoM2E5zcEMqUdby+oWh6OvZX/sGuOU=;
 b=KZxKVZtByrpT25GLtvj/VU0dl9MUOwaFjsd0DRQ0Uy/h71x0+v9wKPP5e77XqfJNX+rAEw2dE
 QuiBeLl672NDLXZlYYaV3XAmdwHMBFcyi7Daquwj39CZf+ncycfFhBz
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Show in the boot menu header the boot reason read from the Android
Bootloader Control Block. Each field on the header line is
independently optional (NULL on error/absent hardware) and simply
skipped.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/phonemenu.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/cmd/phonemenu.c b/cmd/phonemenu.c
index 7478661d049..8f29d8d704b 100644
--- a/cmd/phonemenu.c
+++ b/cmd/phonemenu.c
@@ -2,6 +2,7 @@
 
 #include <android_ab.h>
 #include <ansi.h>
+#include <bcb.h>
 #include <blk.h>
 #include <cli.h>
 #include <command.h>
@@ -471,17 +472,53 @@ static const char *pm_slot(void)
 	return slot == 0 ? "_a" : "_b";
 }
 
+/*
+ * Boot reason from the Android Bootloader Control Block on the "storage"
+ * device's misc partition. Maps the raw "command" field to short labels:
+ *   ""                     -> "normal"
+ *   "boot-recovery"        -> "recovery"
+ *   "bootonce-bootloader"  -> "fastboot"
+ *   "boot-fastboot"        -> "fastbootd"
+ *   anything else          -> the raw command
+ */
+static const char *pm_reason(void)
+{
+	static char buf[32];
+	char cmd[32];
+
+	if (bcb_find_partition_and_load(env_get("storage") ?: "scsi", 0, "misc"))
+		return "normal";
+	if (bcb_get(BCB_FIELD_COMMAND, cmd, sizeof(cmd)))
+		return "normal";
+
+	if (!cmd[0])
+		return "normal";
+	if (!strncmp(cmd, "boot-recovery", sizeof(cmd)))
+		return "recovery";
+	if (!strncmp(cmd, "bootonce-bootloader", sizeof(cmd)))
+		return "fastboot";
+	if (!strncmp(cmd, "boot-fastboot", sizeof(cmd)))
+		return "fastbootd";
+
+	strlcpy(buf, cmd, sizeof(buf));
+	return buf;
+}
+
 static int do_phonemenu(struct cmd_tbl *cmdtp, int flag, int argc,
 			char *const argv[])
 {
 	static char slot_line[96];
 	const char *slot = pm_slot();
+	const char *reason = pm_reason();
 	const char *sub = (argc > 1) ? argv[1] : "main";
 	int n = 0;
 
 	if (slot)
 		n += snprintf(slot_line + n, sizeof(slot_line) - n,
 			      "slot %s", slot);
+	if (reason)
+		n += snprintf(slot_line + n, sizeof(slot_line) - n,
+			      "%s%s", n ? "  -  " : "", reason);
 
 	if (!strcmp(sub, "advanced"))
 		return pm_run(pm_advanced, ARRAY_SIZE(pm_advanced),

-- 
2.55.0

