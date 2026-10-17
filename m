From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:29 +0200
Subject: [PATCH 13/14] expo: Allow a text object to have an RGB colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-13-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=3321;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=hfhRmbv0dP9i7Vv5j6qfTA1XgO594G8Eofa70uxUQl0=;
 b=6vDT9XZf6k8IsMi3IYNL0NapPpo88QdQ2qt/JzRE7hZBJewVn0fF6AHgKalvr/7bAiDVS3gno
 mX62GQC/FenDwV2AXgi3PpjsYGYQatXoNgPmsF6qmdX0btGW0cdrl63
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

scene_txt_set_colour() is limited to the sixteen console colours. Add
scene_txt_set_rgb() to draw a text object in any 0xRRGGBB colour.

Similar to the console colours it is not used while the object
is highlighted.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/scene.c   | 22 +++++++++++++++++++---
 include/expo.h | 18 ++++++++++++++++++
 2 files changed, 37 insertions(+), 3 deletions(-)

diff --git a/boot/scene.c b/boot/scene.c
index 06f46a3c7c2..968c21e448a 100644
--- a/boot/scene.c
+++ b/boot/scene.c
@@ -271,6 +271,19 @@ int scene_txt_set_colour(struct scene *scn, uint id, enum colour_idx colour)
 	return 0;
 }
 
+int scene_txt_set_rgb(struct scene *scn, uint id, u32 rgb)
+{
+	struct scene_obj_txt *txt;
+
+	txt = scene_obj_find(scn, id, SCENEOBJT_TEXT);
+	if (!txt)
+		return log_msg_ret("find", -ENOENT);
+	txt->gen.has_rgb = true;
+	txt->gen.rgb = rgb;
+
+	return 0;
+}
+
 int scene_obj_set_pos(struct scene *scn, uint id, int x, int y)
 {
 	struct scene_obj *obj;
@@ -602,12 +615,15 @@ static int scene_txt_render(struct expo *exp, struct udevice *dev,
 		video_fill_part(dev, x - inset, y,
 				obj->bbox.x1, obj->bbox.y1,
 				vid_priv->colour_bg);
-	} else if (gen->has_colour) {
+	} else if (gen->has_colour || gen->has_rgb) {
 		tinted = true;
 		old.colour_fg = vid_priv->colour_fg;
 		old.colour_bg = vid_priv->colour_bg;
-		vid_priv->colour_fg = video_index_to_colour(vid_priv,
-							    gen->colour);
+		if (gen->has_rgb)
+			vid_priv->colour_fg = rgb_to_colour(vid_priv, gen->rgb);
+		else
+			vid_priv->colour_fg = video_index_to_colour(vid_priv,
+								    gen->colour);
 	}
 
 	mline = alist_get(&gen->lines, 0, typeof(*mline));
diff --git a/include/expo.h b/include/expo.h
index 258b9b66993..48e1d2d58e1 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -365,6 +365,8 @@ struct scene_obj_img {
  * @font_size: Nominal size of font in pixels
  * @has_colour: true to draw the text in @colour instead of the default
  * @colour: Foreground colour to use if @has_colour
+ * @has_rgb: true to draw the text in @rgb instead of the default or @colour
+ * @rgb: Foreground colour as 0xRRGGBB used if @has_rgb
  * @lines: alist of struct vidconsole_mline with a separate record for each
  *	line of text
  */
@@ -374,6 +376,8 @@ struct scene_txt_generic {
 	uint font_size;
 	bool has_colour;
 	enum colour_idx colour;
+	bool has_rgb;
+	u32 rgb;
 	struct alist lines;
 };
 
@@ -873,6 +877,20 @@ int scene_txted_set_font(struct scene *scn, uint id, const char *font_name,
  */
 int scene_txt_set_colour(struct scene *scn, uint id, enum colour_idx colour);
 
+/**
+ * scene_txt_set_rgb() - Set the foreground colour of a text object to an RGB
+ *
+ * Similar to scene_txt_set_colour() but allows any colour rather than one
+ * of the console colours. It takes precedence over scene_txt_set_colour().
+ * The colour is ignored while the object is highlighted
+ *
+ * @scn: Scene to update
+ * @id: ID of text object to update
+ * @rgb: Foreground colour to use as 0xRRGGBB
+ * Return: 0 if OK, -ENOENT if @id is not a text object
+ */
+int scene_txt_set_rgb(struct scene *scn, uint id, u32 rgb);
+
 /**
  * scene_obj_set_pos() - Set the postion of an object
  *

-- 
2.55.0

