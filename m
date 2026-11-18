From: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
Date: Wed, 18 Nov 2026 10:24:41 -0800
Subject: [PATCH v3] staging: most: dim2: drop volatile from state counters
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-staging-dim2-atomic-v3-1-bc595e081fc8@tubot.lat>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ6CMBQFr0K6tqYttDauvIdxUeAXvhFq2kI0h
 Lvb4oaNLid5b2YhATxCIOdiIR5mDOjGBOWhIE1vxg4otomJYEJxzk40RNPh2NEWB0FNdAM2VGm
 jpdUWjFUkPZ8eLL426/X25TDVd2hiVuVFjyE6/96yM8+7/4WZU04V1BVoy60qzSVOtYvHh4kkF
 2axc/AfDpEcRkpmmeSaVeXesa7rB+y+100MAQAA
X-Change-ID: 20261107-staging-dim2-atomic-68a85f8feaf6
To: shyamsunderreddypadira@gmail.com, marusik.adamenko@gmail.com, 
 error27@gmail.com, gregkh@linuxfoundation.org, 
 christian.gromm@microchip.com, parthiban.veerasooran@microchip.com, 
 rajveer.chaudhari.linux@gmail.com
Cc: linux-kernel@vger.kernel.org, linux-staging@lists.linux.dev, 
 Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2808; i=DelaySystem@tubot.lat;
 h=from:subject:message-id; bh=obOr3rP8PTgcSS0Dx2Zi17AJdPtVHUgcvGOImUJO25I=;
 b=owGbwMvMwCH2SNl4+SzWXm/G02pJDFl/3x5P7s9RsppXzhhYcOZ+pvvrOqFdkX2Z/3pcfvKc2
 B16UO9ARykLgxgHg6yYIouYDM/7+vs6cdZWc07AzGFlAhnCwMUpABNhe87IMHWOdUfRJukPVl2L
 MrishERuvv88t2zdhp92ORYzVqz7c4fhf/mX4D+5C2qEL21gv+i+6R3/UvNP543fiPwriSxNkF0
 whQsA
X-Developer-Key: i=DelaySystem@tubot.lat; a=openpgp;
 fpr=161C0CEF7FDF2C5E3B3A9CC8E22333A79A058D4B
X-Endpoint-Received: by B4 Relay for DelaySystem@tubot.lat/default with auth_id=1447
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The request_counter/service_counter pair is shared between the AHB
hard-IRQ handler and the threaded-IRQ service path, but every access
already runs under dim_lock with local interrupts disabled:
dim2_ahb_isr() holds it across dim_service_ahb_int_irq(),
dim2_task_irq() across dim_service_channel(), and configure_channel()
across the dim_init_*() calls that zero the counters. The spinlock
provides both the mutual exclusion and the memory barriers, so the
volatile qualifier adds nothing and wrongly suggests lockless
cross-context sharing (see
Documentation/process/volatile-considered-harmful.rst).

Converting to atomic_t is the wrong tool here: the service-side
check-and-increment cannot be a single atomic step when done as
separate atomic_read() calls, as Dan Carpenter pointed out on the
atomic_t attempt, and a lockless scheme would still need dim_lock for
the sibling channel state (level, indices, done-buffer count, MBO
lists) anyway.

Drop the qualifier and document the actual protection in place. No
functional change intended.

Compile-tested only (MOST=m, MOST_DIM2=m build clean); I don't have
this hardware, so testing on real hardware would be appreciated.

Signed-off-by: Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>
---
Changes in v3:
- New direction: drop the NAKed atomic_t conversion. An audit showed every counter access already runs under dim_lock, so drop volatile and document the lock instead (Dan Carpenter).
- Link to v2: https://patch.msgid.link/20261117-staging-dim2-atomic-v2-1-a550f0518043@tubot.lat

Changes in v2:
- Resend under my real name (From/Signed-off-by: Maximo Manriquez Lizarraga).
- Apologies for the wasted cycle; if the objection was technical rather than the sender identity, please say what to change.
- Link to v1: https://patch.msgid.link/20261107-staging-dim2-atomic-v1-1-6eb4e8f1f63a@tubot.lat
---
 drivers/staging/most/dim2/hal.h | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/staging/most/dim2/hal.h b/drivers/staging/most/dim2/hal.h
index 5d69a5e7d299..f857e6856a16 100644
--- a/drivers/staging/most/dim2/hal.h
+++ b/drivers/staging/most/dim2/hal.h
@@ -33,11 +33,11 @@ struct dim_ch_state {
 };
 
 struct int_ch_state {
-	/* changed only in interrupt context */
-	volatile int request_counter;
+	/* protected by dim_lock; incremented in interrupt context */
+	int request_counter;
 
-	/* changed only in task context */
-	volatile int service_counter;
+	/* protected by dim_lock; updated in task context */
+	int service_counter;
 
 	u8 idx1;
 	u8 idx2;

---
base-commit: a41e364995bbcfa627418a70fe913c35b7510728
change-id: 20261107-staging-dim2-atomic-68a85f8feaf6

Best regards,
--  
Maximo Manriquez Lizarraga <DelaySystem@tubot.lat>

