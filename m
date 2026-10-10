From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:50 +0200
Subject: [PATCH 02/11] cmd: phonemenu: pixel drawn boot menu rendering and
 navigation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-2-bfa23de6eb0b@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=11954;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=iuyoL/O88lzQSL/rNAjnm4b4OlkPYw4eSwCICZOE1qI=;
 b=EblZzkrcPb2I2o8swx7knfwVBWjqIXomcTA0JbmuvLdvMfyNFymkhsGb54yEiX1SkNWqoKe3I
 xzsTN4bkNJeCN4bgV8Gr6E0NewXsdG0NMWrJeOvJwpOypss4jfIVpE6
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the core sectioned boot menu engine:

- the menu data tables
- the pixel layout/drawing primitives (video uclass fills + vidconsole
  bitmap text)
- the navigation loop built on bootmenu_loop() so volume up/down/power
  work via BUTTON_REMAP_PHONE_KEYS

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS     |   1 +
 cmd/Makefile    |   2 +-
 cmd/phonemenu.c | 372 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 374 insertions(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 4b0b0b2f3a5..696abefa1e6 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -688,6 +688,7 @@ L:	u-boot-qcom@groups.io
 S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
 F:	cmd/phone_util.c
+F:	cmd/phonemenu.c
 F:	configs/qcm6490_defconfig
 F:	configs/qcs9100_defconfig
 F:	drivers/*/*/pm8???-*
diff --git a/cmd/Makefile b/cmd/Makefile
index 762572156cd..913d94abdb2 100644
--- a/cmd/Makefile
+++ b/cmd/Makefile
@@ -36,7 +36,7 @@ obj-$(CONFIG_CMD_BMP) += bmp.o
 obj-$(CONFIG_CMD_BOOTCOUNT) += bootcount.o
 obj-$(CONFIG_CMD_BOOTEFI) += bootefi.o
 obj-$(CONFIG_CMD_BOOTMENU) += bootmenu.o
-obj-$(CONFIG_CMD_PHONEMENU) += phone_util.o
+obj-$(CONFIG_CMD_PHONEMENU) += phone_util.o phonemenu.o
 obj-$(CONFIG_CMD_BOOTSTAGE) += bootstage.o
 obj-$(CONFIG_CMD_BOOTZ) += bootz.o
 obj-$(CONFIG_CMD_BOOTI) += booti.o
diff --git a/cmd/phonemenu.c b/cmd/phonemenu.c
new file mode 100644
index 00000000000..30f994bcb64
--- /dev/null
+++ b/cmd/phonemenu.c
@@ -0,0 +1,372 @@
+// SPDX-License-Identifier: GPL-2.0+
+
+#include <cli.h>
+#include <command.h>
+#include <dm.h>
+#include <dm/ofnode.h>
+#include <dm/uclass.h>
+#include <env.h>
+#include <log.h>
+#include <malloc.h>
+#include <menu.h>
+#include <video.h>
+#include <video_console.h>
+#include <version.h>
+#include <linux/string.h>
+
+/* Layout (pixels) */
+#define CARD_MARGIN_X		40
+#define HEADER_TITLE_Y		150
+#define HEADER_SLOT_Y		200
+#define HEADER_VERSION_Y	240
+#define HR_Y			290
+#define HR_THICK		2
+#define BODY_TOP		(HR_Y + HR_THICK + 36)
+#define SECTION_LABEL_H		44
+#define ITEM_H			72
+#define FOOTER_PAD		120
+#define INDENT_SECTION		88
+#define INDENT_ITEM		120
+
+/* Colours packed for X8R8G8B8 */
+#define RGB(r, g, b)		(((u32)(r) << 16) | ((u32)(g) << 8) | (u32)(b))
+#define COL_BG			RGB(0x0d, 0x11, 0x17)
+#define COL_HR			RGB(0x30, 0x36, 0x3d)
+#define COL_TITLE		RGB(0xf0, 0xf3, 0xf6)
+#define COL_SUB			RGB(0x7d, 0x85, 0x90)
+#define COL_SECTION		RGB(0x58, 0xa6, 0xff)
+#define COL_ITEM		RGB(0xc9, 0xd1, 0xd9)
+#define COL_HL_BG		RGB(0x1f, 0x6f, 0xeb)
+#define COL_HL_FG		RGB(0xff, 0xff, 0xff)
+#define COL_FOOTER		RGB(0x7d, 0x85, 0x90)
+
+/* The 16x32 bitmap font */
+#define FONT_W			16
+#define FONT_H			32
+
+enum pm_section {
+	PM_SEC_BOOT,
+	PM_SEC_USB,
+	PM_SEC_DIAG,
+	PM_SEC_SYS,
+	PM_SEC_COUNT,
+};
+
+struct pm_item {
+	const char *label;
+	const char *command;
+	enum pm_section section;
+};
+
+static const char * const pm_section_label[PM_SEC_COUNT] = {
+	[PM_SEC_BOOT] = "BOOT",
+	[PM_SEC_USB]  = "USB MODES",
+	[PM_SEC_DIAG] = "DIAGNOSTICS",
+	[PM_SEC_SYS]  = "SYSTEM",
+};
+
+static const struct pm_item pm_main[] = {
+	{ "Boot",             "run bootcmd",                              PM_SEC_BOOT },
+	{ "Advanced menu >",  "phonemenu advanced",                       PM_SEC_BOOT },
+	{ "Reset",            "reset",                                    PM_SEC_SYS  },
+	{ "Power off",        "phone_poweroff",                           PM_SEC_SYS  },
+};
+
+static const struct pm_item pm_advanced[] = {
+#if IS_ENABLED(CONFIG_USB_ETHER) && IS_ENABLED(CONFIG_CMD_TFTPBOOT)
+	{ "TFTP boot",        "run tftp_boot; phonemenu advanced",        PM_SEC_BOOT },
+#endif
+#if IS_ENABLED(CONFIG_USB_ETHER) && IS_ENABLED(CONFIG_CMD_PXE)
+	{ "PXE boot",         "run pxe_boot; phonemenu advanced",         PM_SEC_BOOT },
+#endif
+#if IS_ENABLED(CONFIG_USB_FUNCTION_ACM)
+	{ "Serial gadget",    "run serial_gadget",                        PM_SEC_USB  },
+#endif
+#if IS_ENABLED(CONFIG_CMD_USB_MASS_STORAGE)
+	{ "USB mass storage", "ums 0 ${storage} 0; phonemenu advanced",   PM_SEC_USB  },
+#endif
+#if IS_ENABLED(CONFIG_CMD_FASTBOOT)
+	{ "Fastboot",         "run fastboot; phonemenu advanced",         PM_SEC_USB  },
+#endif
+#if IS_ENABLED(CONFIG_CMD_DFU)
+	{ "DFU",              "dfu_pwr; phonemenu advanced",              PM_SEC_USB  },
+#endif
+	{ "Diagnostics >",    "phonemenu diag",                           PM_SEC_DIAG },
+	{ "< Back",           "phonemenu",                                PM_SEC_SYS  },
+};
+
+static const struct pm_item pm_diag[] = {
+	{ "Dump clocks",      "clk dump; pause; phonemenu diag",          PM_SEC_DIAG },
+	{ "Dump environment", "printenv; pause; phonemenu diag",          PM_SEC_DIAG },
+	{ "Bootargs",         "fdt addr $fdt_addr_r; fdt print /chosen bootargs; pause; "
+			      "phonemenu diag",                           PM_SEC_DIAG },
+	{ "Board info",       "bdinfo; pause; phonemenu diag",            PM_SEC_DIAG },
+	{ "Buttons",          "button list; pause; phonemenu diag",       PM_SEC_DIAG },
+	{ "< Back",           "phonemenu advanced",                       PM_SEC_SYS  },
+};
+
+struct pm_state {
+	struct udevice *vid;
+	struct udevice *vc;
+	struct video_priv *vp;
+	int w, h;
+	const struct pm_item *items;
+	int count;
+	int active;
+	int last_active;
+	int *row_y;
+	int *section_y;
+	int footer_y;
+	const char *title;
+	const char *subtitle;
+	const char *version;
+};
+
+static int pm_init_dev(struct pm_state *s)
+{
+	int ret;
+
+	ret = uclass_first_device_err(UCLASS_VIDEO, &s->vid);
+	if (ret)
+		return ret;
+	ret = uclass_first_device_err(UCLASS_VIDEO_CONSOLE, &s->vc);
+	if (ret)
+		return ret;
+
+	s->vp = dev_get_uclass_priv(s->vid);
+	s->w = video_get_xsize(s->vid);
+	s->h = video_get_ysize(s->vid);
+	return 0;
+}
+
+static void pm_text(struct pm_state *s, int x, int y, u32 fg, u32 bg,
+		    const char *str)
+{
+	s->vp->colour_fg = fg;
+	s->vp->colour_bg = bg;
+	vidconsole_set_cursor_pos(s->vc, x, y);
+	vidconsole_put_string(s->vc, (char *)str);
+}
+
+static int pm_center_x(struct pm_state *s, const char *str)
+{
+	int px = (int)strlen(str) * FONT_W;
+
+	return (s->w - px) / 2;
+}
+
+static void pm_layout(struct pm_state *s)
+{
+	enum pm_section prev = PM_SEC_COUNT;
+	int y = BODY_TOP;
+	int i;
+
+	for (i = 0; i < s->count; i++) {
+		if (s->items[i].section != prev) {
+			s->section_y[i] = y;
+			y += SECTION_LABEL_H;
+			prev = s->items[i].section;
+		} else {
+			s->section_y[i] = -1;
+		}
+		s->row_y[i] = y;
+		y += ITEM_H;
+	}
+	s->footer_y = s->h - FOOTER_PAD;
+}
+
+static void pm_draw_item(struct pm_state *s, int i, bool active)
+{
+	int y = s->row_y[i];
+	int text_y = y + (ITEM_H - FONT_H) / 2;
+	u32 fg, bg;
+
+	if (active) {
+		video_fill_part(s->vid, CARD_MARGIN_X, y,
+				s->w - CARD_MARGIN_X, y + ITEM_H,
+				COL_HL_BG);
+		fg = COL_HL_FG;
+		bg = COL_HL_BG;
+	} else {
+		video_fill_part(s->vid, CARD_MARGIN_X, y,
+				s->w - CARD_MARGIN_X, y + ITEM_H,
+				COL_BG);
+		fg = COL_ITEM;
+		bg = COL_BG;
+	}
+
+	pm_text(s, INDENT_ITEM, text_y, fg, bg, s->items[i].label);
+}
+
+static void pm_draw_frame(struct pm_state *s)
+{
+	int hr_x0 = CARD_MARGIN_X + 20;
+	int hr_x1 = s->w - CARD_MARGIN_X - 20;
+	const char *foot = "Vol up/down to move    Power to select";
+	int i;
+
+	video_fill_part(s->vid, 0, 0, s->w, s->h, COL_BG);
+
+	pm_text(s, pm_center_x(s, s->title), HEADER_TITLE_Y,
+		COL_TITLE, COL_BG, s->title);
+
+	if (s->subtitle && *s->subtitle)
+		pm_text(s, pm_center_x(s, s->subtitle), HEADER_SLOT_Y,
+			COL_SUB, COL_BG, s->subtitle);
+
+	if (s->version && *s->version)
+		pm_text(s, pm_center_x(s, s->version), HEADER_VERSION_Y,
+			COL_SUB, COL_BG, s->version);
+
+	video_fill_part(s->vid, hr_x0, HR_Y, hr_x1, HR_Y + HR_THICK, COL_HR);
+
+	for (i = 0; i < s->count; i++) {
+		if (s->section_y[i] < 0)
+			continue;
+		pm_text(s, INDENT_SECTION, s->section_y[i],
+			COL_SECTION, COL_BG,
+			pm_section_label[s->items[i].section]);
+	}
+
+	video_fill_part(s->vid, hr_x0, s->footer_y - 36,
+			hr_x1, s->footer_y - 36 + HR_THICK, COL_HR);
+	pm_text(s, pm_center_x(s, foot), s->footer_y,
+		COL_FOOTER, COL_BG, foot);
+}
+
+static void pm_render_all(struct pm_state *s)
+{
+	int i;
+
+	pm_draw_frame(s);
+	for (i = 0; i < s->count; i++)
+		pm_draw_item(s, i, i == s->active);
+	video_sync(s->vid, true);
+}
+
+static int pm_run(const struct pm_item *items, int count,
+		  const char *title, const char *subtitle, const char *version)
+{
+	struct pm_state s = { 0 };
+	struct cli_ch_state cch;
+	struct bootmenu_data nav = {
+		.delay = -1,
+		.active = 0,
+		.last_active = 0,
+		.count = count,
+		.first = NULL,
+	};
+	const char *cmd;
+	bool running = true;
+	int ret = CMD_RET_SUCCESS;
+
+	if (pm_init_dev(&s))
+		return CMD_RET_FAILURE;
+
+	s.items = items;
+	s.count = count;
+	s.title = title;
+	s.subtitle = subtitle;
+	s.version = version;
+	s.row_y = calloc(count, sizeof(int));
+	s.section_y = calloc(count, sizeof(int));
+	if (!s.row_y || !s.section_y) {
+		ret = CMD_RET_FAILURE;
+		goto cleanup;
+	}
+
+	pm_layout(&s);
+	pm_render_all(&s);
+
+	cli_ch_init(&cch);
+	while (running) {
+		enum bootmenu_key k = bootmenu_loop(&nav, &cch);
+
+		switch (k) {
+		case BKEY_UP:
+			/* Wrap from item 0 around to the last item. */
+			s.last_active = s.active;
+			s.active = s.active ? s.active - 1 : count - 1;
+			pm_draw_item(&s, s.last_active, false);
+			pm_draw_item(&s, s.active, true);
+			video_sync(s.vid, true);
+			break;
+		case BKEY_DOWN:
+			/* Wrap from the last item back to item 0. */
+			s.last_active = s.active;
+			s.active = (s.active < count - 1) ? s.active + 1 : 0;
+			pm_draw_item(&s, s.last_active, false);
+			pm_draw_item(&s, s.active, true);
+			video_sync(s.vid, true);
+			break;
+		case BKEY_SELECT:
+			running = false;
+			break;
+		case BKEY_QUIT:
+			s.active = count - 1;
+			running = false;
+			break;
+		default:
+			break;
+		}
+	}
+
+	/* Repaint to BG before running the chosen command */
+	video_fill_part(s.vid, 0, 0, s.w, s.h, COL_BG);
+	vidconsole_set_cursor_pos(s.vc, 16, 0);
+	s.vp->colour_fg = COL_ITEM;
+	s.vp->colour_bg = COL_BG;
+	video_sync(s.vid, true);
+
+	cmd = items[s.active].command;
+	if (cmd && cmd[0])
+		run_command((char *)cmd, 0);
+	/* an empty command leaves us at the console */
+
+cleanup:
+	free(s.row_y);
+	free(s.section_y);
+	return ret;
+}
+
+static const char *pm_codename(void)
+{
+	static char buf[32];
+	const char *compat;
+	const char *p;
+
+	compat = ofnode_read_string(ofnode_root(), "compatible");
+	if (!compat || !*compat)
+		return "unknown";
+
+	p = strchr(compat, ',');
+	if (p)
+		compat = p + 1;
+
+	strlcpy(buf, compat, sizeof(buf));
+	return buf;
+}
+
+static int do_phonemenu(struct cmd_tbl *cmdtp, int flag, int argc,
+			char *const argv[])
+{
+	const char *sub = (argc > 1) ? argv[1] : "main";
+
+	if (!strcmp(sub, "advanced"))
+		return pm_run(pm_advanced, ARRAY_SIZE(pm_advanced),
+			      "Advanced menu", NULL, U_BOOT_VERSION);
+
+	if (!strcmp(sub, "diag"))
+		return pm_run(pm_diag, ARRAY_SIZE(pm_diag),
+			      "Diagnostics", NULL, U_BOOT_VERSION);
+
+	return pm_run(pm_main, ARRAY_SIZE(pm_main),
+		      pm_codename(), NULL, U_BOOT_VERSION);
+}
+
+U_BOOT_CMD(phonemenu, 2, 0, do_phonemenu,
+	   "pixel-drawn sectioned boot menu",
+	   "[advanced|diag]\n"
+	   "    - Render the main menu (default), the advanced menu or the\n"
+	   "      diagnostics submenu.\n"
+	   "      Navigation: Vol up/down to move, Power to select.\n");

-- 
2.55.0

