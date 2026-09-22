From: Jaidev Shastri <jaidevshastri@vt.edu>
Date: Mon, 21 Sep 2026 21:28:16 -0400
Subject: [PATCH 3/6] vt: keyboard: publish dead_key_next with release
 semantics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260921-mb-keyboard-v1-3-d170228b80c0@vt.edu>
References: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
In-Reply-To: <20260921-mb-keyboard-v1-0-d170228b80c0@vt.edu>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Jaidev Shastri <jaidevshastri@vt.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790040498; l=1229;
 i=jaidevshastri@vt.edu; s=20260921; h=from:subject:message-id;
 bh=Zt+gxI5ocGWwJ74nIWECJ+/LdypxLyX9sdrY+y+9ulM=;
 b=9M/duHJeMb15eWfiTq1xttTPwr5lz2qfehv4hzEQucqHB0Cihsliy9ePf4U0cMqNni3EhBjB2
 UMIETRRa7wDAReKXSs1pA1WWlC6rrAmlc7l1rTjPYb4qjBn96OupyD/
X-Developer-Key: i=jaidevshastri@vt.edu; a=ed25519;
 pk=J7+xYJRlTPds+pv5hbqFFRqGCpDeJDzmZT1ggRwj7/0=
X-Endpoint-Received: by B4 Relay for jaidevshastri@vt.edu/20260921 with auth_id=1044
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fn_compose() arms the dead-key state in dead_key_next and k_unicode()
consumes it together with diacr.

Store the flag with smp_store_release() and read it with
smp_load_acquire().

Found with MBCheck, a static herd7-based memory consistency checker.

Signed-off-by: Jaidev Shastri <jaidevshastri@vt.edu>
---
 drivers/tty/vt/keyboard.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/vt/keyboard.c b/drivers/tty/vt/keyboard.c
index 6f3472cd4..d7db5e226 100644
--- a/drivers/tty/vt/keyboard.c
+++ b/drivers/tty/vt/keyboard.c
@@ -618,7 +618,8 @@ static void fn_boot_it(struct vc_data *vc)
 
 static void fn_compose(struct vc_data *vc)
 {
-	dead_key_next = true;
+	/* Pairs with the smp_load_acquire() in k_unicode(). */
+	smp_store_release(&dead_key_next, true);
 }
 
 static void fn_spawn_con(struct vc_data *vc)
@@ -672,7 +673,8 @@ static void k_unicode(struct vc_data *vc, unsigned int value, char up_flag)
 	if (diacr)
 		value = handle_diacr(vc, value);
 
-	if (dead_key_next) {
+	/* Pairs with the smp_store_release() in fn_compose(). */
+	if (smp_load_acquire(&dead_key_next)) {
 		dead_key_next = false;
 		diacr = value;
 		return;

-- 
2.43.0

