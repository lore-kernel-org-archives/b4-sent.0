From: Weidong Wang <weidongw@illinois.edu>
Date: Thu, 12 Nov 2026 00:37:21 -0600
Subject: [PATCH] fbdev: cirrusfb: Fix overflow in the video memory check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-c4-n053-v1-1-1e45ef75304c@illinois.edu>
X-B4-Tracking: v=1; b=H4sIAKBe9WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0Mj3WQT3TwDU2NdI3NLi0SLFAsDI8tEJaDqgqLUtMwKsEnRsRB+cWl
 SVmpyCUi7Um0tABkLWDxrAAAA
X-Change-ID: 20261112-c4-n053-2798a8d8029a
To: Helge Deller <deller@gmx.de>
Cc: linux-fbdev@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Zijie Zhao <zijie4@illinois.edu>, Weidong Wang <weidongw@illinois.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794465443; l=3801;
 i=weidongw@illinois.edu; s=20261108; h=from:subject:message-id;
 bh=xRG3ca+6pdSvKSwRB+UJidN1R6P4hGws1bA3L4XBzg8=;
 b=jteVozVB8mMHGt6fDH8LV0GIynCc1mAKqvbMM1Ch7dewLc38Z7nammT+XsN2loZ789CGrNYNN
 uHL1gCPqlspDfsnGqSAf2q/e6pcqiapACSjISMTmVYApJWFxJoDNhs6
X-Developer-Key: i=weidongw@illinois.edu; a=ed25519;
 pk=DR2S1xPEa5sELrWPfOpvUphJQ2VHC+MDc/wJavE/ifg=
X-Endpoint-Received: by B4 Relay for weidongw@illinois.edu/20261108 with auth_id=1449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cirrusfb_check_var() raises xres_virtual to xres and then checks
xres_virtual * yres_virtual against the video memory in 32-bit
arithmetic. fb_set_var() checks the product for overflow, but only for
the values passed in, before the driver raises xres_virtual. A mode with
xres 65536, xres_virtual 640 and yres_virtual 65536 passes that check,
becomes 65536 x 65536 in cirrusfb_check_var(), and the product wraps to
0, so the mode is accepted on a 4 MiB card with a line length of
65536 bytes. The framebuffer console then draws at offsets far past the
end of the video memory mapping.

Do the multiplication in 64 bits.

Found by an AI code review agent (an LLM-based bug-finding tool
developed by Zijie Zhao and the submitter) and confirmed on an
unmodified kernel, without error injection, on x86_64 under QEMU with
-vga cirrus (GD5446, 4 MiB) and KASAN. FBIOPUT_VSCREENINFO with
xres 65536, yres 128, xres_virtual 640, yres_virtual 65536 at 8 bpp is
accepted as 65536x128, virtual 65536x65536. Booted with
video=cirrusfb:noaccel, fbcon's redraw then faults:

  BUG: unable to handle page fault for address: ffffc90000b00000
  RIP: 0010:cfb_imageblit+0xbc6/0x1970
   soft_cursor+0x5eb/0xcd0
   bit_cursor+0xb41/0x1910
   hide_cursor+0x6e/0x1d0

With acceleration enabled, text on the GD5446 is drawn with the blitter,
which QEMU bounds, so the mode is accepted but nothing faults; drawing
goes through the CPU with noaccel and on the Laguna chips, which always
run without acceleration. Asked for without the wrap, as 65536x128 with
a 65536x128 virtual resolution (8 MiB), the mode is rejected, as it
should be.

With this patch the mode is rejected with "virtual resolution too high
to fit into video memory", and 1024x768x8 is still accepted.

The reproducer, fix and changelog were drafted with AI assistance
(Claude), then reviewed and tested by the submitter.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Cc: stable@vger.kernel.org
Cc: Zijie Zhao <zijie4@illinois.edu>
Signed-off-by: Weidong Wang <weidongw@illinois.edu>
---
Tested on v7.4-rc1 (05441d697f7f), x86_64, KASAN, QEMU/KVM -vga cirrus
(GD5446, 4 MiB). FBIOPUT_VSCREENINFO at 8 bpp:

               65536x128, virtual 640x65536    65536x128, virtual 65536x128
                                               (control)
  unpatched    accepted as virtual 65536x65536; rejected
               with noaccel, fbcon faults in
               cfb_imageblit, panic
  patched      rejected                        rejected

1024x768x8 is accepted on both. With acceleration on, the GD5446 draws
text with the blitter and nothing faults; the overflow is the same.
No KASAN/UBSAN reports on the patched kernel; checkpatch clean. The
code is unchanged in mainline and linux-next (next-20261111).

The reproducer is not attached (AI-found issue, see security-bugs.rst)
and can be shared on request.
---
 drivers/video/fbdev/cirrusfb.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/fbdev/cirrusfb.c b/drivers/video/fbdev/cirrusfb.c
index 2693b5cc0..0fa809127 100644
--- a/drivers/video/fbdev/cirrusfb.c
+++ b/drivers/video/fbdev/cirrusfb.c
@@ -588,7 +588,7 @@ static int cirrusfb_check_var(struct fb_var_screeninfo *var,
 	if (var->yres_virtual < var->yres)
 		var->yres_virtual = var->yres;
 
-	if (var->xres_virtual * var->yres_virtual > pixels) {
+	if ((u64)var->xres_virtual * var->yres_virtual > pixels) {
 		dev_err(info->device, "mode %dx%dx%d rejected... "
 		      "virtual resolution too high to fit into video memory!\n",
 			var->xres_virtual, var->yres_virtual,

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261112-c4-n053-2798a8d8029a

Best regards,
--  
Weidong Wang <weidongw@illinois.edu>

