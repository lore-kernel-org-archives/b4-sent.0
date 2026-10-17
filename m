From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:25 +0200
Subject: [PATCH 09/14] expo: Allow a box to have its own colour
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-9-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=2696;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=9YaaXsdEUmQIItAOT+My/QhEBjL0DWy8CWDfbsYOQvg=;
 b=8V8U8AvRwcO6E8aFdiN9SYYKBHstR0/wq5yYQVZ833NxK3guZUPKacJbN67rAK6Wf3FhOmJKE
 iZVE09b6dEDBYpENPrYJD4llfGi22mZ/oqzz5kNs2MUx5QGaPgBwrc5
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add scene_box_set_rgb() to draw a box in a chosen colour instead of the
console foreground.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/scene.c   | 20 +++++++++++++++++++-
 include/expo.h | 17 +++++++++++++++++
 2 files changed, 36 insertions(+), 1 deletion(-)

diff --git a/boot/scene.c b/boot/scene.c
index 6073ab5a9f5..3f63c84a331 100644
--- a/boot/scene.c
+++ b/boot/scene.c
@@ -231,6 +231,19 @@ int scene_box(struct scene *scn, const char *name, uint id, uint width,
 	return box->obj.id;
 }
 
+int scene_box_set_rgb(struct scene *scn, uint id, u32 rgb)
+{
+	struct scene_obj_box *box;
+
+	box = scene_obj_find(scn, id, SCENEOBJT_BOX);
+	if (!box)
+		return log_msg_ret("find", -ENOENT);
+	box->has_rgb = true;
+	box->rgb = rgb;
+
+	return 0;
+}
+
 int scene_txt_set_font(struct scene *scn, uint id, const char *font_name,
 		       uint font_size)
 {
@@ -696,8 +709,13 @@ static int scene_obj_render(struct scene_obj *obj, bool text_mode)
 	case SCENEOBJT_BOX: {
 		struct scene_obj_box *box = (struct scene_obj_box *)obj;
 
+		u32 colour = vid_priv->colour_fg;
+
+		if (box->has_rgb)
+			colour = video_rgb_to_colour(vid_priv, box->rgb >> 16,
+						     box->rgb >> 8, box->rgb);
 		video_draw_box(dev, obj->bbox.x0, obj->bbox.y0, obj->bbox.x1,
-			       obj->bbox.y1, box->width, vid_priv->colour_fg);
+			       obj->bbox.y1, box->width, colour);
 		break;
 	}
 	case SCENEOBJT_TEXTEDIT: {
diff --git a/include/expo.h b/include/expo.h
index 61fec3d52c5..995c57e7bad 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -481,10 +481,14 @@ struct scene_obj_textline {
  *
  * @obj: Basic object information
  * @width: Line-width in pixels
+ * @has_rgb: true to draw in @rgb instead of the default foreground colour
+ * @rgb: Colour to draw in as 0xRRGGBB used if @has_rgb
  */
 struct scene_obj_box {
 	struct scene_obj obj;
 	uint width;
+	bool has_rgb;
+	u32 rgb;
 };
 
 /**
@@ -790,6 +794,19 @@ int scene_textline(struct scene *scn, const char *name, uint id, uint max_chars,
 int scene_box(struct scene *scn, const char *name, uint id, uint width,
 	      struct scene_obj_box **boxp);
 
+/**
+ * scene_box_set_rgb() - Set the colour of a box
+ *
+ * A box with a bounding box no taller than its line-width is a solid line, so
+ * this can be used to draw a horizontal rule.
+ *
+ * @scn: Scene to update
+ * @id: ID of box object to update
+ * @rgb: Colour to draw the box in as 0xRRGGBB
+ * Return: 0 if OK, -ENOENT if @id is not a box
+ */
+int scene_box_set_rgb(struct scene *scn, uint id, u32 rgb);
+
 /**
  *  scene_texted() - create a text editor
  *

-- 
2.55.0

