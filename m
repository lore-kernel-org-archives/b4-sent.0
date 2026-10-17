From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:27 +0200
Subject: [PATCH 11/14] expo: Allow the highlight colours to be set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-11-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=4295;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=ARVtdUmZv2Sp+/cn4Q8naNycjEBWyYRaqFWxvhaz3wE=;
 b=RDZBClmXUaFpTcFEondqte0hHbR7PjejuySVpvMmInlzkZoBRuR+Kqrt3qBKI8n9oi7saqBBV
 n0dNiFgAcngAMJhcefLUErTc4In2JICQnhWAYRFxwMdWtkj69KyJIJ9
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The selected menu item is drawn in reverse video. Add
expo_set_highlight_rgb() to choose the colour of the highlight bar and of
the text on it instead.

The video device's colours are put back after each item is drawn.

Also add a small helper to convert 0xRRGGBB to a display colour and use it
for boxes as well.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/expo.c    |  7 +++++++
 boot/scene.c   | 19 ++++++++++++++++---
 include/expo.h | 19 +++++++++++++++++++
 3 files changed, 42 insertions(+), 3 deletions(-)

diff --git a/boot/expo.c b/boot/expo.c
index fb67a80a29f..8e05f98f2ad 100644
--- a/boot/expo.c
+++ b/boot/expo.c
@@ -265,6 +265,13 @@ void expo_set_bg_rgb(struct expo *exp, u32 rgb)
 	exp->bg_rgb = rgb;
 }
 
+void expo_set_highlight_rgb(struct expo *exp, u32 bg_rgb, u32 fg_rgb)
+{
+	exp->has_hl_rgb = true;
+	exp->hl_bg_rgb = bg_rgb;
+	exp->hl_fg_rgb = fg_rgb;
+}
+
 int expo_send_key(struct expo *exp, int key)
 {
 	struct scene *scn = NULL;
diff --git a/boot/scene.c b/boot/scene.c
index 3f63c84a331..06f46a3c7c2 100644
--- a/boot/scene.c
+++ b/boot/scene.c
@@ -541,6 +541,11 @@ static void scene_render_background(struct scene_obj *obj, bool box_only,
 	}
 }
 
+static u32 rgb_to_colour(struct video_priv *vid_priv, u32 rgb)
+{
+	return video_rgb_to_colour(vid_priv, rgb >> 16, rgb >> 8, rgb);
+}
+
 static int scene_txt_render(struct expo *exp, struct udevice *dev,
 			    struct udevice *cons, struct scene_obj *obj,
 			    struct scene_txt_generic *gen, int x, int y,
@@ -584,7 +589,16 @@ static int scene_txt_render(struct expo *exp, struct udevice *dev,
 		int inset;
 
 		inset = exp->popup ? menu_inset : 0;
-		vidconsole_push_colour(cons, fore, back, &old);
+		if (exp->has_hl_rgb) {
+			old.colour_fg = vid_priv->colour_fg;
+			old.colour_bg = vid_priv->colour_bg;
+			vid_priv->colour_fg = rgb_to_colour(vid_priv,
+							    exp->hl_fg_rgb);
+			vid_priv->colour_bg = rgb_to_colour(vid_priv,
+							    exp->hl_bg_rgb);
+		} else {
+			vidconsole_push_colour(cons, fore, back, &old);
+		}
 		video_fill_part(dev, x - inset, y,
 				obj->bbox.x1, obj->bbox.y1,
 				vid_priv->colour_bg);
@@ -712,8 +726,7 @@ static int scene_obj_render(struct scene_obj *obj, bool text_mode)
 		u32 colour = vid_priv->colour_fg;
 
 		if (box->has_rgb)
-			colour = video_rgb_to_colour(vid_priv, box->rgb >> 16,
-						     box->rgb >> 8, box->rgb);
+			colour = rgb_to_colour(vid_priv, box->rgb);
 		video_draw_box(dev, obj->bbox.x0, obj->bbox.y0, obj->bbox.x1,
 			       obj->bbox.y1, box->width, colour);
 		break;
diff --git a/include/expo.h b/include/expo.h
index 995c57e7bad..258b9b66993 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -110,6 +110,9 @@ struct expo_theme {
  * @show_highlight: show a highlight bar on the selected menu item
  * @has_bg_rgb: true to use @bg_rgb as the background instead of black or white
  * @bg_rgb: Background colour as 0xRRGGBB used if @has_bg_rgb
+ * @has_hl_rgb: true to use @hl_bg_rgb and @hl_fg_rgb for the highlight bar
+ * @hl_bg_rgb: Colour of the highlight bar as 0xRRGGBB
+ * @hl_fg_rgb: Colour of the text on the highlight bar as 0xRRGGBB
  * @priv: Private data for the controller
  * @done: Indicates that a cedit session is complete and the user has quit
  * @save: Indicates that cedit data should be saved, rather than discarded
@@ -130,6 +133,9 @@ struct expo {
 	bool show_highlight;
 	bool has_bg_rgb;
 	u32 bg_rgb;
+	bool has_hl_rgb;
+	u32 hl_bg_rgb;
+	u32 hl_fg_rgb;
 	void *priv;
 	bool done;
 	bool save;
@@ -655,6 +661,19 @@ void expo_set_text_mode(struct expo *exp, bool text_mode);
  */
 void expo_set_bg_rgb(struct expo *exp, u32 rgb);
 
+/**
+ * expo_set_highlight_rgb() - Set the colours of the highlight bar
+ *
+ * By default the selected menu item is shown in reverse video. This selects
+ * the colours to use instead. It only has an effect when @exp->show_highlight
+ * is set.
+ *
+ * @exp: Expo to update
+ * @bg_rgb: Colour of the bar as 0xRRGGBB
+ * @fg_rgb: Colour of the text on the bar as 0xRRGGBB
+ */
+void expo_set_highlight_rgb(struct expo *exp, u32 bg_rgb, u32 fg_rgb);
+
 /**
  * scene_new() - create a new scene in a expo
  *

-- 
2.55.0

