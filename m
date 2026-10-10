From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:51 +0200
Subject: [PATCH 03/11] cmd: phonemenu: mirror the menu to byte-stream
 consoles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-3-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=4352;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=/mKdxYAuxwGadyLKCtPHJTCiuo/hLdKQi7LAU63mz2Y=;
 b=VbnozkMPmOu9ywmvEnEyFZZmSrveQ/JXB4SlrdHd+unag4NBI9CzpFgfy/AiIz8kb4kZRuQpz
 m6kjOaBZMIXBi1mWaw5Tn/F/eOPMV6l4aCGnQ7TSB19aiMB/8kpwfEN
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The pixel-drawn menu is rendered to serial or USB CDC-ACM.
Add pm_term_puts()/pm_term_render() to render the same menu as ANSI
escapes over those byte-stream consoles.

Wire it into pm_render_all() for initial draw and the up/down navigation
in pm_run().

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 cmd/phonemenu.c | 80 +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 80 insertions(+)

diff --git a/cmd/phonemenu.c b/cmd/phonemenu.c
index 30f994bcb64..e83394714c3 100644
--- a/cmd/phonemenu.c
+++ b/cmd/phonemenu.c
@@ -1,5 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0+
 
+#include <ansi.h>
 #include <cli.h>
 #include <command.h>
 #include <dm.h>
@@ -9,6 +10,8 @@
 #include <log.h>
 #include <malloc.h>
 #include <menu.h>
+#include <stdio.h>
+#include <stdio_dev.h>
 #include <video.h>
 #include <video_console.h>
 #include <version.h>
@@ -234,6 +237,76 @@ static void pm_draw_frame(struct pm_state *s)
 		COL_FOOTER, COL_BG, foot);
 }
 
+/* ANSI escape sequences and line ending used on the byte-stream consoles */
+#define PM_TERM_EOL		"\r\n"
+#define PM_TERM_CLEAR		ANSI_CLEAR_CONSOLE "\e[H"
+#define PM_TERM_CURSOR_HIDE	ANSI_CURSOR_HIDE
+#define PM_TERM_CURSOR_SHOW	ANSI_CURSOR_SHOW
+#define PM_TERM_REVERSE		ANSI_COLOR_REVERSE
+#define PM_TERM_RESET		ANSI_COLOR_RESET
+
+/* Mirror the menu to byte-stream consoles (serial UART, USB CDC ACM) */
+static void pm_term_puts(const char *str)
+{
+	static const char * const names[] = { "serial", "usbacm" };
+	struct stdio_dev *d;
+	size_t i;
+
+	for (i = 0; i < ARRAY_SIZE(names); i++) {
+		d = stdio_get_by_name(names[i]);
+		if (!d || !d->puts)
+			continue;
+
+		if (!strcmp(names[i], "usbacm") && !d->priv)
+			continue;
+
+		d->puts(d, str);
+	}
+}
+
+static void pm_term_render(struct pm_state *s)
+{
+	enum pm_section prev = PM_SEC_COUNT;
+	char buf[160];
+	int i;
+
+	/* Clear screen, cursor home, hide cursor while we paint. */
+	pm_term_puts(PM_TERM_CLEAR PM_TERM_CURSOR_HIDE);
+
+	snprintf(buf, sizeof(buf), "  %s" PM_TERM_EOL, s->title);
+	pm_term_puts(buf);
+	if (s->subtitle && *s->subtitle) {
+		snprintf(buf, sizeof(buf), "  %s" PM_TERM_EOL, s->subtitle);
+		pm_term_puts(buf);
+	}
+	if (s->version && *s->version) {
+		snprintf(buf, sizeof(buf), "  %s" PM_TERM_EOL, s->version);
+		pm_term_puts(buf);
+	}
+	pm_term_puts(PM_TERM_EOL);
+
+	for (i = 0; i < s->count; i++) {
+		if (s->items[i].section != prev) {
+			snprintf(buf, sizeof(buf), "  [%s]" PM_TERM_EOL,
+				 pm_section_label[s->items[i].section]);
+			pm_term_puts(buf);
+			prev = s->items[i].section;
+		}
+		if (i == s->active)
+			snprintf(buf, sizeof(buf),
+				 "    " PM_TERM_REVERSE "> %s" PM_TERM_RESET PM_TERM_EOL,
+				 s->items[i].label);
+		else
+			snprintf(buf, sizeof(buf), "      %s" PM_TERM_EOL,
+				 s->items[i].label);
+		pm_term_puts(buf);
+	}
+
+	pm_term_puts(PM_TERM_EOL
+		     "  Vol up/down or arrows to move    Power or Enter to select"
+		     PM_TERM_EOL);
+}
+
 static void pm_render_all(struct pm_state *s)
 {
 	int i;
@@ -242,6 +315,8 @@ static void pm_render_all(struct pm_state *s)
 	for (i = 0; i < s->count; i++)
 		pm_draw_item(s, i, i == s->active);
 	video_sync(s->vid, true);
+
+	pm_term_render(s);
 }
 
 static int pm_run(const struct pm_item *items, int count,
@@ -290,6 +365,7 @@ static int pm_run(const struct pm_item *items, int count,
 			pm_draw_item(&s, s.last_active, false);
 			pm_draw_item(&s, s.active, true);
 			video_sync(s.vid, true);
+			pm_term_render(&s);
 			break;
 		case BKEY_DOWN:
 			/* Wrap from the last item back to item 0. */
@@ -298,6 +374,7 @@ static int pm_run(const struct pm_item *items, int count,
 			pm_draw_item(&s, s.last_active, false);
 			pm_draw_item(&s, s.active, true);
 			video_sync(s.vid, true);
+			pm_term_render(&s);
 			break;
 		case BKEY_SELECT:
 			running = false;
@@ -318,6 +395,9 @@ static int pm_run(const struct pm_item *items, int count,
 	s.vp->colour_bg = COL_BG;
 	video_sync(s.vid, true);
 
+	/* Reset the terminal: clear screen, show cursor, reset colours. */
+	pm_term_puts(PM_TERM_CLEAR PM_TERM_CURSOR_SHOW PM_TERM_RESET);
+
 	cmd = items[s.active].command;
 	if (cmd && cmd[0])
 		run_command((char *)cmd, 0);

-- 
2.55.0

