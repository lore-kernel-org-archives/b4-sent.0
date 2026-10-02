From: Petr Hodina <petr.hodina@protonmail.com>
Date: Fri, 02 Oct 2026 23:19:31 +0200
Subject: [PATCH] video: console: clear rows stride-aware in set_row
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261002-b4-framebuffer-stride-fix-v1-1-4a8498416b01@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQrCMBCE4auUfXYhCdJaryI+NMlEV7DKbitC6
 d2N7eM3MP9CBhUYnZuFFB8xeY0V/tBQug/jDSy5moILrXcucDxy0eGJOJcCZZtUMrjIl9su+dz
 l/uTRU/2/FXXe2pfrbpvjA2n6B2ldfz9m7jp9AAAA
X-Change-ID: 20261002-b4-framebuffer-stride-fix-67c1d7d981e9
To: u-boot@lists.u-boot-project.org
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>, 
 Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790975978; l=3436;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=EuFkYrM/XuLNQZtyrH4tPGeKWmdV6xYzb0sMMzvRHp4=;
 b=AUDj6+1RHnfXiTgpPjroRS3k4bb2e0ojBfqGfytiRUPzh3OyS+uHkf96gd9mRR/0UHAlg0hWF
 TA0y4/mXxGLADUbLauac0kBzNgxnXv/lXZPGxp8MwVth68KwnnG9uS+
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

console_set_row() and console_set_row_2() clear a row with a single
contiguous fill assuming line_length == xsize * pbytes. A stride-padded
framebuffer inherited from a prior boot stage (e.g. via
simple-framebuffer) breaks that assumption leaving stale pixels after
scroll.

Step per scanline by line_length instead matching the glyph renderer.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Found while testing the scrollback viewer against a stride-padded
splash framebuffer inherited via simple-framebuffer.

console_set_row() and console_set_row_2() clear rows assuming
line_length == xsize * pbytes. Fix them to step per scanline by
line_length instead.
---
 drivers/video/console_normal.c | 16 +++++++++-------
 drivers/video/console_rotate.c | 16 +++++++++-------
 2 files changed, 18 insertions(+), 14 deletions(-)

diff --git a/drivers/video/console_normal.c b/drivers/video/console_normal.c
index 07db613ac53..f86cf24349d 100644
--- a/drivers/video/console_normal.c
+++ b/drivers/video/console_normal.c
@@ -18,10 +18,9 @@ static int console_set_row(struct udevice *dev, uint row, int clr)
 	struct video_priv *vid_priv = dev_get_uclass_priv(dev->parent);
 	struct console_simple_priv *priv = dev_get_priv(dev);
 	struct video_fontdata *fontdata = priv->fontdata;
-	void *line, *dst, *end;
-	int pixels = fontdata->height * vid_priv->xsize;
+	void *line, *dst;
 	int ret;
-	int i;
+	int i, j;
 	int pbytes;
 
 	ret = check_bpix_support(vid_priv->bpix);
@@ -29,11 +28,14 @@ static int console_set_row(struct udevice *dev, uint row, int clr)
 		return ret;
 
 	line = vid_priv->fb + row * fontdata->height * vid_priv->line_length;
-	dst = line;
 	pbytes = VNBYTES(vid_priv->bpix);
-	for (i = 0; i < pixels; i++)
-		fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
-	end = dst;
+
+	for (j = 0; j < fontdata->height; j++) {
+		dst = line;
+		for (i = 0; i < vid_priv->xsize; i++)
+			fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
+		line += vid_priv->line_length;
+	}
 
 	video_damage(dev->parent,
 		     0,
diff --git a/drivers/video/console_rotate.c b/drivers/video/console_rotate.c
index 886b25dcfaf..4423aded25a 100644
--- a/drivers/video/console_rotate.c
+++ b/drivers/video/console_rotate.c
@@ -112,18 +112,20 @@ static int console_set_row_2(struct udevice *dev, uint row, int clr)
 	struct video_priv *vid_priv = dev_get_uclass_priv(dev->parent);
 	struct console_simple_priv *priv = dev_get_priv(dev);
 	struct video_fontdata *fontdata = priv->fontdata;
-	void *start, *line, *dst, *end;
-	int pixels = fontdata->height * vid_priv->xsize;
-	int i;
+	void *start, *line, *dst;
+	int i, j;
 	int pbytes = VNBYTES(vid_priv->bpix);
 
 	start = vid_priv->fb + vid_priv->ysize * vid_priv->line_length -
 		(row + 1) * fontdata->height * vid_priv->line_length;
 	line = start;
-	dst = line;
-	for (i = 0; i < pixels; i++)
-		fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
-	end = dst;
+
+	for (j = 0; j < fontdata->height; j++) {
+		dst = line;
+		for (i = 0; i < vid_priv->xsize; i++)
+			fill_pixel_and_goto_next(&dst, clr, pbytes, pbytes);
+		line += vid_priv->line_length;
+	}
 
 	video_damage(dev->parent,
 		     0,

---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-framebuffer-stride-fix-67c1d7d981e9

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

