From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:28 +0200
Subject: [PATCH 12/14] test: expo: Test setting the highlight colours
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-12-479ac06e7642@protonmail.com>
References: <20261017-b4-expo-colours-v1-0-479ac06e7642@protonmail.com>
In-Reply-To: <20261017-b4-expo-colours-v1-0-479ac06e7642@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=2269;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=r/A1+zfVVHxHzN6Ykw8gBWo77vTIojcmydtusTmGxPU=;
 b=Zgx5ebijGokT878W6Eu/B/aP3R8heNTfClTjQv36x2xczYmQBC4zZ3ep6zWtKjFo91YW50Xub
 aEaXKYZ8yYGAoC1oA+lBunSTOilBVOL8Nl9+ap1ncq4DHH1+2DOjTIN
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add expo_highlight_rgb() to check that expo_set_highlight_rgb() records
both colours.

Check that rendering a menu with a highlight leaves the video device's own
foreground and background colours as they were.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 46 ++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 46 insertions(+)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index 2374e61f864..9a8012cbd51 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -1014,3 +1014,49 @@ static int expo_box_rgb(struct unit_test_state *uts)
 	return 0;
 }
 BOOTSTD_TEST(expo_box_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);
+
+/* Test setting the colours of the highlight bar */
+static int expo_highlight_rgb(struct unit_test_state *uts)
+{
+	struct scene_obj_menu *menu;
+	struct video_priv *vid_priv;
+	struct scene *scn;
+	struct udevice *dev;
+	struct expo *exp;
+	u32 old_fg, old_bg;
+
+	ut_assertok(uclass_first_device_err(UCLASS_VIDEO, &dev));
+	vid_priv = dev_get_uclass_priv(dev);
+	old_fg = vid_priv->colour_fg;
+	old_bg = vid_priv->colour_bg;
+
+	ut_assertok(expo_new(EXPO_NAME, NULL, &exp));
+	ut_assert(scene_new(exp, SCENE_NAME1, SCENE1, &scn) > 0);
+	ut_assertok(expo_set_display(exp, dev));
+
+	ut_assert(scene_menu(scn, "main", OBJ_MENU, &menu) > 0);
+	ut_assert(scene_txt_str(scn, "label1", ITEM1_LABEL, STR_ITEM1_LABEL,
+				"Play", NULL) > 0);
+	ut_assert(scene_menuitem(scn, OBJ_MENU, "item1", ITEM1, 0,
+				 ITEM1_LABEL, 0, 0, 0, NULL) > 0);
+	scene_set_highlight_id(scn, OBJ_MENU);
+	ut_assertok(scene_menu_select_item(scn, OBJ_MENU, ITEM1));
+	exp->show_highlight = true;
+
+	ut_assert(!exp->has_hl_rgb);
+	expo_set_highlight_rgb(exp, 0x1f6feb, 0xffffff);
+	ut_assert(exp->has_hl_rgb);
+	ut_asserteq(0x1f6feb, exp->hl_bg_rgb);
+	ut_asserteq(0xffffff, exp->hl_fg_rgb);
+
+	/* rendering uses the colours but leaves the video device's alone */
+	ut_assertok(expo_set_scene_id(exp, SCENE1));
+	ut_assertok(expo_render(exp));
+	ut_asserteq(old_fg, vid_priv->colour_fg);
+	ut_asserteq(old_bg, vid_priv->colour_bg);
+
+	expo_destroy(exp);
+
+	return 0;
+}
+BOOTSTD_TEST(expo_highlight_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);

-- 
2.55.0

