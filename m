From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:28:15 -0400
Subject: [PATCH 2/6] vt: keyboard: publish npadch_value with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-keyboard-v1-2-d170228b80c0@vt.edu>
References: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
In-Reply-To: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1592;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=fmmEErRcPyO4zz0N6xCFkyoCjOBlv003JbWU2K7PoDE=;
 b=8byxCaFtSMphNyhtVoZMMVV38Hep9HPKKIzRXsDbE0X/YH1E+1pphIikQuhQvcNJ8X9VZ310/
 pAThflcBo8zBTG2Hk64zw6dFBo3vZP4WY7+LlNVTQ8eAZlA0IfwXr9M
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

k_ascii() accumulates the numeric keypad code in npadch_value after it
has set npadch_active. k_shift() tests npadch_active and then emits
npadch_value when the modifier is released.

Store the accumulated value with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/keyboard.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/tty/vt/keyboard.c b/drivers/tty/vt/keyboard.c
index 089f3b048..6f3472cd4 100644
--- a/drivers/tty/vt/keyboard.c
+++ b/drivers/tty/vt/keyboard.c
@@ -898,10 +898,13 @@ static void k_shift(struct vc_data *vc, unsigned char value, char up_flag)
 
 	/* kludge */
 	if (up_flag && shift_state != old_state && npadch_active) {
+		/* Pairs with the smp_store_release() in k_ascii(). */
+		unsigned int npadch = smp_load_acquire(&npadch_value);
+
 		if (kbd->kbdmode == VC_UNICODE)
-			to_utf8(vc, npadch_value);
+			to_utf8(vc, npadch);
 		else
-			put_queue(vc, npadch_value & 0xff);
+			put_queue(vc, npadch & 0xff);
 		npadch_active = false;
 	}
 }
@@ -939,7 +942,8 @@ static void k_ascii(struct vc_data *vc, unsigned char value, char up_flag)
 		npadch_active = true;
 	}
 
-	npadch_value = npadch_value * base + value;
+	/* Pairs with the smp_load_acquire() in k_shift(). */
+	smp_store_release(&npadch_value, npadch_value * base + value);
 }
 
 static void k_lock(struct vc_data *vc, unsigned char value, char up_flag)

-- 
2.43.0

