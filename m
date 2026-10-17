From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:23 +0200
Subject: [PATCH 07/14] expo: Allow the background colour to be set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-7-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=3612;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=/5HgJCOGqNFJiafhkd9vG8WjoIN4LkQs0IKPtMQSRlA=;
 b=8NcSkgFAHMavsqe8g8whVn9asAQ6BI0L075nXfqQjDjfvkpIzM6FmL9lc5ZpWKLjyf8H+vEQg
 d5g6HpWWupGAMu3dtWndwsialltS5k3qenljwE1UqBnJN3eGJVAZKOU
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Expo clears the display to black or white depending on the video
device's white_on_black setting.

Add expo_set_bg_rgb() to use another colour instead. The colour is also set
as the background of text while the expo is rendered.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 boot/expo.c    | 42 +++++++++++++++++++++++++++++++++---------
 include/expo.h | 15 +++++++++++++++
 2 files changed, 48 insertions(+), 9 deletions(-)

diff --git a/boot/expo.c b/boot/expo.c
index 94413acd381..fb67a80a29f 100644
--- a/boot/expo.c
+++ b/boot/expo.c
@@ -215,30 +215,54 @@ int expo_render(struct expo *exp)
 {
 	struct udevice *dev = exp->display;
 	struct video_priv *vid_priv = dev_get_uclass_priv(dev);
+	u32 old_bg = vid_priv->colour_bg;
 	struct scene *scn = NULL;
 	enum colour_idx back;
 	u32 colour;
 	int ret;
 
-	back = vid_priv->white_on_black ? VID_BLACK : VID_WHITE;
-	colour = video_index_to_colour(vid_priv, back);
+	if (exp->has_bg_rgb) {
+		colour = video_rgb_to_colour(vid_priv, exp->bg_rgb >> 16,
+					     exp->bg_rgb >> 8, exp->bg_rgb);
+		/* text is drawn on this colour too, not on black or white */
+		vid_priv->colour_bg = colour;
+	} else {
+		back = vid_priv->white_on_black ? VID_BLACK : VID_WHITE;
+		colour = video_index_to_colour(vid_priv, back);
+	}
 	ret = video_fill(dev, colour);
-	if (ret)
-		return log_msg_ret("fill", ret);
+	if (ret) {
+		ret = log_msg_ret("fill", ret);
+		goto done;
+	}
 
 	if (exp->scene_id) {
 		scn = expo_lookup_scene_id(exp, exp->scene_id);
-		if (!scn)
-			return log_msg_ret("scn", -ENOENT);
+		if (!scn) {
+			ret = log_msg_ret("scn", -ENOENT);
+			goto done;
+		}
 
 		ret = scene_render(scn);
-		if (ret)
-			return log_msg_ret("ren", ret);
+		if (ret) {
+			ret = log_msg_ret("ren", ret);
+			goto done;
+		}
 	}
 
 	video_sync(dev, true);
+	ret = scn ? 0 : -ECHILD;
 
-	return scn ? 0 : -ECHILD;
+done:
+	vid_priv->colour_bg = old_bg;
+
+	return ret;
+}
+
+void expo_set_bg_rgb(struct expo *exp, u32 rgb)
+{
+	exp->has_bg_rgb = true;
+	exp->bg_rgb = rgb;
 }
 
 int expo_send_key(struct expo *exp, int key)
diff --git a/include/expo.h b/include/expo.h
index fe20c68750e..61fec3d52c5 100644
--- a/include/expo.h
+++ b/include/expo.h
@@ -108,6 +108,8 @@ struct expo_theme {
  * @text_mode: true to use text mode for the menu (no vidconsole)
  * @popup: true to use popup menus, instead of showing all items
  * @show_highlight: show a highlight bar on the selected menu item
+ * @has_bg_rgb: true to use @bg_rgb as the background instead of black or white
+ * @bg_rgb: Background colour as 0xRRGGBB used if @has_bg_rgb
  * @priv: Private data for the controller
  * @done: Indicates that a cedit session is complete and the user has quit
  * @save: Indicates that cedit data should be saved, rather than discarded
@@ -126,6 +128,8 @@ struct expo {
 	bool text_mode;
 	bool popup;
 	bool show_highlight;
+	bool has_bg_rgb;
+	u32 bg_rgb;
 	void *priv;
 	bool done;
 	bool save;
@@ -636,6 +640,17 @@ int expo_render(struct expo *exp);
  */
 void expo_set_text_mode(struct expo *exp, bool text_mode);
 
+/**
+ * expo_set_bg_rgb() - Set the background colour of the expo
+ *
+ * By default the display is cleared to black or white depending on the video
+ * device's white_on_black setting. This selects another colour instead
+ *
+ * @exp: Expo to update
+ * @rgb: Background colour as 0xRRGGBB
+ */
+void expo_set_bg_rgb(struct expo *exp, u32 rgb);
+
 /**
  * scene_new() - create a new scene in a expo
  *

-- 
2.55.0

