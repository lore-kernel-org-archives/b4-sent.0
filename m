From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:19 +0200
Subject: [PATCH 03/14] expo: Allow a text object to have its own colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-3-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=4372;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=UPB0LHVZw5Jb28TCAoxQMD5l5dcBNqsaNcayOVg/y+U=;
 b=ObGaBB2Zl5z90ccG51eijn73KEWv26yRQYsruCZx0UNiIKvpZCSJndzoJyc2lqCCYeL9YjEXH
 abUffo5JBQTBk9kU8SFZ5no2ol4sQzUhZIRqliy5/aNDpVFO3vCudrh
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add scene_txt_set_colour() to draw a text object in a chosen foreground
colour, on the normal background.

The colour is not used while the object is highlighted which keeps
the reverse-video bar.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/scene.c     | 22 +++++++++++++++++++++-
 include/expo.h   | 17 +++++++++++++++++
 test/boot/expo.c |  4 ++++
 3 files changed, 42 insertions(+), 1 deletion(-)

diff --git a/boot/scene.c b/boot/scene.c
index fa8f540bfb0..6073ab5a9f5 100644
--- a/boot/scene.c
+++ b/boot/scene.c
@@ -245,6 +245,19 @@ int scene_txt_set_font(struct scene *scn, uint id, const char *font_name,
 	return 0;
 }
 
+int scene_txt_set_colour(struct scene *scn, uint id, enum colour_idx colour)
+{
+	struct scene_obj_txt *txt;
+
+	txt = scene_obj_find(scn, id, SCENEOBJT_TEXT);
+	if (!txt)
+		return log_msg_ret("find", -ENOENT);
+	txt->gen.has_colour = true;
+	txt->gen.colour = colour;
+
+	return 0;
+}
+
 int scene_obj_set_pos(struct scene *scn, uint id, int x, int y)
 {
 	struct scene_obj *obj;
@@ -526,6 +539,7 @@ static int scene_txt_render(struct expo *exp, struct udevice *dev,
 	enum colour_idx fore, back;
 	struct scene_obj_dims dims;
 	struct scene_obj_bbox bbox;
+	bool tinted = false;
 	const char *str;
 	int ret;
 
@@ -561,6 +575,12 @@ static int scene_txt_render(struct expo *exp, struct udevice *dev,
 		video_fill_part(dev, x - inset, y,
 				obj->bbox.x1, obj->bbox.y1,
 				vid_priv->colour_bg);
+	} else if (gen->has_colour) {
+		tinted = true;
+		old.colour_fg = vid_priv->colour_fg;
+		old.colour_bg = vid_priv->colour_bg;
+		vid_priv->colour_fg = video_index_to_colour(vid_priv,
+							    gen->colour);
 	}
 
 	mline = alist_get(&gen->lines, 0, typeof(*mline));
@@ -592,7 +612,7 @@ static int scene_txt_render(struct expo *exp, struct udevice *dev,
 		vidconsole_set_cursor_pos(cons, x, y);
 		vidconsole_put_stringn(cons, str + mline->start, mline->len);
 	}
-	if (obj->flags & SCENEOF_POINT)
+	if ((obj->flags & SCENEOF_POINT) || tinted)
 		vidconsole_pop_colour(cons, &old);
 
 	return 0;
diff --git a/include/expo.h b/include/expo.h
index 3127b4fd5f2..ac7644d8392 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -12,6 +12,7 @@
 #include <dm/ofnode_decl.h>
 #include <linux/bitops.h>
 #include <linux/list.h>
+#include <video.h>
 
 struct udevice;
 
@@ -352,6 +353,8 @@ struct scene_obj_img {
  * @str_id: ID of the text string to display
  * @font_name: Name of font (allocated by caller)
  * @font_size: Nominal size of font in pixels
+ * @has_colour: true to draw the text in @colour instead of the default
+ * @colour: Foreground colour to use if @has_colour
  * @lines: alist of struct vidconsole_mline with a separate record for each
  *	line of text
  */
@@ -359,6 +362,8 @@ struct scene_txt_generic {
 	uint str_id;
 	const char *font_name;
 	uint font_size;
+	bool has_colour;
+	enum colour_idx colour;
 	struct alist lines;
 };
 
@@ -803,6 +808,18 @@ int scene_txt_set_font(struct scene *scn, uint id, const char *font_name,
 int scene_txted_set_font(struct scene *scn, uint id, const char *font_name,
 			 uint font_size);
 
+/**
+ * scene_txt_set_colour() - Set the foreground colour of a text object
+ *
+ * The colour is ignored while the object is highlighted.
+ *
+ * @scn: Scene to update
+ * @id: ID of text object to update
+ * @colour: Foreground colour to use
+ * Return: 0 if OK, -ENOENT if @id is not a text object
+ */
+int scene_txt_set_colour(struct scene *scn, uint id, enum colour_idx colour);
+
 /**
  * scene_obj_set_pos() - Set the postion of an object
  *
diff --git a/test/boot/expo.c b/test/boot/expo.c
index 5ea8c016706..19148a8892e 100644
--- a/test/boot/expo.c
+++ b/test/boot/expo.c
@@ -898,6 +898,10 @@ static int expo_menu_header(struct unit_test_state *uts)
 	ut_assert(scene_menuitem(scn, OBJ_MENU, "item4", ITEM4, 0, ITEM4_LABEL,
 				 0, 0, 0, NULL) > 0);
 
+	/* a header can be tinted; other IDs are not text objects */
+	ut_assertok(scene_txt_set_colour(scn, ITEM1_LABEL, VID_LIGHT_BLUE));
+	ut_asserteq(-ENOENT, scene_txt_set_colour(scn, OBJ_MENU, VID_RED));
+
 	/* the first selectable item is current, not the header before it */
 	ut_assertok(scene_arrange(scn));
 	ut_asserteq(ITEM2, menu->cur_item_id);

-- 
2.55.0

