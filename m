From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:28:18 -0400
Subject: [PATCH 5/6] vt: keyboard: recompute the shift state into locals
 before publishing it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-keyboard-v1-5-d170228b80c0@vt.edu>
References: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
In-Reply-To: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1670;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=Pcy9gXCqUcOIXjrml7UXFL+N6Nxn53Hov/Dv8U22J58=;
 b=/S5sFva/qHPrN7SkZipZS8wgJoIDFwKtAIrLhgQAV0p9/Gtkd2AibWMh0YcCmzStXavDablxR
 1ml1JWaxjzyDDA7cTOBcOPf/20vP8sN4/D6Xv9VHsfNULO8pSLdOFlW
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_compute_shiftstate() clears shift_state and shift_down[] and rebuilds
them in place while it iterates key_down[]. vt_get_shift_state() reads
shift_state without kbd_event_lock and can observe the cleared or
partially rebuilt value.

Compute the new state into locals, copy shift_down[] first and publish
shift_state last with smp_store_release().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/keyboard.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/tty/vt/keyboard.c b/drivers/tty/vt/keyboard.c
index c2fd92e2b..87970415a 100644
--- a/drivers/tty/vt/keyboard.c
+++ b/drivers/tty/vt/keyboard.c
@@ -403,10 +403,9 @@ static void set_leds(void)
 
 static void do_compute_shiftstate(void)
 {
+	unsigned char down[NR_SHIFT] = { 0 };
 	unsigned int k, sym, val;
-
-	shift_state = 0;
-	memset(shift_down, 0, sizeof(shift_down));
+	int state = 0;
 
 	for_each_set_bit(k, key_down, min(NR_KEYS, KEY_CNT)) {
 		sym = U(key_maps[0][k]);
@@ -417,9 +416,17 @@ static void do_compute_shiftstate(void)
 		if (val == KVAL(K_CAPSSHIFT))
 			val = KVAL(K_SHIFT);
 
-		shift_down[val]++;
-		shift_state |= BIT(val);
+		down[val]++;
+		state |= BIT(val);
 	}
+
+	memcpy(shift_down, down, sizeof(shift_down));
+	/*
+	 * Publish the recomputed state in one step. vt_get_shift_state()
+	 * reads shift_state without kbd_event_lock; pairs with its
+	 * smp_load_acquire().
+	 */
+	smp_store_release(&shift_state, state);
 }
 
 /* We still have to export this method to vt.c */

-- 
2.43.0

