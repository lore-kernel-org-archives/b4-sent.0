From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:28:14 -0400
Subject: [PATCH 1/6] vt: keyboard: publish shift_state with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-keyboard-v1-1-d170228b80c0@vt.edu>
References: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
In-Reply-To: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1864;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=DZORQFC62iK2iCZRnS/XkfCIg2hwFuw7UKYfnaQuUPU=;
 b=UPuc8ERycqOPiQnTgiSO+VF/BAaQwbTGdO2XpaeEJXPgAq6q81guYo1In6Qq9UMuTmzdgh+S4
 Lfm5Rt6i8lqDtWYfJUboPxbNdQPelQ5+vm/YJGZoqCYAZzQ/2tlA2bJ
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

k_shift() updates shift_down[] and then shift_state under
kbd_event_lock. vt_get_shift_state() reads shift_state without the lock
for TIOCL_GETSHIFTSTATE, so the plain accesses leave the relation
between the counters and the summary word unspecified.

Store shift_state with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/keyboard.c | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/drivers/tty/vt/keyboard.c b/drivers/tty/vt/keyboard.c
index c41d850b2..089f3b048 100644
--- a/drivers/tty/vt/keyboard.c
+++ b/drivers/tty/vt/keyboard.c
@@ -865,6 +865,7 @@ static void k_pad(struct vc_data *vc, unsigned char value, char up_flag)
 static void k_shift(struct vc_data *vc, unsigned char value, char up_flag)
 {
 	int old_state = shift_state;
+	int state;
 
 	if (rep)
 		return;
@@ -889,9 +890,11 @@ static void k_shift(struct vc_data *vc, unsigned char value, char up_flag)
 		shift_down[value]++;
 
 	if (shift_down[value])
-		shift_state |= BIT(value);
+		state = shift_state | BIT(value);
 	else
-		shift_state &= ~BIT(value);
+		state = shift_state & ~BIT(value);
+	/* Pairs with the smp_load_acquire() in vt_get_shift_state(). */
+	smp_store_release(&shift_state, state);
 
 	/* kludge */
 	if (up_flag && shift_state != old_state && npadch_active) {
@@ -2212,8 +2215,11 @@ void vt_reset_unicode(unsigned int console)
  */
 int vt_get_shift_state(void)
 {
-        /* Don't lock as this is a transient report */
-        return shift_state;
+	/*
+	 * Don't lock as this is a transient report. Pairs with the
+	 * smp_store_release() in k_shift().
+	 */
+	return smp_load_acquire(&shift_state);
 }
 
 /**

-- 
2.43.0

