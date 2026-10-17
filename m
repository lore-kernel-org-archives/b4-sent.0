From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 17 Oct 2026 11:10:22 +0200
Subject: [PATCH 06/14] video: Add video_rgb_to_colour()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261017-b4-expo-colours-v1-6-479ac06e7642@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792228225; l=3390;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=eWA4+RawQU/jqqAiPzdzgGMDEGPyuRCFQ3YH/wzujK4=;
 b=TijiBWOtdzeqgaya0sqgf+QuyoJJlhAf8107hGL+kYHqeuK93D75jM9b/iso5UPLW7Xlluutj
 UL1dEMJm98JCvd4AFmPr8matBmzQAKVwjE5mvcK16mmvivEs8oT+tqx
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

video_index_to_colour() can only produce the sixteen console colours.

Split its pixel format conversion out into video_rgb_to_colour() so that
code which wants an arbitrary colour can get a value matching the
framebuffer format.

Make video_index_to_colour() call it.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/video/video-uclass.c | 27 +++++++++++++--------------
 include/video.h              | 13 +++++++++++++
 2 files changed, 26 insertions(+), 14 deletions(-)

diff --git a/drivers/video/video-uclass.c b/drivers/video/video-uclass.c
index 22183d00d97..cba961ad467 100644
--- a/drivers/video/video-uclass.c
+++ b/drivers/video/video-uclass.c
@@ -333,31 +333,24 @@ static const struct vid_rgb colours[VID_COLOUR_COUNT] = {
 	{ 0x40, 0x40, 0x40 },  /* dark gray */
 };
 
-u32 video_index_to_colour(struct video_priv *priv, enum colour_idx idx)
+u32 video_rgb_to_colour(struct video_priv *priv, u8 r, u8 g, u8 b)
 {
 	switch (priv->bpix) {
 	case VIDEO_BPP16:
 		if (CONFIG_IS_ENABLED(VIDEO_BPP16)) {
-			return ((colours[idx].r >> 3) << 11) |
-			       ((colours[idx].g >> 2) <<  5) |
-			       ((colours[idx].b >> 3) <<  0);
+			return ((r >> 3) << 11) | ((g >> 2) << 5) |
+			       ((b >> 3) << 0);
 		}
 		break;
 	case VIDEO_BPP32:
 		if (CONFIG_IS_ENABLED(VIDEO_BPP32)) {
 			switch (priv->format) {
 			case VIDEO_X2R10G10B10:
-				return (colours[idx].r << 22) |
-				       (colours[idx].g << 12) |
-				       (colours[idx].b <<  2);
+				return (r << 22) | (g << 12) | (b << 2);
 			case VIDEO_RGBA8888:
-				return (colours[idx].r << 24) |
-				       (colours[idx].g << 16) |
-				       (colours[idx].b << 8) | 0xff;
+				return (r << 24) | (g << 16) | (b << 8) | 0xff;
 			default:
-				return (colours[idx].r << 16) |
-				       (colours[idx].g <<  8) |
-				       (colours[idx].b <<  0);
+				return (r << 16) | (g << 8) | (b << 0);
 			}
 		}
 		break;
@@ -369,12 +362,18 @@ u32 video_index_to_colour(struct video_priv *priv, enum colour_idx idx)
 	 * For unknown bit arrangements just support
 	 * black and white.
 	 */
-	if (idx)
+	if (r || g || b)
 		return 0xffffff; /* white */
 
 	return 0x000000; /* black */
 }
 
+u32 video_index_to_colour(struct video_priv *priv, enum colour_idx idx)
+{
+	return video_rgb_to_colour(priv, colours[idx].r, colours[idx].g,
+				   colours[idx].b);
+}
+
 void video_set_default_colors(struct udevice *dev, bool invert)
 {
 	struct video_priv *priv = dev_get_uclass_priv(dev);
diff --git a/include/video.h b/include/video.h
index 8e4c1544e56..72f1dc936c8 100644
--- a/include/video.h
+++ b/include/video.h
@@ -209,8 +209,21 @@ enum colour_idx {
  * @idx		color index (e.g. VID_YELLOW)
  * Return:	color value
  */
+
 u32 video_index_to_colour(struct video_priv *priv, enum colour_idx idx);
 
+/**
+ * video_rgb_to_colour() - convert an RGB value to a pixel's internal format
+ *
+ * @priv	private data of the video device (UCLASS_VIDEO)
+ * @r		red component (0-255)
+ * @g		green component (0-255)
+ * @b		blue component (0-255)
+ * Return:	colour value, suitable for @priv->colour_fg / @priv->colour_bg
+ *		or video_fill()
+ */
+u32 video_rgb_to_colour(struct video_priv *priv, u8 r, u8 g, u8 b);
+
 /**
  * video_reserve() - Reserve frame-buffer memory for video devices
  *

-- 
2.55.0

