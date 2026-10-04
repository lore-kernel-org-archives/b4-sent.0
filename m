From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:47:24 +0200
Subject: [PATCH v2] video: console: clear rows stride-aware in set_row
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-framebuffer-stride-fix-v2-1-923af6708491@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NSw6CMBRFt2I69pm+puHjyH0YBv28So1Q0haiI
 ezdghtweG7uvWdliaKnxK6nlUVafPJhLCDOJ2Z6NT4IvC3MBBcVci5AS3BRDaRn5yhCytFbAuf
 fUNUGbW3bBqllZT9FKvHxfe9+nGb9JJP3w73R+5RD/BzyBffeP54FAUGqRraNxEpzvE0x5DAOy
 r8uJgys27btC6jm23vZAAAA
X-Change-ID: 20261002-b4-framebuffer-stride-fix-67c1d7d981e9
To: u-boot@lists.u-boot-project.org
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791143248; l=3984;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=HwbrIMmhKvc7bUtP00b6jwcxMskb4BSruE7UiQCRNDI=;
 b=z3CzFSZNnK/Vp+PMAMMjRtTIdi1qJmIY5/y3j2QzoS2ballZ2JRhxnXPVFoPyrwVzrsX9+/Ai
 Bgotq5JW9xtABh5BAeputI0u38mg3bq84wFS1+Jmxv1/6JcjVjwrSKL
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_set_row() and console_set_row_2() clear a row with a single
contiguous fill assuming line_length == xsize * pbytes. A stride-padded
framebuffer inherited from a prior boot stage (e.g. via
simple-framebuffer) breaks that assumption leaving stale pixels after
scroll.

Use video_fill_part() which already steps per scanline by
line_length.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Found while testing the scrollback viewer against a stride-padded
splash framebuffer inherited via simple-framebuffer.

console_set_row() and console_set_row_2() clear rows assuming
line_length == xsize * pbytes. Fix them to step per scanline by
line_length instead.
---
Changes in v2:
- Switch to video_fill_part() which already handles stride
- Link to v1: https://patch.msgid.link/20261002-b4-framebuffer-stride-fix-v1-1-4a8498416b01@protonmail.com

To: u-boot@lists.u-boot-project.org
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>
Cc: Simon Glass <sjg@chromium.org>
Cc: Tom Rini <trini@konsulko.com>
Cc: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/video/console_normal.c | 26 +++-----------------------
 drivers/video/console_rotate.c | 23 ++++-------------------
 2 files changed, 7 insertions(+), 42 deletions(-)

diff --git a/drivers/video/console_normal.c b/drivers/video/console_normal.c
index 07db613ac53..9a3d08aad02 100644
--- a/drivers/video/console_normal.c
+++ b/drivers/video/console_normal.c
@@ -18,30 +18,10 @@ static int console_set_row(struct udevice *dev, uint row, int clr)
 	struct video_priv *vid_priv = dev_get_uclass_priv(dev->parent);
 	struct console_simple_priv *priv = dev_get_priv(dev);
 	struct video_fontdata *fontdata = priv->fontdata;
-	void *line, *dst, *end;
-	int pixels = fontdata->height * vid_priv->xsize;
-	int ret;
-	int i;
-	int pbytes;
 
-	ret = check_bpix_support(vid_priv->bpix);
-	if (ret)
-		return ret;
-
-	line = vid_priv->fb + row * fontdata->height * vid_priv->line_length;
-	dst = line;
-	pbytes = VNBYTES(vid_priv->bpix);
-	for (i = 0; i < pixels; i++)
-		fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
-	end = dst;
-
-	video_damage(dev->parent,
-		     0,
-		     fontdata->height * row,
-		     vid_priv->xsize,
-		     fontdata->height);
-
-	return 0;
+	return video_fill_part(dev->parent, 0, row * fontdata->height,
+				vid_priv->xsize,
+				(row + 1) * fontdata->height, clr);
 }
 
 static int console_move_rows(struct udevice *dev, uint rowdst,
diff --git a/drivers/video/console_rotate.c b/drivers/video/console_rotate.c
index 886b25dcfaf..6feacd43b6c 100644
--- a/drivers/video/console_rotate.c
+++ b/drivers/video/console_rotate.c
@@ -112,26 +112,11 @@ static int console_set_row_2(struct udevice *dev, uint row, int clr)
 	struct video_priv *vid_priv = dev_get_uclass_priv(dev->parent);
 	struct console_simple_priv *priv = dev_get_priv(dev);
 	struct video_fontdata *fontdata = priv->fontdata;
-	void *start, *line, *dst, *end;
-	int pixels = fontdata->height * vid_priv->xsize;
-	int i;
-	int pbytes = VNBYTES(vid_priv->bpix);
-
-	start = vid_priv->fb + vid_priv->ysize * vid_priv->line_length -
-		(row + 1) * fontdata->height * vid_priv->line_length;
-	line = start;
-	dst = line;
-	for (i = 0; i < pixels; i++)
-		fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
-	end = dst;
 
-	video_damage(dev->parent,
-		     0,
-		     vid_priv->ysize - (row + 1) * fontdata->height,
-		     vid_priv->xsize,
-		     fontdata->height);
-
-	return 0;
+	return video_fill_part(dev->parent, 0,
+				vid_priv->ysize - (row + 1) * fontdata->height,
+				vid_priv->xsize,
+				vid_priv->ysize - row * fontdata->height, clr);
 }
 
 static int console_move_rows_2(struct udevice *dev, uint rowdst, uint rowsrc,

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-framebuffer-stride-fix-67c1d7d981e9

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

