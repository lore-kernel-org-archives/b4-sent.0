From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 16:39:09 +0000
Subject: [PATCH] vt: allocate the screen buffers with kvzalloc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-vt-kvzalloc-v1-1-5e5f59b37f61@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBBA0avIrDXREspVxKJqMAjS0ghxd8XyL
 f6/wKIhtFAEFxh0ZGmZPXgYgO7V3CGjxhtEJFLOec7cxkZ3qmlaNMNURLKRmUpkDL5YDbZ0fLe
 y+m33ekC9vQu47wcFkD5UbwAAAA==
X-Change-ID: 20261119-vt-kvzalloc-e6208d87a483
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Nicolas Pitre <nico@fluxnic.net>, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795106349; l=4415;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=83ftxt1Y3R8cULoF8CrapPrLjB8/VCL6Q7syy8fYTqQ=;
 b=cb/1C90W46uJY1W+sHyRgr96rWWZcFm89KMxF4+WT3nuPzc3Bn/lRrxjcGeme3U9TjrPR2mcf
 so5JjuVRguhCihuRTgAKezivDTuv0ms44KLgo3WYGGskr49hILlsjeI
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A console's screen buffer grows with the display: 480x135 (3840x2160
with the 8x16 font) needs 129600 bytes, an order-5 kzalloc() that can
fail when memory is fragmented. On an Orange Pi Zero2 (1 GiB) under
memory load, plugging in an HDMI monitor gave an order:5 page
allocation failure in vc_do_resize() from fbcon_startup().

Commit 9a98e7a80f95 ("vt: don't use kmalloc() for the unicode screen
buffer") moved the unicode buffer to vmalloc for this reason; let the
screen buffer and its alternate screen copy fall back to vmalloc too.
Nothing needs them physically contiguous. con_init() keeps its
GFP_NOWAIT kzalloc(), which kvfree() also handles.

Cc: Nicolas Pitre <nico@fluxnic.net>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi Zero2 (H616) on 7.3.4 with KASAN and the order-5
kmalloc failed by fault injection: 20 of 20 fbcon rebinds fell back to
vmalloc and kept the screen contents (all 20 fail without the patch).

Developed with Claude (Anthropic), which wrote the code and the commit
message. I reviewed it.
---
 drivers/tty/vt/vt.c | 20 ++++++++++----------
 1 file changed, 10 insertions(+), 10 deletions(-)

diff --git a/drivers/tty/vt/vt.c b/drivers/tty/vt/vt.c
index 7dbc0072a40a..cdc862be4d6f 100644
--- a/drivers/tty/vt/vt.c
+++ b/drivers/tty/vt/vt.c
@@ -1232,7 +1232,7 @@ int vc_allocate(unsigned int currcons)	/* return 0 on success */
 	    vc->vc_screenbuf_size > KMALLOC_MAX_SIZE || !vc->vc_screenbuf_size)
 		goto err_free;
 	err = -ENOMEM;
-	vc->vc_screenbuf = kzalloc(vc->vc_screenbuf_size, GFP_KERNEL);
+	vc->vc_screenbuf = kvzalloc(vc->vc_screenbuf_size, GFP_KERNEL);
 	if (!vc->vc_screenbuf)
 		goto err_free;
 
@@ -1324,14 +1324,14 @@ static int vc_do_resize(struct tty_struct *tty, struct vc_data *vc,
 
 	if (new_screen_size > KMALLOC_MAX_SIZE || !new_screen_size)
 		return -EINVAL;
-	newscreen = kzalloc(new_screen_size, GFP_USER);
+	newscreen = kvzalloc(new_screen_size, GFP_USER);
 	if (!newscreen)
 		return -ENOMEM;
 
 	if (vc->vc_uni_lines) {
 		new_uniscr = vc_uniscr_alloc(new_cols, new_rows);
 		if (!new_uniscr) {
-			kfree(newscreen);
+			kvfree(newscreen);
 			return -ENOMEM;
 		}
 	}
@@ -1344,7 +1344,7 @@ static int vc_do_resize(struct tty_struct *tty, struct vc_data *vc,
 
 	err = resize_screen(vc, new_cols, new_rows, from_user);
 	if (err) {
-		kfree(newscreen);
+		kvfree(newscreen);
 		vc_uniscr_free(new_uniscr);
 		return err;
 	}
@@ -1402,7 +1402,7 @@ static int vc_do_resize(struct tty_struct *tty, struct vc_data *vc,
 	vc->vc_screenbuf = newscreen;
 	vc->vc_screenbuf_size = new_screen_size;
 	set_origin(vc);
-	kfree(oldscreen);
+	kvfree(oldscreen);
 
 	/* do part of a reset_terminal() */
 	vc->vc_top = 0;
@@ -1483,10 +1483,10 @@ struct vc_data *vc_deallocate(unsigned int currcons)
 		con_free_unimap(vc);
 		put_pid(vc->vt_pid);
 		vc_uniscr_set(vc, NULL);
-		kfree(vc->vc_screenbuf);
+		kvfree(vc->vc_screenbuf);
 		vc_cons[currcons].d = NULL;
 		if (vc->vc_saved_screen != NULL) {
-			kfree(vc->vc_saved_screen);
+			kvfree(vc->vc_saved_screen);
 			vc->vc_saved_screen = NULL;
 		}
 		vc_uniscr_free(vc->vc_saved_uni_lines);
@@ -2032,7 +2032,7 @@ static void enter_alt_screen(struct vc_data *vc)
 
 	if (vc->vc_saved_screen != NULL)
 		return; /* Already inside an alt-screen */
-	vc->vc_saved_screen = kmemdup((u16 *)vc->vc_origin, size, GFP_KERNEL);
+	vc->vc_saved_screen = kvmemdup((u16 *)vc->vc_origin, size, GFP_KERNEL);
 	if (vc->vc_saved_screen == NULL)
 		return;
 	vc->vc_saved_uni_lines = vc->vc_uni_lines;
@@ -2082,7 +2082,7 @@ static void leave_alt_screen(struct vc_data *vc)
 	/* Update the entire screen */
 	if (con_should_update(vc))
 		do_update_region(vc, vc->vc_origin, vc->vc_screenbuf_size / 2);
-	kfree(vc->vc_saved_screen);
+	kvfree(vc->vc_saved_screen);
 	vc->vc_saved_screen = NULL;
 }
 
@@ -2400,7 +2400,7 @@ static void reset_terminal(struct vc_data *vc, int do_clear)
 	vc->vc_decim		= 0;
 
 	if (vc->vc_saved_screen != NULL) {
-		kfree(vc->vc_saved_screen);
+		kvfree(vc->vc_saved_screen);
 		vc->vc_saved_screen = NULL;
 		vc_uniscr_free(vc->vc_saved_uni_lines);
 		vc->vc_saved_uni_lines = NULL;

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261119-vt-kvzalloc-e6208d87a483

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

