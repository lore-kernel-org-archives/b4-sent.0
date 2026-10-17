From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:26 +0200
Subject: [PATCH 10/14] test: expo: Test a box with its own colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-10-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=1800;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=Vbjcl9pQZ3UyhdQBRck7uib88dk+EsLCEq41Sxopc3c=;
 b=EbFKQfR29znNZa+ELxsmI6B+bMMyo0q1+JJ2xWrsL4WmmPzTz9tNyrdglbzu2E0aMwsaFeMqu
 J2jjnLinN8VDFU1bykNXfeUIWe5D958yoE7/uDkEIxedlcSM5mWvUXu
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add expo_box_rgb() to check that scene_box_set_rgb() records the colour on
a box.

Returns -ENOENT for a non-box object or an unknown ID.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index b50c32c0860..2374e61f864 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -977,3 +977,40 @@ static int expo_bg_rgb(struct unit_test_state *uts)
 	return 0;
 }
 BOOTSTD_TEST(expo_bg_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);
+
+/* Test drawing a box in its own colour, as used for a horizontal rule */
+static int expo_box_rgb(struct unit_test_state *uts)
+{
+	struct scene_obj_box *box;
+	struct scene *scn;
+	struct udevice *dev;
+	struct expo *exp;
+
+	ut_assertok(uclass_first_device_err(UCLASS_VIDEO, &dev));
+
+	ut_assertok(expo_new(EXPO_NAME, NULL, &exp));
+	ut_assert(scene_new(exp, SCENE_NAME1, SCENE1, &scn) > 0);
+	ut_assertok(expo_set_display(exp, dev));
+
+	ut_assert(scene_box(scn, "rule", OBJ_BOX, 2, &box) > 0);
+	ut_assertok(scene_obj_set_bbox(scn, OBJ_BOX, 10, 20, 200, 22));
+	ut_assert(!box->has_rgb);
+	ut_assertok(scene_box_set_rgb(scn, OBJ_BOX, 0x30363d));
+	ut_assert(box->has_rgb);
+	ut_asserteq(0x30363d, box->rgb);
+
+	ut_assert(scene_txt_str(scn, "text", OBJ_TEXT, STR_TEXT, "my string",
+				NULL) > 0);
+
+	/* only boxes have a colour */
+	ut_asserteq(-ENOENT, scene_box_set_rgb(scn, OBJ_TEXT, 0));
+	ut_asserteq(-ENOENT, scene_box_set_rgb(scn, 9999, 0));
+
+	ut_assertok(expo_set_scene_id(exp, SCENE1));
+	ut_assertok(expo_render(exp));
+
+	expo_destroy(exp);
+
+	return 0;
+}
+BOOTSTD_TEST(expo_box_rgb, UTF_DM | UTF_SCAN_FDT | UTF_CONSOLE);

-- 
2.55.0

