From: Mani Tofigh <mt4022@columbia.edu>
Date: Sun, 22 Nov 2026 19:35:13 -0500
Subject: [PATCH v2 2/2] sched/wait: Pass wq_flags to
 __wait_event_interruptible_locked()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-sched-wait-intr-head-v2-2-4a764b64e8ce@columbia.edu>
References: <20261122-b4-sched-wait-intr-head-v2-0-4a764b64e8ce@columbia.edu>
In-Reply-To: <20261122-b4-sched-wait-intr-head-v2-0-4a764b64e8ce@columbia.edu>
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>
Cc: Oleg Nesterov <oleg@redhat.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Michal Nazarewicz <mina86@mina86.com>, Wen Yang <wen.yang@linux.dev>, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795394112; l=2225;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=roZMgbnlfY7Z0LN5dKGYogcKymzGcKkdtpGYCk/T+Jo=;
 b=xrysl58p2Ru8qL/I34WaiTlZ2Jjlmo/1OMOvsM2VNL7THSVyD3N/OCDGp5pMp2Ksr7eY+X8KH
 qunO9+E8kDRAfZ4Y/6VV4B2u8uLcrt/ykpUfKJ1YllQaWphsSXSRhno
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit cea5f91daa3a ("wait-event: clean up the internal helper
arguments") made ___wait_event() take the wait entry's flags instead of
a 0/1 argument for whether it is exclusive.
__wait_event_interruptible_locked() still takes the 0/1 argument.

Pass wq_flags here too, so the _exclusive_locked variants say
WQ_FLAG_EXCLUSIVE rather than an unexplained 1.

No functional change.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 include/linux/wait.h | 11 ++++++-----
 1 file changed, 6 insertions(+), 5 deletions(-)

diff --git a/include/linux/wait.h b/include/linux/wait.h
index b3e94c71cd3e..6c039d92c770 100644
--- a/include/linux/wait.h
+++ b/include/linux/wait.h
@@ -770,12 +770,11 @@ do {										\
 extern int do_wait_intr(wait_queue_head_t *, wait_queue_entry_t *);
 extern int do_wait_intr_irq(wait_queue_head_t *, wait_queue_entry_t *);
 
-#define __wait_event_interruptible_locked(wq, condition, exclusive, fn)		\
+#define __wait_event_interruptible_locked(wq, condition, wq_flags, fn)		\
 ({										\
 	int __ret;								\
 	DEFINE_WAIT(__wait);							\
-	if (exclusive)								\
-		__wait.flags |= WQ_FLAG_EXCLUSIVE;				\
+	__wait.flags = (wq_flags);						\
 	do {									\
 		__ret = fn(&(wq), &__wait);					\
 		if (__ret)							\
@@ -870,7 +869,8 @@ extern int do_wait_intr_irq(wait_queue_head_t *, wait_queue_entry_t *);
  */
 #define wait_event_interruptible_exclusive_locked(wq, condition)		\
 	((condition)								\
-	 ? 0 : __wait_event_interruptible_locked(wq, condition, 1, do_wait_intr))
+	 ? 0 : __wait_event_interruptible_locked(wq, condition,			\
+						 WQ_FLAG_EXCLUSIVE, do_wait_intr))
 
 /**
  * wait_event_interruptible_exclusive_locked_irq - sleep until a condition gets true
@@ -901,7 +901,8 @@ extern int do_wait_intr_irq(wait_queue_head_t *, wait_queue_entry_t *);
  */
 #define wait_event_interruptible_exclusive_locked_irq(wq, condition)		\
 	((condition)								\
-	 ? 0 : __wait_event_interruptible_locked(wq, condition, 1, do_wait_intr_irq))
+	 ? 0 : __wait_event_interruptible_locked(wq, condition,			\
+						 WQ_FLAG_EXCLUSIVE, do_wait_intr_irq))
 
 
 #define __wait_event_killable(wq, condition)					\

-- 
2.53.0

