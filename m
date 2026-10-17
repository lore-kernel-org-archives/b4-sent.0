From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:24 +0200
Subject: [PATCH 08/14] test: expo: Test setting the background colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-8-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=1577;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=zOT9KuiJwBhCFWl3FN4WtxbXfzlBrDYCsfqOv+hX7X4=;
 b=FD3DSPg005od8XM7M8mgPJS/O/Tr5/B/yWn6PnVxDhzddxza77U5yUv9bu9LDe3oYD6t7OYlF
 Rzr4WuO76LhCG14iS0xuiZbJGuZ+H2ED0l6AvQpI1XljYvdBRbQzKlw
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add expo_bg_rgb() to check that expo_set_bg_rgb() records the colour and
that rendering leaves the video device's own background colour as it was.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 33 +++++++++++++++++++++++++++++++++
 1 file changed, 33 insertions(+)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index e52de029477..b50c32c0860 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -944,3 +944,36 @@ static int expo_menu_header(struct unit_test_state *uts)
 	return 0;
 }
 BOOTSTD_TEST(expo_menu_header, UTF_DM | UTF_SCAN_FDT);
+
+/* Test setting the background colour */
+static int expo_bg_rgb(struct unit_test_state *uts)
+{
+	struct video_priv *vid_priv;
+	struct scene *scn;
+	struct udevice *dev;
+	struct expo *exp;
+	u32 old_bg;
+
+	ut_assertok(uclass_first_device_err(UCLASS_VIDEO, &dev));
+	vid_priv = dev_get_uclass_priv(dev);
+	old_bg = vid_priv->colour_bg;
+
+	ut_assertok(expo_new(EXPO_NAME, NULL, &exp));
+	ut_assert(scene_new(exp, SCENE_NAME1, SCENE1, &scn) > 0);
+	ut_assertok(expo_set_display(exp, dev));
+	ut_assertok(expo_set_scene_id(exp, SCENE1));
+
+	ut_assert(!exp->has_bg_rgb);
+	expo_set_bg_rgb(exp, 0x0d1117);
+	ut_assert(exp->has_bg_rgb);
+	ut_asserteq(0x0d1117, exp->bg_rgb);
+
+	/* rendering uses the colour but leaves the video device's alone */
+	ut_assertok(expo_render(exp));
+	ut_asserteq(old_bg, vid_priv->colour_bg);
+
+	expo_destroy(exp);
+
+	return 0;
+}
+BOOTSTD_TEST(expo_bg_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);

-- 
2.55.0

