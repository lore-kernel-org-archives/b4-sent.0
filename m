From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:21 +0200
Subject: [PATCH 05/14] test: expo: Test menu wrap-around
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-5-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=1726;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=tcuyYZ6bOFix6DB65XGo7ybP7hqjrHESxrvYuJQ+VIQ=;
 b=24XcAnNfohkIQBEQMP4jMF2QiwUWO0+/NZN6aME3g+1SIJqV2dKOcZh3wwLWL5DPtQUz0DwNp
 Cn0oGsSfcXpAn8KSXfMwk3tBVZZSgWaarpl6hIOJ/cG1Ewn0z8hXDu2
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend expo_menu_header() to check that with wrapping enabled up from
the first selectable item goes to the last item and down from the last
goes back to the first.

Check it's also skipping the section header and that scene_menu_set_wrap()
returns -ENOENT for an object which is not a menu.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/boot/expo.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/test/boot/expo.c b/test/boot/expo.c
index 19148a8892e..e52de029477 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -865,7 +865,7 @@ static int expo_test_build(struct unit_test_state *uts)
 }
 BOOTSTD_TEST(expo_test_build, UTF_DM);
 
-/* Test that section-header menu items are skipped by selection and keys */
+/* Test section headers and wrapping with up/down keys */
 static int expo_menu_header(struct unit_test_state *uts)
 {
 	struct scene_obj_menu *menu;
@@ -927,6 +927,17 @@ static int expo_menu_header(struct unit_test_state *uts)
 	ut_assertok(expo_send_key(exp, BKEY_UP));
 	ut_asserteq(-EAGAIN, expo_action_get(exp, &act));
 
+	/* with wrapping, it goes to the last item, then back to the first */
+	ut_assertok(scene_menu_set_wrap(scn, OBJ_MENU, true));
+	ut_asserteq(-ENOENT, scene_menu_set_wrap(scn, ITEM2, true));
+	ut_assertok(expo_send_key(exp, BKEY_UP));
+	ut_assertok(expo_action_get(exp, &act));
+	ut_asserteq(ITEM4, act.select.id);
+	ut_assertok(scene_menu_select_item(scn, OBJ_MENU, ITEM4));
+	ut_assertok(expo_send_key(exp, BKEY_DOWN));
+	ut_assertok(expo_action_get(exp, &act));
+	ut_asserteq(ITEM2, act.select.id);
+
 	expo_destroy(exp);
 	ut_assertok(ut_check_delta(start_mem));
 

-- 
2.55.0

