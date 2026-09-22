From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:27:16 -0400
Subject: [PATCH 3/3] vt: order the vc_cons[] clear against
 console_callback()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-vt-v1-3-71b7990c26c1@vt.edu>
References: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
In-Reply-To: <20260921-mb-vt-v1-0-71b7990c26c1@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040439; l=1520;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=n064wC3Fdt35/BuS9qHKcc8lilea0y9ChG1ooSTcVBk=;
 b=Cyt/0YbOQE8rFx7wYIzQ8vqzJBMtdzlsL/BBKnz9w9AzPzpGW72AsY5HktLYXJ+9ocVbqB4jJ
 XjrdM5P/lGsB+HepieQVYNFM54YzSadx3wlB5bHuRj/i0NXCxQAGUno
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vc_deallocate() frees the console's screen buffer and unimap and then
clears vc_cons[currcons].d with a plain store. console_callback() reads
vc_cons[fg_console].d with a plain load.

Clear the slot with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/vt.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/vt/vt.c b/drivers/tty/vt/vt.c
index 726402167..66aa089bf 100644
--- a/drivers/tty/vt/vt.c
+++ b/drivers/tty/vt/vt.c
@@ -1369,7 +1369,8 @@ struct vc_data *vc_deallocate(unsigned int currcons)
 		put_pid(vc->vt_pid);
 		vc_uniscr_set(vc, NULL);
 		kfree(vc->vc_screenbuf);
-		vc_cons[currcons].d = NULL;
+		/* Pairs with the smp_load_acquire() in console_callback(). */
+		smp_store_release(&vc_cons[currcons].d, NULL);
 		if (vc->vc_saved_screen != NULL) {
 			kfree(vc->vc_saved_screen);
 			vc->vc_saved_screen = NULL;
@@ -3368,7 +3369,8 @@ static void console_callback(struct work_struct *ignored)
 		poke_blanked_console();
 	}
 	if (scrollback_delta) {
-		struct vc_data *vc = vc_cons[fg_console].d;
+		/* Pairs with the smp_store_release() in vc_deallocate(). */
+		struct vc_data *vc = smp_load_acquire(&vc_cons[fg_console].d);
 		clear_selection();
 		if (vc->vc_mode == KD_TEXT && vc->vc_sw->con_scrolldelta)
 			vc->vc_sw->con_scrolldelta(vc, scrollback_delta);

-- 
2.43.0

