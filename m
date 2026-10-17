From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:30 +0200
Subject: [PATCH 14/14] test: expo: Test a text object with an RGB colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-14-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=1857;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=xxKsFm6ww2Zbe1I+mjfKuL8mjt9Djj194g4yJQh4yvA=;
 b=lo6z/a0g/ppsepvYn3NO+eeJIkjtx6KVEKj0khoHuGDzkCnDgZvtJyHzX9D0ZpbfJHQjTY9yh
 RISE45tCR2RCbfATGhmneG5f/sx2kggh2ly5Xa9mxJAHRZHtptCUQlC
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add expo_txt_rgb() to check that scene_txt_set_rgb() records the colour on
a text object.

Check it returns -ENOENT for an unknown ID and that rendering
leaves the video device's own foreground colour as it was.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 38 ++++++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index 9a8012cbd51..5ea0e6b51c4 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -1060,3 +1060,41 @@ static int expo_highlight_rgb(struct unit_test_state *uts)
 	return 0;
 }
 BOOTSTD_TEST(expo_highlight_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);
+
+/* Test giving a text object an RGB colour */
+static int expo_txt_rgb(struct unit_test_state *uts)
+{
+	struct scene_obj_txt *txt;
+	struct video_priv *vid_priv;
+	struct scene *scn;
+	struct udevice *dev;
+	struct expo *exp;
+	u32 old_fg;
+
+	ut_assertok(uclass_first_device_err(UCLASS_VIDEO, &dev));
+	vid_priv = dev_get_uclass_priv(dev);
+	old_fg = vid_priv->colour_fg;
+
+	ut_assertok(expo_new(EXPO_NAME, NULL, &exp));
+	ut_assert(scene_new(exp, SCENE_NAME1, SCENE1, &scn) > 0);
+	ut_assertok(expo_set_display(exp, dev));
+
+	ut_assert(scene_txt_str(scn, "text", OBJ_TEXT, STR_TEXT, "my string",
+				&txt) > 0);
+	ut_assert(!txt->gen.has_rgb);
+	ut_assertok(scene_txt_set_rgb(scn, OBJ_TEXT, 0xc9d1d9));
+	ut_assert(txt->gen.has_rgb);
+	ut_asserteq(0xc9d1d9, txt->gen.rgb);
+
+	/* only text objects have a colour */
+	ut_asserteq(-ENOENT, scene_txt_set_rgb(scn, 9999, 0));
+
+	ut_assertok(expo_set_scene_id(exp, SCENE1));
+	ut_assertok(expo_render(exp));
+	ut_asserteq(old_fg, vid_priv->colour_fg);
+
+	expo_destroy(exp);
+
+	return 0;
+}
+BOOTSTD_TEST(expo_txt_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);

-- 
2.55.0

