From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Tue, 17 Nov 2026 16:06:06 -0800
Subject: [PATCH v2] staging: most: dim2: use atomic_t for channel state
 counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-staging-dim2-atomic-v2-1-a550f0518043@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBBFr0Jm7RhatTauvIdhMcAUxgglbSEaw
 t0F3Lt8yfvvzxA5CEe4ZTMEniSK71fQhwyqlvqGUeqVQefaKJVfMSZqpG+wlk4jJd9JhcaSvTj
 rmJyBdTkEdvLeq4/ix3Esn1ylLbUZrcTkw2e/ndTm/X+YFCo0XJ7ZOuXMie5pLH06vihBsSzLF
 2q0klzIAAAA
X-Change-ID: 20261107-staging-dim2-atomic-68a85f8feaf6
To: error27@gmail.com, shyamsunderreddypadira@gmail.com, 
 marusik.adamenko@gmail.com, rajveer.chaudhari.linux@gmail.com, 
 parthiban.veerasooran@microchip.com, christian.gromm@microchip.com, 
 gregkh@linuxfoundation.org
Cc: linux-kernel@vger.kernel.org, linux-staging@lists.linux.dev, 
 Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3418; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=DzVwGgJlaMAT/3SAIgdkmln9ovVSG2ZhjYnhV3aplks=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/Xr/9uNDl6g6TFZyFb2+K2nkm9HqZsJYuUdnjs1Okr
 vxT6bKXHaUsDGIcDLJiiixiMjzv6+/rxFlbzTkBM4eVCWQIAxenAExkOwMjw7S0lCZeoSddMrvv
 tZVHaRq1VuRmi8R8VnGx+Tu9zeb/VEaG9kNmFzmvxIlmGJglyF0NcdiWG6g/9dImzUzTEydPHEt
 iAwA=
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
Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Changes in v2:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Apologies for the wasted cycle; if the objection was technical rather than the sender identity, please say what to change.
- Link to v1: https://patch.msgid.link/20261107-staging-dim2-atomic-v1-1-6eb4e8f1f63a@tubot.lat
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
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

