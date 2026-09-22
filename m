From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:28:19 -0400
Subject: [PATCH 6/6] vt: keyboard: publish the shift_down[] counters with
 release semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-keyboard-v1-6-d170228b80c0@vt.edu>
References: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
In-Reply-To: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1912;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=KnTNjEcgHMMpVCPx3XbhLE+RN8D0Cwj3lZFOas1PfsM=;
 b=GlDBlN86FER15lgRBvlYa0LSOQ81HR/YvfKC6lQD9Jtc/CmZOAIpmHp5AxhRbJQlcx8HrJ+He
 NuoQNEbI2kLBI/9wvBB/z6B+hyoeIbVELZ6tiaOPPsHObOH+SvV31yx
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

k_shift() maintains the per-modifier depress counters in shift_down[]
and k_pad() tests shift_down[KG_SHIFT] to choose between application and
numeric keypad codes.

Update the counter with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/keyboard.c | 13 +++++++++----
 1 file changed, 9 insertions(+), 4 deletions(-)

diff --git a/drivers/tty/vt/keyboard.c b/drivers/tty/vt/keyboard.c
index 87970415a..e6112e0db 100644
--- a/drivers/tty/vt/keyboard.c
+++ b/drivers/tty/vt/keyboard.c
@@ -823,7 +823,8 @@ static void k_pad(struct vc_data *vc, unsigned char value, char up_flag)
 		return;		/* no action, if this is a key release */
 
 	/* kludge... shift forces cursor/number keys */
-	if (vc_kbd_mode(kbd, VC_APPLIC) && !shift_down[KG_SHIFT]) {
+	/* Pairs with the smp_store_release() in k_shift(). */
+	if (vc_kbd_mode(kbd, VC_APPLIC) && !smp_load_acquire(&shift_down[KG_SHIFT])) {
 		applkey(vc, app_map[value], 1);
 		return;
 	}
@@ -877,6 +878,7 @@ static void k_shift(struct vc_data *vc, unsigned char value, char up_flag)
 {
 	int old_state = shift_state;
 	int state;
+	unsigned char cnt;
 
 	if (rep)
 		return;
@@ -890,15 +892,18 @@ static void k_shift(struct vc_data *vc, unsigned char value, char up_flag)
 			clr_vc_kbd_led(kbd, VC_CAPSLOCK);
 	}
 
+	cnt = shift_down[value];
 	if (up_flag) {
 		/*
 		 * handle the case that two shift or control
 		 * keys are depressed simultaneously
 		 */
-		if (shift_down[value])
-			shift_down[value]--;
+		if (cnt)
+			cnt--;
 	} else
-		shift_down[value]++;
+		cnt++;
+	/* Pairs with the smp_load_acquire() in k_pad(). */
+	smp_store_release(&shift_down[value], cnt);
 
 	if (shift_down[value])
 		state = shift_state | BIT(value);

-- 
2.43.0

