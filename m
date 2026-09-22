From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:27:14 -0400
Subject: [PATCH 1/3] vt: order the fg_console switch against
 vt_console_print()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-vt-v1-1-71b7990c26c1@vt.edu>
References: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
In-Reply-To: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040439; l=1552;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=t3w49a+qfe39Dk2oPAqqzDMPS4oixsoA4+DLTHcPzWQ=;
 b=gREHg8oU0b+2dX6YOKClDz3gXZ9k/R+gxQhItKMJW2tnsE2PJTZ9ViDqHLlkcePX7de3mQ0bE
 iSvsIHnZs09BQ4GN1h2RKFDPWKvx2K7i80tCVWpsRFySn/Gr+nJmEiw
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

redraw_screen() switches fg_console with a plain store once the new
console's state is set up. vt_console_print(), the printk console
callback, indexes vc_cons[] with fg_console before it takes
printing_lock.

Store the new index with smp_store_release() and read it with
smp_load_acquire(), so that the printk path cannot reach the slot before
the console it denotes is complete.

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/vt.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/vt/vt.c b/drivers/tty/vt/vt.c
index 57edf3749..3abbd6cf9 100644
--- a/drivers/tty/vt/vt.c
+++ b/drivers/tty/vt/vt.c
@@ -973,7 +973,8 @@ void redraw_screen(struct vc_data *vc, int is_switch)
 		if (!con_is_visible(vc))
 			redraw = 1;
 		*vc->vc_display_fg = vc;
-		fg_console = vc->vc_num;
+		/* Pairs with the smp_load_acquire() in vt_console_print(). */
+		smp_store_release(&fg_console, vc->vc_num);
 		hide_cursor(old_vc);
 		if (!con_is_visible(old_vc)) {
 			save_screen(old_vc);
@@ -3447,7 +3448,8 @@ int vt_kmsg_redirect(int new)
 
 static void vt_console_print(struct console *co, const char *b, unsigned count)
 {
-	struct vc_data *vc = vc_cons[fg_console].d;
+	/* Pairs with the smp_store_release() in redraw_screen(). */
+	struct vc_data *vc = vc_cons[smp_load_acquire(&fg_console)].d;
 	unsigned char c;
 	static DEFINE_SPINLOCK(printing_lock);
 	const ushort *start;

-- 
2.43.0

