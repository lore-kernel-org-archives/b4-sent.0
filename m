From: DelaySystem <DelaySystem@tubot.lat>
Date: Sat, 07 Nov 2026 19:14:42 -0800
Subject: [PATCH] staging: most: dim2: use atomic_t for channel state
 counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-staging-dim2-atomic-v1-1-6eb4e8f1f63a@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDtgAo3Bq5QupnESRzCWTCwF8
 e5N2+Vb/H+AchFWGLsDCr9EZcsN5tJBmCknRpmawfbWGdMPqJWS5ISTrBapbqsEdJ78NfrIFB2
 08lk4yvt3vd3/1v2xcKjfFZznBymVmeZ3AAAA
X-Change-ID: 20261107-staging-dim2-atomic-68a85f8feaf6
To: christian.gromm@microchip.com, rajveer.chaudhari.linux@gmail.com, 
 gregkh@linuxfoundation.org, error27@gmail.com, 
 parthiban.veerasooran@microchip.com, shyamsunderreddypadira@gmail.com, 
 marusik.adamenko@gmail.com
Cc: linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 DelaySystem <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3065; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=Ii9BCHVX5TgM8cAejB89bBMykIT8SDp5IxFLV81pPhs=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFnvXypmejyLT3GKnGHGu+GXwwQNIe6H0mGvu1L7fpxSC
 XA/zb+ho5SFQYyDQVZMkUVMhud9/X2dOGurOSdg5rAygQxh4OIUgIlIJDD8D7Zhqf3NFRbAzVoz
 76/5qaBAXefeSh0np+0X121hqNMqY/hnVxD5PTTLqvhznszz+O0/TH3mmr3rzVZ7v3L3uv1VxmI
 8AA==
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the volatile int channel state counters with atomic_t and
convert all access sites to the atomic API.

request_counter is incremented in the AHB interrupt handler
(channel_service_interrupt) and read from task context
(channel_service), while service_counter is updated in task context.
Plain volatile provides neither atomicity nor ordering for such
cross-context sharing, see
Documentation/process/volatile-considered-harmful.rst.

Use atomic_set() at init, atomic_inc() for updates and atomic_read()
for the comparison in channel_service().  No functional change is
intended.  Unlike the earlier attempt that only dropped the
qualifier, this converts the access sites as well.

Compile-tested only; I don't have this hardware, so testing on real
hardware would be appreciated.

Link: https://lore.kernel.org/linux-staging/2026072515-domestic-cardboard-f657@gregkh/
Signed-off-by: DelaySystem <DelaySystem@tubot.lat>
---
 drivers/staging/most/dim2/hal.c | 11 ++++++-----
 drivers/staging/most/dim2/hal.h |  5 +++--
 2 files changed, 9 insertions(+), 7 deletions(-)

diff --git a/drivers/staging/most/dim2/hal.c b/drivers/staging/most/dim2/hal.c
index 4f137ef846a3..ca931782b06c 100644
--- a/drivers/staging/most/dim2/hal.c
+++ b/drivers/staging/most/dim2/hal.c
@@ -419,8 +419,8 @@ u16 dim_dbr_space(struct dim_channel *ch)
 
 static void state_init(struct int_ch_state *state)
 {
-	state->request_counter = 0;
-	state->service_counter = 0;
+	atomic_set(&state->request_counter, 0);
+	atomic_set(&state->service_counter, 0);
 
 	state->idx1 = 0;
 	state->idx2 = 0;
@@ -634,7 +634,7 @@ static bool channel_service_interrupt(struct dim_channel *ch)
 		return false;
 
 	state->idx2 ^= 1;
-	state->request_counter++;
+	atomic_inc(&state->request_counter);
 	return true;
 }
 
@@ -682,8 +682,9 @@ static u8 channel_service(struct dim_channel *ch)
 {
 	struct int_ch_state *const state = &ch->state;
 
-	if (state->service_counter != state->request_counter) {
-		state->service_counter++;
+	if (atomic_read(&state->service_counter) !=
+	    atomic_read(&state->request_counter)) {
+		atomic_inc(&state->service_counter);
 		if (state->level == 0)
 			return DIM_ERR_UNDERFLOW;
 
diff --git a/drivers/staging/most/dim2/hal.h b/drivers/staging/most/dim2/hal.h
index 5d69a5e7d299..70b10793cf84 100644
--- a/drivers/staging/most/dim2/hal.h
+++ b/drivers/staging/most/dim2/hal.h
@@ -9,6 +9,7 @@
 #ifndef _DIM2_HAL_H
 #define _DIM2_HAL_H
 
+#include <linux/atomic.h>
 #include <linux/types.h>
 #include "reg.h"
 
@@ -34,10 +35,10 @@ struct dim_ch_state {
 
 struct int_ch_state {
 	/* changed only in interrupt context */
-	volatile int request_counter;
+	atomic_t request_counter;
 
 	/* changed only in task context */
-	volatile int service_counter;
+	atomic_t service_counter;
 
 	u8 idx1;
 	u8 idx2;

---
base-commit: a41e364995bbcfa627418a70fe913c35b7510728
change-id: 20261107-staging-dim2-atomic-68a85f8feaf6

Best regards,
--  
DelaySystem <DelaySystem@tubot.lat>

