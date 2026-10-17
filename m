From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:18 +0200
Subject: [PATCH 02/14] test: expo: Add a test for menu section headers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-2-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=3257;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=AnoiUr+7DbHmSJ/S8XWOSnV6gGNomi+vIaAAAe0n6Ko=;
 b=yS1euP1foHp1UpqRFiF8sKQN0NfNOIxK9EQhznpyi+/P7C8FeplGKG5XDfeuRupqX7Kygtt3V
 4xqAGFhaypBAo/wFHfxu1QYUZhX57wrdd4JOXPH9HgD0ViX5OfDgFyf
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check that up/down and the initial selection skip a SCENEMIF_HEADER item
and that scene_menu_select_item() refuses it.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 72 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 72 insertions(+)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index ddfb739f9cf..5ea8c016706 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -67,6 +67,13 @@ enum {
 
 	/* pointer to current item */
 	POINTER_TEXT,
+
+	STR_ITEM3_LABEL,
+	STR_ITEM4_LABEL,
+	ITEM3,
+	ITEM3_LABEL,
+	ITEM4,
+	ITEM4_LABEL,
 };
 
 #define BAD_POINTER	((void *)1)
@@ -857,3 +864,68 @@ static int expo_test_build(struct unit_test_state *uts)
 	return 0;
 }
 BOOTSTD_TEST(expo_test_build, UTF_DM);
+
+/* Test that section-header menu items are skipped by selection and keys */
+static int expo_menu_header(struct unit_test_state *uts)
+{
+	struct scene_obj_menu *menu;
+	struct expo_action act;
+	struct scene *scn;
+	struct expo *exp;
+	ulong start_mem;
+
+	start_mem = ut_check_free();
+
+	ut_assertok(expo_new(EXPO_NAME, NULL, &exp));
+	ut_assert(scene_new(exp, SCENE_NAME1, SCENE1, &scn) > 0);
+	ut_assert(scene_menu(scn, "main", OBJ_MENU, &menu) > 0);
+
+	/* header, item, header, item */
+	ut_assert(scene_txt_str(scn, "h1", ITEM1_LABEL, STR_ITEM1_LABEL, "A",
+				NULL) > 0);
+	ut_assert(scene_menuitem(scn, OBJ_MENU, "hdr1", ITEM1, 0, ITEM1_LABEL,
+				 0, 0, SCENEMIF_HEADER, NULL) > 0);
+	ut_assert(scene_txt_str(scn, "l2", ITEM2_LABEL, STR_ITEM2_LABEL, "B",
+				NULL) > 0);
+	ut_assert(scene_menuitem(scn, OBJ_MENU, "item2", ITEM2, 0, ITEM2_LABEL,
+				 0, 0, 0, NULL) > 0);
+	ut_assert(scene_txt_str(scn, "h3", ITEM3_LABEL, STR_ITEM3_LABEL, "C",
+				NULL) > 0);
+	ut_assert(scene_menuitem(scn, OBJ_MENU, "hdr3", ITEM3, 0, ITEM3_LABEL,
+				 0, 0, SCENEMIF_HEADER, NULL) > 0);
+	ut_assert(scene_txt_str(scn, "l4", ITEM4_LABEL, STR_ITEM4_LABEL, "D",
+				NULL) > 0);
+	ut_assert(scene_menuitem(scn, OBJ_MENU, "item4", ITEM4, 0, ITEM4_LABEL,
+				 0, 0, 0, NULL) > 0);
+
+	/* the first selectable item is current, not the header before it */
+	ut_assertok(scene_arrange(scn));
+	ut_asserteq(ITEM2, menu->cur_item_id);
+
+	/* a header cannot be selected directly */
+	ut_asserteq(-EINVAL, scene_menu_select_item(scn, OBJ_MENU, ITEM1));
+
+	/* down skips the second header */
+	ut_assertok(expo_set_scene_id(exp, SCENE1));
+	ut_assertok(expo_send_key(exp, BKEY_DOWN));
+	ut_assertok(expo_action_get(exp, &act));
+	ut_asserteq(EXPOACT_POINT_ITEM, act.type);
+	ut_asserteq(ITEM4, act.select.id);
+	ut_assertok(scene_menu_select_item(scn, OBJ_MENU, ITEM4));
+
+	/* up skips it again */
+	ut_assertok(expo_send_key(exp, BKEY_UP));
+	ut_assertok(expo_action_get(exp, &act));
+	ut_asserteq(ITEM2, act.select.id);
+	ut_assertok(scene_menu_select_item(scn, OBJ_MENU, ITEM2));
+
+	/* nothing selectable above: the leading header gives no action */
+	ut_assertok(expo_send_key(exp, BKEY_UP));
+	ut_asserteq(-EAGAIN, expo_action_get(exp, &act));
+
+	expo_destroy(exp);
+	ut_assertok(ut_check_delta(start_mem));
+
+	return 0;
+}
+BOOTSTD_TEST(expo_menu_header, UTF_DM | UTF_SCAN_FDT);

-- 
2.55.0

