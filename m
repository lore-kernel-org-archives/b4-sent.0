From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:17 +0200
Subject: [PATCH 01/14] expo: Add section headers to menus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-1-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228224; l=4158;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=hp4TfbV9qOLml3czJGjCQePcM+zDAQKZ4nr9rlvyC3U=;
 b=w3qyqQfwNG4envoYLYIypOLBUDp96jq631ji6+5zYTsGHcm+kVjumQMCnduZaH6YZupY96Ecx
 wvGe1g//O+ZCdsRUAQx3XskBDcBMF5a5zpBbwGfSJpiYhNZk25ha9e/
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add SCENEMIF_HEADER a menu item flag for an item which is laid out and
shown like any other but is never highlighted or selected.

Up/down skip over it the initial selection skips it and
scene_menu_select_item() refuses it.

This lets a menu group its items under titles.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/scene_menu.c    | 21 +++++++++++++++++----
 doc/develop/expo.rst |  4 ++++
 include/expo.h       |  2 ++
 3 files changed, 23 insertions(+), 4 deletions(-)

diff --git a/boot/scene_menu.c b/boot/scene_menu.c
index 23404172093..77d25f34da3 100644
--- a/boot/scene_menu.c
+++ b/boot/scene_menu.c
@@ -277,7 +277,7 @@ int scene_menu_arrange(struct scene *scn, struct expo_arrange_info *arr,
 			y += height;
 
 		/* select an item if not done already */
-		if (!sel_id)
+		if (!sel_id && !(item->flags & SCENEMIF_HEADER))
 			sel_id = item->id;
 
 		selected = sel_id == item->id;
@@ -361,6 +361,8 @@ static struct scene_menitem *scene_menu_find_key(struct scene *scn,
 	struct scene_menitem *item;
 
 	list_for_each_entry(item, &menu->item_head, sibling) {
+		if (item->flags & SCENEMIF_HEADER)
+			continue;
 		if (item->key_id) {
 			struct scene_obj_txt *txt;
 			const char *str;
@@ -401,22 +403,28 @@ int scene_menu_send_key(struct scene *scn, struct scene_obj_menu *menu, int key,
 
 	switch (key) {
 	case BKEY_UP:
-		if (item != list_first_entry(&menu->item_head,
-					     struct scene_menitem, sibling)) {
+		while (item != list_first_entry(&menu->item_head,
+						struct scene_menitem, sibling)) {
 			item = list_entry(item->sibling.prev,
 					  struct scene_menitem, sibling);
+			if (item->flags & SCENEMIF_HEADER)
+				continue;
 			event->type = EXPOACT_POINT_ITEM;
 			event->select.id = item->id;
 			log_debug("up to item %d\n", event->select.id);
+			break;
 		}
 		break;
 	case BKEY_DOWN:
-		if (!list_is_last(&item->sibling, &menu->item_head)) {
+		while (!list_is_last(&item->sibling, &menu->item_head)) {
 			item = list_entry(item->sibling.next,
 					  struct scene_menitem, sibling);
+			if (item->flags & SCENEMIF_HEADER)
+				continue;
 			event->type = EXPOACT_POINT_ITEM;
 			event->select.id = item->id;
 			log_debug("down to item %d\n", event->select.id);
+			break;
 		}
 		break;
 	case BKEY_SELECT:
@@ -529,12 +537,17 @@ int scene_menu_set_pointer(struct scene *scn, uint id, uint pointer_id)
 int scene_menu_select_item(struct scene *scn, uint id, uint cur_item_id)
 {
 	struct scene_obj_menu *menu;
+	const struct scene_menitem *item;
 	int ret;
 
 	menu = scene_obj_find(scn, id, SCENEOBJT_MENU);
 	if (!menu)
 		return log_msg_ret("menu", -ENOENT);
 
+	item = scene_menuitem_find(menu, cur_item_id);
+	if (item && (item->flags & SCENEMIF_HEADER))
+		return log_msg_ret("hdr", -EINVAL);
+
 	ret = menu_point_to_item(menu, cur_item_id);
 	if (ret)
 		return log_msg_ret("msi", ret);
diff --git a/doc/develop/expo.rst b/doc/develop/expo.rst
index b94340e9a8d..9c33284c9aa 100644
--- a/doc/develop/expo.rst
+++ b/doc/develop/expo.rst
@@ -63,6 +63,10 @@ select the item), label and description. All three are shown in a single line
 within the menu. Items can also have a preview image, which is shown when the
 item is highlighted.
 
+A menu item flagged `SCENEMIF_HEADER` is a section header. It is laid out and
+shown like any other item, however, it is never highlighted or selected so the
+user can only move between the items around it.
+
 A `textline object` contains a label and an editable string.
 
 A `box object` is a rectangle with a given line width. It is not filled.
diff --git a/include/expo.h b/include/expo.h
index 4dee479e9a0..3127b4fd5f2 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -405,9 +405,11 @@ struct scene_obj_menu {
  * enum scene_menuitem_flags_t - flags for menu items
  *
  * @SCENEMIF_GAP_BEFORE: Add a gap before this item
+ * @SCENEMIF_HEADER: Item is a section header (shown but never selectable)
  */
 enum scene_menuitem_flags_t {
 	SCENEMIF_GAP_BEFORE	= 1 << 0,
+	SCENEMIF_HEADER		= 1 << 1,
 };
 
 /**

-- 
2.55.0

