From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:19 +0100
Subject: [PATCH v3 2/7] video: console: Parse UTF-8 character sequences
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-2-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=11428; i=j@jannau.net;
 h=from:subject:message-id; bh=ewsT+wUDqoRNP/x/o8zRRofilcQb7Sb+6QUu71JRSGQ=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIvJd3CJME76dYLPXVeJkKThySbXFa61F6glTY+2dS
 tnMmuodpSwMYlwMsmKKLEnaLzsYVtcoxtQ+CIOZw8oEMoSBi1MAJpJux8gwcZehSEtvQ9H7uUnZ
 C3OdH6w9vd7nmNSnZ/Lv+6yX7dilxcgwaeuloI9/Ty6akLNP6+/aq3ur3CMz5PavvzLt9QQZ83X
 1nAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

efi_console / UEFI applications (grub2, sd-boot, ...) pass UTF-8
character sequences to vidconsole which results in wrong glyphs for code
points outside of ASCII. The truetype console expects Unicode code
points and bitmap font based consoles expect code page 437 code points.
To support both convert UTF-8 to UTF-32 and pass Unicode code points in
vidconsole_ops.putc_xy(). These can be used directly in console_truetype
and after conversion to code page 437 in console_{normal,rotate}.

This fixes rendering of international, symbol and box drawing characters
used by UEFI applications.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 drivers/video/console_normal.c      |  6 ++++--
 drivers/video/console_rotate.c      | 16 ++++++++++------
 drivers/video/console_truetype.c    |  8 ++++----
 drivers/video/vidconsole-uclass.c   | 18 +++++++++++++-----
 drivers/video/vidconsole_internal.h | 19 +++++++++++++++++++
 include/video_console.h             | 10 ++++++----
 6 files changed, 56 insertions(+), 21 deletions(-)

diff --git a/drivers/video/console_normal.c b/drivers/video/console_normal.c
index a0231293f3..34ef5a5229 100644
--- a/drivers/video/console_normal.c
+++ b/drivers/video/console_normal.c
@@ -7,6 +7,7 @@
  */
 
 #include <common.h>
+#include <charset.h>
 #include <dm.h>
 #include <video.h>
 #include <video_console.h>
@@ -63,7 +64,7 @@ static int console_move_rows(struct udevice *dev, uint rowdst,
 	return 0;
 }
 
-static int console_putc_xy(struct udevice *dev, uint x_frac, uint y, char ch)
+static int console_putc_xy(struct udevice *dev, uint x_frac, uint y, int cp)
 {
 	struct vidconsole_priv *vc_priv = dev_get_uclass_priv(dev);
 	struct udevice *vid = dev->parent;
@@ -73,8 +74,9 @@ static int console_putc_xy(struct udevice *dev, uint x_frac, uint y, char ch)
 	int pbytes = VNBYTES(vid_priv->bpix);
 	int x, linenum, ret;
 	void *start, *line;
+	u8 ch = console_utf_to_cp437(cp);
 	uchar *pfont = fontdata->video_fontdata +
-			(u8)ch * fontdata->char_pixel_bytes;
+			ch * fontdata->char_pixel_bytes;
 
 	if (x_frac + VID_TO_POS(vc_priv->x_charsize) > vc_priv->xsize_frac)
 		return -EAGAIN;
diff --git a/drivers/video/console_rotate.c b/drivers/video/console_rotate.c
index 65358a1c6e..e4303dfb36 100644
--- a/drivers/video/console_rotate.c
+++ b/drivers/video/console_rotate.c
@@ -7,6 +7,7 @@
  */
 
 #include <common.h>
+#include <charset.h>
 #include <dm.h>
 #include <video.h>
 #include <video_console.h>
@@ -67,7 +68,7 @@ static int console_move_rows_1(struct udevice *dev, uint rowdst, uint rowsrc,
 	return 0;
 }
 
-static int console_putc_xy_1(struct udevice *dev, uint x_frac, uint y, char ch)
+static int console_putc_xy_1(struct udevice *dev, uint x_frac, uint y, int cp)
 {
 	struct vidconsole_priv *vc_priv = dev_get_uclass_priv(dev);
 	struct udevice *vid = dev->parent;
@@ -77,8 +78,9 @@ static int console_putc_xy_1(struct udevice *dev, uint x_frac, uint y, char ch)
 	int pbytes = VNBYTES(vid_priv->bpix);
 	int x, linenum, ret;
 	void *start, *line;
+	u8 ch = console_utf_to_cp437(cp);
 	uchar *pfont = fontdata->video_fontdata +
-			(u8)ch * fontdata->char_pixel_bytes;
+			ch * fontdata->char_pixel_bytes;
 
 	if (x_frac + VID_TO_POS(vc_priv->x_charsize) > vc_priv->xsize_frac)
 		return -EAGAIN;
@@ -145,7 +147,7 @@ static int console_move_rows_2(struct udevice *dev, uint rowdst, uint rowsrc,
 	return 0;
 }
 
-static int console_putc_xy_2(struct udevice *dev, uint x_frac, uint y, char ch)
+static int console_putc_xy_2(struct udevice *dev, uint x_frac, uint y, int cp)
 {
 	struct vidconsole_priv *vc_priv = dev_get_uclass_priv(dev);
 	struct udevice *vid = dev->parent;
@@ -155,8 +157,9 @@ static int console_putc_xy_2(struct udevice *dev, uint x_frac, uint y, char ch)
 	int pbytes = VNBYTES(vid_priv->bpix);
 	int linenum, x, ret;
 	void *start, *line;
+	u8 ch = console_utf_to_cp437(cp);
 	uchar *pfont = fontdata->video_fontdata +
-			(u8)ch * fontdata->char_pixel_bytes;
+			ch * fontdata->char_pixel_bytes;
 
 	if (x_frac + VID_TO_POS(vc_priv->x_charsize) > vc_priv->xsize_frac)
 		return -EAGAIN;
@@ -227,7 +230,7 @@ static int console_move_rows_3(struct udevice *dev, uint rowdst, uint rowsrc,
 	return 0;
 }
 
-static int console_putc_xy_3(struct udevice *dev, uint x_frac, uint y, char ch)
+static int console_putc_xy_3(struct udevice *dev, uint x_frac, uint y, int cp)
 {
 	struct vidconsole_priv *vc_priv = dev_get_uclass_priv(dev);
 	struct udevice *vid = dev->parent;
@@ -237,8 +240,9 @@ static int console_putc_xy_3(struct udevice *dev, uint x_frac, uint y, char ch)
 	int pbytes = VNBYTES(vid_priv->bpix);
 	int linenum, x, ret;
 	void *start, *line;
+	u8 ch = console_utf_to_cp437(cp);
 	uchar *pfont = fontdata->video_fontdata +
-			(u8)ch * fontdata->char_pixel_bytes;
+			ch * fontdata->char_pixel_bytes;
 
 	if (x_frac + VID_TO_POS(vc_priv->x_charsize) > vc_priv->xsize_frac)
 		return -EAGAIN;
diff --git a/drivers/video/console_truetype.c b/drivers/video/console_truetype.c
index 14fb81e956..bc3ec1c31f 100644
--- a/drivers/video/console_truetype.c
+++ b/drivers/video/console_truetype.c
@@ -262,7 +262,7 @@ static int console_truetype_move_rows(struct udevice *dev, uint rowdst,
 }
 
 static int console_truetype_putc_xy(struct udevice *dev, uint x, uint y,
-				    char ch)
+				    int cp)
 {
 	struct vidconsole_priv *vc_priv = dev_get_uclass_priv(dev);
 	struct udevice *vid = dev->parent;
@@ -281,7 +281,7 @@ static int console_truetype_putc_xy(struct udevice *dev, uint x, uint y,
 	int row, ret;
 
 	/* First get some basic metrics about this character */
-	stbtt_GetCodepointHMetrics(font, ch, &advance, &lsb);
+	stbtt_GetCodepointHMetrics(font, cp, &advance, &lsb);
 
 	/*
 	 * First out our current X position in fractional pixels. If we wrote
@@ -290,7 +290,7 @@ static int console_truetype_putc_xy(struct udevice *dev, uint x, uint y,
 	xpos = frac(VID_TO_PIXEL((double)x));
 	if (vc_priv->last_ch) {
 		xpos += met->scale * stbtt_GetCodepointKernAdvance(font,
-							vc_priv->last_ch, ch);
+							vc_priv->last_ch, cp);
 	}
 
 	/*
@@ -320,7 +320,7 @@ static int console_truetype_putc_xy(struct udevice *dev, uint x, uint y,
 	 * return NULL;
 	 */
 	data = stbtt_GetCodepointBitmapSubpixel(font, met->scale, met->scale,
-						x_shift, 0, ch, &width, &height,
+						x_shift, 0, cp, &width, &height,
 						&xoff, &yoff);
 	if (!data)
 		return width_frac;
diff --git a/drivers/video/vidconsole-uclass.c b/drivers/video/vidconsole-uclass.c
index 22d55df71f..5f89f6a521 100644
--- a/drivers/video/vidconsole-uclass.c
+++ b/drivers/video/vidconsole-uclass.c
@@ -11,6 +11,7 @@
 
 #include <common.h>
 #include <abuf.h>
+#include <charset.h>
 #include <command.h>
 #include <console.h>
 #include <log.h>
@@ -20,7 +21,7 @@
 #include <video_font.h>		/* Bitmap font for code page 437 */
 #include <linux/ctype.h>
 
-int vidconsole_putc_xy(struct udevice *dev, uint x, uint y, char ch)
+int vidconsole_putc_xy(struct udevice *dev, uint x, uint y, int ch)
 {
 	struct vidconsole_ops *ops = vidconsole_get_ops(dev);
 
@@ -426,8 +427,8 @@ error:
 	priv->escape = 0;
 }
 
-/* Put that actual character on the screen (using the CP437 code page). */
-static int vidconsole_output_glyph(struct udevice *dev, char ch)
+/* Put that actual character on the screen (using the UTF-32 code points). */
+static int vidconsole_output_glyph(struct udevice *dev, int ch)
 {
 	struct vidconsole_priv *priv = dev_get_uclass_priv(dev);
 	int ret;
@@ -455,7 +456,7 @@ static int vidconsole_output_glyph(struct udevice *dev, char ch)
 int vidconsole_put_char(struct udevice *dev, char ch)
 {
 	struct vidconsole_priv *priv = dev_get_uclass_priv(dev);
-	int ret;
+	int cp, ret;
 
 	if (priv->escape) {
 		vidconsole_escape_char(dev, ch);
@@ -489,7 +490,14 @@ int vidconsole_put_char(struct udevice *dev, char ch)
 		priv->last_ch = 0;
 		break;
 	default:
-		ret = vidconsole_output_glyph(dev, ch);
+		if (CONFIG_IS_ENABLED(CHARSET)) {
+			cp = utf8_to_utf32_stream(ch, priv->utf8_buf);
+			if (cp == 0)
+				return 0;
+		} else {
+			cp = ch;
+		}
+		ret = vidconsole_output_glyph(dev, cp);
 		if (ret < 0)
 			return ret;
 		break;
diff --git a/drivers/video/vidconsole_internal.h b/drivers/video/vidconsole_internal.h
index 0ec581b266..bb0277ee45 100644
--- a/drivers/video/vidconsole_internal.h
+++ b/drivers/video/vidconsole_internal.h
@@ -6,6 +6,9 @@
  * (C) Copyright 2023 Dzmitry Sankouski <dsankouski@gmail.com>
  */
 
+#include <charset.h>
+#include <config.h>
+
 #define FLIPPED_DIRECTION 1
 #define NORMAL_DIRECTION 0
 
@@ -142,3 +145,19 @@ int console_simple_get_font(struct udevice *dev, int seq, struct vidfont_info *i
  * See details in video_console.h select_font function
  **/
 int console_simple_select_font(struct udevice *dev, const char *name, uint size);
+
+/**
+ * Internal function to convert Unicode code points to code page 437.
+ * Used by video consoles using bitmap fonts.
+ *
+ * @param codepoint	Unicode code point
+ * @returns code page 437 character.
+ */
+static inline u8 console_utf_to_cp437(int codepoint)
+{
+	if (CONFIG_IS_ENABLED(CHARSET)) {
+		utf_to_cp(&codepoint, codepage_437);
+		return codepoint;
+	}
+	return codepoint;
+}
diff --git a/include/video_console.h b/include/video_console.h
index bde67fa9a5..8b5928dc5e 100644
--- a/include/video_console.h
+++ b/include/video_console.h
@@ -43,6 +43,7 @@ enum {
  * @col_saved:		Saved X position, in fractional units (VID_TO_POS(x))
  * @row_saved:		Saved Y position in pixels (0=top)
  * @escape_buf:		Buffer to accumulate escape sequence
+ * @utf8_buf:		Buffer to accumulate UTF-8 byte sequence
  */
 struct vidconsole_priv {
 	struct stdio_dev sdev;
@@ -66,6 +67,7 @@ struct vidconsole_priv {
 	int row_saved;
 	int col_saved;
 	char escape_buf[32];
+	char utf8_buf[5];
 };
 
 /**
@@ -124,12 +126,12 @@ struct vidconsole_ops {
 	 * @x_frac:	Fractional pixel X position (0=left-most pixel) which
 	 *		is the X position multipled by VID_FRAC_DIV.
 	 * @y:		Pixel Y position (0=top-most pixel)
-	 * @ch:		Character to write
+	 * @cp:		UTF-32 code point to write
 	 * @return number of fractional pixels that the cursor should move,
 	 * if all is OK, -EAGAIN if we ran out of space on this line, other -ve
 	 * on error
 	 */
-	int (*putc_xy)(struct udevice *dev, uint x_frac, uint y, char ch);
+	int (*putc_xy)(struct udevice *dev, uint x_frac, uint y, int cp);
 
 	/**
 	 * move_rows() - Move text rows from one place to another
@@ -403,12 +405,12 @@ void vidconsole_pop_colour(struct udevice *dev, struct vidconsole_colour *old);
  * @x_frac:	Fractional pixel X position (0=left-most pixel) which
  *		is the X position multipled by VID_FRAC_DIV.
  * @y:		Pixel Y position (0=top-most pixel)
- * @ch:		Character to write
+ * @cp:		UTF-32 code point to write
  * Return: number of fractional pixels that the cursor should move,
  * if all is OK, -EAGAIN if we ran out of space on this line, other -ve
  * on error
  */
-int vidconsole_putc_xy(struct udevice *dev, uint x, uint y, char ch);
+int vidconsole_putc_xy(struct udevice *dev, uint x, uint y, int cp);
 
 /**
  * vidconsole_move_rows() - Move text rows from one place to another

-- 
2.44.0

