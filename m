From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 03 Oct 2026 05:44:03 +0200
Subject: [PATCH] cmd: button: add live monitor subcommand
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-b4-button-live-monitor-v1-1-6a2934e71fbd@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDsQg0TxKuKiE6d1RJOSHxHEu
 ze1y2/x3gmRg3CEvjoh8C5RvCuoHxXY+enejDIVg1ba1EpppAYpp+QdrrIzbt5J8gG7lnQ7daa
 xZKDEn8AvOe7xMP4dMy1s0+8G1/UFKeA08noAAAA=
X-Change-ID: 20261002-b4-button-live-monitor-87b27d864cb6
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790999049; l=3218;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=W5lumvEdK05TMwElbKPNBeEZv+2cTckmdk6q6jk7ySM=;
 b=R88UJhta9UgsW6RCKbh6SZTYvMM4+o7UOpgUc2+ly9gAXEdC4g6+oudVNeddAldVVt5Hujfd4
 TeXtbAblrbPBCBmZKXynhNv3hSVEKA2uus4Gpj6BoCpKA7q8BMstntr
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`button list` prints state once and exits. The new subcommand `monitor`
loops the input states with default timeout 5s so live verification
on the device is easier.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
`button list` only prints state once and exits so verifying a
button mapping on a mobile device is not practical. Therefore 
the new subcommand loops the input states and prints it live.
---
 cmd/button.c | 59 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 57 insertions(+), 2 deletions(-)

diff --git a/cmd/button.c b/cmd/button.c
index 3e6db3f5b8e..daab7b6fb6c 100644
--- a/cmd/button.c
+++ b/cmd/button.c
@@ -8,7 +8,11 @@
 #include <command.h>
 #include <dm.h>
 #include <button.h>
+#include <stdio.h>
+#include <time.h>
+#include <vsprintf.h>
 #include <dm/uclass-internal.h>
+#include <linux/delay.h>
 
 static const char *const state_label[] = {
 	[BUTTON_OFF]	= "off",
@@ -53,6 +57,48 @@ static int list_buttons(void)
 	return 0;
 }
 
+static int monitor_buttons(unsigned long timeout_ms)
+{
+	ulong start = get_timer(0);
+	ulong elapsed;
+
+	/* Clear screen and move cursor to row 1, column 1 */
+	puts("\x1b[2J\x1b[H");
+	puts("Button monitor\r\n\r\n");
+
+	for (;;) {
+		struct udevice *dev;
+
+		elapsed = get_timer(start);
+		if (elapsed >= timeout_ms)
+			break;
+
+		puts("\x1b[3;1H");
+		printf("%lu.%lus left\x1b[K\r\n",
+		       (timeout_ms - elapsed) / 1000,
+		       ((timeout_ms - elapsed) % 1000) / 100);
+		puts("--------------------\r\n");
+
+		for (uclass_first_device(UCLASS_BUTTON, &dev);
+		     dev;
+		     uclass_next_device(&dev)) {
+			struct button_uc_plat *plat = dev_get_uclass_plat(dev);
+			int state;
+
+			if (!plat->label)
+				continue;
+			state = button_get_state(dev);
+
+			printf("%-15s %-3s\x1b[K\r\n", plat->label,
+			       (state == BUTTON_ON) ? "ON" : "off");
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
@@ -65,6 +111,13 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 	button_label = argv[1];
 	if (strncmp(button_label, "list", 4) == 0)
 		return list_buttons();
+	if (strncmp(button_label, "monitor", 7) == 0) {
+		unsigned long timeout_ms = 5000;
+
+		if (argc >= 3)
+			timeout_ms = dectoul(argv[2], NULL);
+		return monitor_buttons(timeout_ms);
+	}
 
 	ret = button_get_by_label(button_label, &dev);
 	if (ret) {
@@ -78,8 +131,10 @@ int do_button(struct cmd_tbl *cmdtp, int flag, int argc, char *const argv[])
 }
 
 U_BOOT_CMD(
-	button, 2, 1, do_button,
+	button, 3, 1, do_button,
 	"manage buttons",
 	"<button_label> \tGet button state\n"
-	"button list\t\tShow a list of buttons"
+	"button list\t\tShow a list of buttons\n"
+	"button monitor [timeout_ms]\tLive table, updates every 100ms,\n"
+	"                             \tquits on timeout (default 5000ms)"
 );

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-button-live-monitor-87b27d864cb6

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

