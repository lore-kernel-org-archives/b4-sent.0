From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 14:27:52 +0200
Subject: [PATCH v2 1/3] cmd: button: add live monitor subcommand
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-button-live-monitor-v2-1-004f47a4a7b1@protonmail.com>
References: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
In-Reply-To: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791635298; l=4119;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=1aa5H9bzC+wAoQQVdtNv1o0xYF8isu0OAxDh+fGQfjc=;
 b=egxcIcmenVmFPC+DfnZVNFuLJuha2QZZUorI98qQerYLhMc1d2uW4Eay8Fljytvxb3YV83JcE
 yeyb8NBNzhmC6mkXJkSIf08RdNg7hJ2fL6oXs0InICSGkGQ/iPsd4hK
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'button list' prints state once and exits. The new subcommand 'monitor'
loops the input states with default timeout 5s so live verification
on the device is easier.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/button.c | 104 +++++++++++++++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 95 insertions(+), 9 deletions(-)

diff --git a/cmd/button.c b/cmd/button.c
index 3e6db3f5b8e..268f5a64952 100644
--- a/cmd/button.c
+++ b/cmd/button.c
@@ -7,8 +7,14 @@
 
 #include <command.h>
 #include <dm.h>
+#include <ansi.h>
 #include <button.h>
+#include <console.h>
+#include <stdio.h>
+#include <time.h>
+#include <vsprintf.h>
 #include <dm/uclass-internal.h>
+#include <linux/delay.h>
 
 static const char *const state_label[] = {
 	[BUTTON_OFF]	= "off",
@@ -28,10 +34,27 @@ static int show_button_state(struct udevice *dev)
 	return ret;
 }
 
+static void show_button_status(struct udevice *dev)
+{
+	int ret;
+
+	if (!device_active(dev)) {
+		puts("<inactive>");
+		return;
+	}
+
+	ret = button_get_state(dev);
+	if (ret >= BUTTON_COUNT)
+		ret = -EINVAL;
+	if (ret >= 0)
+		puts(state_label[ret]);
+	else
+		printf("Error %d", ret);
+}
+
 static int list_buttons(void)
 {
 	struct udevice *dev;
-	int ret;
 
 	for (uclass_find_first_device(UCLASS_BUTTON, &dev);
 	     dev;
@@ -41,13 +64,62 @@ static int list_buttons(void)
 		if (!plat->label)
 			continue;
 		printf("%-15s ", plat->label);
-		if (device_active(dev)) {
-			ret = show_button_state(dev);
-			if (ret < 0)
-				printf("Error %d\n", ret);
-		} else {
-			printf("<inactive>\n");
+		show_button_status(dev);
+		puts("\n");
+	}
+
+	return 0;
+}
+
+static int monitor_buttons(unsigned long timeout_ms)
+{
+	ulong start = get_timer(0);
+	ulong elapsed;
+	int ret;
+
+	/* Probe once; buttons which fail to probe are shown as <inactive> */
+	ret = uclass_probe_all(UCLASS_BUTTON);
+
+	puts(ANSI_CLEAR_CONSOLE);
+	printf(ANSI_CURSOR_POSITION, 1, 1);
+	puts("Button monitor\n");
+	if (ret)
+		printf("Some buttons failed to probe (err=%d)", ret);
+	puts("\n");
+
+	for (;;) {
+		struct udevice *dev;
+
+		if (ctrlc())
+			break;
+
+		elapsed = get_timer(start);
+		if (timeout_ms && elapsed >= timeout_ms)
+			break;
+
+		printf(ANSI_CURSOR_POSITION, 3, 1);
+		if (timeout_ms)
+			printf("%lu.%lus left, Ctrl-C to quit"
+			       ANSI_CLEAR_LINE_TO_END "\n",
+			       (timeout_ms - elapsed) / 1000,
+			       ((timeout_ms - elapsed) % 1000) / 100);
+		else
+			puts("Ctrl-C to quit" ANSI_CLEAR_LINE_TO_END "\n");
+		puts("--------------------\n");
+
+		for (uclass_find_first_device(UCLASS_BUTTON, &dev);
+		     dev;
+		     uclass_find_next_device(&dev)) {
+			struct button_uc_plat *plat = dev_get_uclass_plat(dev);
+
+			if (!plat->label)
+				continue;
+			printf("%-15s ", plat->label);
+			show_button_status(dev);
+			puts(ANSI_CLEAR_LINE_TO_END "\n");
 		}
+
+		mdelay(100);
 	}
 
 	return 0;
@@ -65,6 +137,17 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 	button_label = argv[1];
 	if (strncmp(button_label, "list", 4) == 0)
 		return list_buttons();
+	if (strcmp(button_label, "monitor") == 0) {
+		unsigned long timeout_ms = 5000;
+		char *endp;
+
+		if (argc >= 3) {
+			timeout_ms = dectoul(argv[2], &endp);
+			if (endp == argv[2] || *endp)
+				return CMD_RET_USAGE;
+		}
+		return monitor_buttons(timeout_ms);
+	}
 
 	ret = button_get_by_label(button_label, &dev);
 	if (ret) {
@@ -78,8 +161,11 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 }
 
 U_BOOT_CMD(
-	button, 2, 1, do_button,
+	button, 3, 1, do_button,
 	"manage buttons",
 	"<button_label> \tGet button state\n"
-	"button list\t\tShow a list of buttons"
+	"button list\t\tShow a list of buttons\n"
+	"button monitor [timeout_ms]\tLive table, updates every 100ms,\n"
+	"                             \tquits on timeout (default 5000ms,\n"
+	"                             \t0 = until Ctrl-C) or Ctrl-C"
 );

-- 
2.55.0

