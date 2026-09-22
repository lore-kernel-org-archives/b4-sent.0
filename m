From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:27:15 -0400
Subject: [PATCH 2/3] vt: order console_blanked between blanking and
 unblanking
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-vt-v1-2-71b7990c26c1@vt.edu>
References: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
In-Reply-To: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040439; l=2137;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=kWl2d17xXxJJ8s7vN2eawZUFTwGBKmwR9FBaN+SterI=;
 b=puDUrOD62COIIKtRmhFJsjOVKQExiVWpSnLNaL38LxHzsnr0wLXrLhGLReZv6IpXKzqnU31R5
 BtS4vK8wEvZDCMqRemObqmiOpf4yhBv++LdnAqTOpEznhl1WXEyHGC8
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_blank_screen() records the blanked console in console_blanked with a
plain store, after blank_state and the console state have been updated.
do_unblank_screen() tests console_blanked with a plain load before it
uses that state.

Store it with smp_store_release() and read it with smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/vt.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/tty/vt/vt.c b/drivers/tty/vt/vt.c
index 3abbd6cf9..726402167 100644
--- a/drivers/tty/vt/vt.c
+++ b/drivers/tty/vt/vt.c
@@ -4683,7 +4683,8 @@ void do_blank_screen(int entering_gfx)
 		hide_cursor(vc);
 		save_screen(vc);
 		vc->vc_sw->con_blank(vc, VESA_VSYNC_SUSPEND, 1);
-		console_blanked = fg_console + 1;
+		/* Pairs with the smp_load_acquire() in do_unblank_screen(). */
+		smp_store_release(&console_blanked, fg_console + 1);
 		blank_state = blank_off;
 		set_origin(vc);
 		return;
@@ -4693,7 +4694,8 @@ void do_blank_screen(int entering_gfx)
 
 	/* don't blank graphics */
 	if (vc->vc_mode != KD_TEXT) {
-		console_blanked = fg_console + 1;
+		/* Pairs with the smp_load_acquire() in do_unblank_screen(). */
+		smp_store_release(&console_blanked, fg_console + 1);
 		return;
 	}
 
@@ -4705,7 +4707,8 @@ void do_blank_screen(int entering_gfx)
 	/* In case we need to reset origin, blanking hook returns 1 */
 	i = vc->vc_sw->con_blank(vc, vesa_off_interval ? VESA_VSYNC_SUSPEND :
 				 (vesa_blank_mode + 1), 0);
-	console_blanked = fg_console + 1;
+	/* Pairs with the smp_load_acquire() in do_unblank_screen(). */
+	smp_store_release(&console_blanked, fg_console + 1);
 	if (i)
 		set_origin(vc);
 
@@ -4737,7 +4740,8 @@ void do_unblank_screen(int leaving_gfx)
 	WARN_CONSOLE_UNLOCKED();
 
 	ignore_poke = 0;
-	if (!console_blanked)
+	/* Pairs with the smp_store_release() in do_blank_screen(). */
+	if (!smp_load_acquire(&console_blanked))
 		return;
 	if (!vc_cons_allocated(fg_console)) {
 		/* impossible */

-- 
2.43.0

