From: Petr Hodina <petr.hodina@protonmail.com>
Date: Tue, 13 Oct 2026 18:33:32 +0200
Subject: [PATCH v3 2/4] cmd: button: add live monitor subcommand
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-b4-button-live-monitor-v3-2-3563b4d3ccdf@protonmail.com>
References: <20261013-b4-button-live-monitor-v3-0-3563b4d3ccdf@protonmail.com>
In-Reply-To: <20261013-b4-button-live-monitor-v3-0-3563b4d3ccdf@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791909215; l=3523;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ITLNbOdpfrKUeEi04PmS+kZBupXlmPeNqsjTfbVW/ZI=;
 b=VqgMZhq5QYQh05BTRoqZ8ZnZwxnsjhpoVY6O/vhDeU8al2qu2pcJltuaz/d9pMZ8WhoThLfM0
 gCk6v+9AZarAAEUdFxWVUTTNuLL5Q668UssTXo/9oX9E3cAqBJCw8X+
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a 'monitor' subcommand which redraws the state of all buttons
every 100ms until Ctrl-C is pressed or a timeout expires (default 5s,
0 for none). This allows the buttons to be checked live on a device.

It reuses show_button_status() so both subcommands produce the same
output.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/button.c | 78 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 76 insertions(+), 2 deletions(-)

diff --git a/cmd/button.c b/cmd/button.c
index da1bf1f6e3b..268f5a64952 100644
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
@@ -65,6 +71,60 @@ static int list_buttons(void)
 	return 0;
 }
 
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
+		}
+
+		mdelay(100);
+	}
+
+	return 0;
+}
+
 int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 {
 	const char *button_label;
@@ -77,6 +137,17 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
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
@@ -90,8 +161,11 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
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

