From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:20 +0200
Subject: [PATCH 04/14] expo: Allow menus to wrap around
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-4-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=4945;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=aFSwbOJj+Rnn0fSwerqsVz5zwUFs6TBz4jMuEhr+ojU=;
 b=eiQxeRYYI4T1tcP71XgfpN3GJDf5nUr7OMdv8W0MNXJTxfFJptaiB1rK1Pckk1LZTrrlaK4jU
 Xl5djhYrEouD0NxZxeLiHDA93KsDRnRSSjIWWTeODjUmBihn44vZNs+
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add scene_menu_set_wrap() so that pressing down on the last selectable
item moves to the first and up on the first moves to the last.

Move the search for the next item into a helper which also skips
section headers.

This is off by default so existing menus behave as before.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/scene_menu.c    | 53 +++++++++++++++++++++++++++++++++++++++-------------
 doc/develop/expo.rst |  3 +++
 include/expo.h       | 14 ++++++++++++++
 3 files changed, 57 insertions(+), 13 deletions(-)

diff --git a/boot/scene_menu.c b/boot/scene_menu.c
index 77d25f34da3..8ec2155e75c 100644
--- a/boot/scene_menu.c
+++ b/boot/scene_menu.c
@@ -379,6 +379,29 @@ static struct scene_menitem *scene_menu_find_key(struct scene *scn,
 	return NULL;
 }
 
+static struct scene_menitem *menu_step(const struct scene_obj_menu *menu,
+				       const struct scene_menitem *cur, bool down)
+{
+	const struct list_head *head = &menu->item_head;
+	const struct list_head *pos = &cur->sibling;
+
+	for (;;) {
+		struct scene_menitem *item;
+
+		pos = down ? pos->next : pos->prev;
+		if (pos == head) {
+			if (!menu->wrap)
+				return NULL;
+			pos = down ? head->next : head->prev;
+		}
+		item = list_entry(pos, struct scene_menitem, sibling);
+		if (item == cur)
+			return NULL;
+		if (!(item->flags & SCENEMIF_HEADER))
+			return item;
+	}
+}
+
 int scene_menu_send_key(struct scene *scn, struct scene_obj_menu *menu, int key,
 			struct expo_action *event)
 {
@@ -403,28 +426,19 @@ int scene_menu_send_key(struct scene *scn, struct scene_obj_menu *menu, int key,
 
 	switch (key) {
 	case BKEY_UP:
-		while (item != list_first_entry(&menu->item_head,
-						struct scene_menitem, sibling)) {
-			item = list_entry(item->sibling.prev,
-					  struct scene_menitem, sibling);
-			if (item->flags & SCENEMIF_HEADER)
-				continue;
+		item = menu_step(menu, cur, false);
+		if (item) {
 			event->type = EXPOACT_POINT_ITEM;
 			event->select.id = item->id;
 			log_debug("up to item %d\n", event->select.id);
-			break;
 		}
 		break;
 	case BKEY_DOWN:
-		while (!list_is_last(&item->sibling, &menu->item_head)) {
-			item = list_entry(item->sibling.next,
-					  struct scene_menitem, sibling);
-			if (item->flags & SCENEMIF_HEADER)
-				continue;
+		item = menu_step(menu, cur, true);
+		if (item) {
 			event->type = EXPOACT_POINT_ITEM;
 			event->select.id = item->id;
 			log_debug("down to item %d\n", event->select.id);
-			break;
 		}
 		break;
 	case BKEY_SELECT:
@@ -635,3 +649,16 @@ int scene_menu_render_deps(struct scene *scn, struct scene_obj_menu *menu)
 
 	return 0;
 }
+
+int scene_menu_set_wrap(struct scene *scn, uint id, bool wrap)
+{
+	struct scene_obj_menu *menu;
+
+	menu = scene_obj_find(scn, id, SCENEOBJT_MENU);
+	if (!menu)
+		return log_msg_ret("menu", -ENOENT);
+
+	menu->wrap = wrap;
+
+	return 0;
+}
diff --git a/doc/develop/expo.rst b/doc/develop/expo.rst
index 9c33284c9aa..40adc049d02 100644
--- a/doc/develop/expo.rst
+++ b/doc/develop/expo.rst
@@ -67,6 +67,9 @@ A menu item flagged `SCENEMIF_HEADER` is a section header. It is laid out and
 shown like any other item, however, it is never highlighted or selected so the
 user can only move between the items around it.
 
+By default the highlight stops at the first and last selectable item. Call
+`scene_menu_set_wrap()` to make up/down wrap around instead.
+
 A `textline object` contains a label and an editable string.
 
 A `box object` is a rectangle with a given line width. It is not filled.
diff --git a/include/expo.h b/include/expo.h
index ac7644d8392..fe20c68750e 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -396,6 +396,7 @@ struct scene_obj_txt {
  * @title_id: ID of the title text, or 0 if none
  * @cur_item_id: ID of the current menu item, or 0 if none
  * @pointer_id: ID of the object pointing to the current selection
+ * @wrap: true to move from the last item to the first, and back, on up/down
  * @item_head: List of items in the menu
  */
 struct scene_obj_menu {
@@ -403,6 +404,7 @@ struct scene_obj_menu {
 	uint title_id;
 	uint cur_item_id;
 	uint pointer_id;
+	bool wrap;
 	struct list_head item_head;
 };
 
@@ -943,6 +945,18 @@ int scene_menu_select_item(struct scene *scn, uint id, uint sel_id);
  */
 int scene_menu_get_cur_item(struct scene *scn, uint id);
 
+/**
+ * scene_menu_set_wrap() - set whether up/down wrap around the ends of a menu
+ *
+ * By default the highlight stops at the first and last selectable item.
+ *
+ * @scn: Scene to update
+ * @id: ID of menu object to update
+ * @wrap: true to wrap around
+ * Return: 0 if OK, -ENOENT if @id is not a menu
+ */
+int scene_menu_set_wrap(struct scene *scn, uint id, bool wrap);
+
 /**
  * scene_obj_get_hw() - Get width and height of an object in a scene
  *

-- 
2.55.0

