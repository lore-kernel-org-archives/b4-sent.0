From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 19:04:59 +0000
Subject: [PATCH] locking/lockdep: Use this_cpu_read() in
 lockdep_assert_RT_in_threaded_ctx()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-lockdep-rt-threaded-v1-1-7976173c8c49@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTuJU8WgVzEsaPsrowbItBISw
 t2tuvwW762UYIpEl2olw6xJx6FAdhWFvhvuYI3F5PbuJOIafo3hGTGxZc69oYuI7OvaH+TYnIO
 ASjkZbrr8rtf27/T2D4T8XdG2fQBB0i8wdwAAAA==
X-Change-ID: 20261128-lockdep-rt-threaded-b55b31489c1e
To: Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Waiman Long <longman@redhat.com>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Clark Williams <clrkwllms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Thomas Gleixner <tglx@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-rt-devel@lists.linux.dev, 
 syzbot+7227d49ef464b1dff36d@syzkaller.appspotmail.com, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795892699; l=1978;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=M6Q70FwjS3gK8WKT+pEZqDFYuamqQecaM5Af55U1tAQ=;
 b=Y/WatsaFLxjB6zXGU0NNMbw+lDx2F/9HF0A4exN0hoF+QHVf3rt8hBSnsYKxe8kSbWUNtyarJ
 N3BOOie6Jn3ASHOxjIztadUFFfir+jzTD2I7gYrWsF2t3abRZDDUsS6
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

lockdep_hardirq_context() is raw_cpu_read(). In preemptible code the
task can migrate between computing the per-CPU address and the load, and
read another CPU's hardirq_context. complete_all() from process context
then warns "Not in threaded context on PREEMPT_RT as expected".

Commit baffd723e44d ("lockdep: Revert "lockdep: Use raw_cpu_*() for
per-cpu variables"") fixed this for the other lockdep_assert_*()
helpers but missed this one, which reads it via irqflags.h.

Use this_cpu_read() like the other helpers.

Fixes: fddf9055a60d ("lockdep: Use raw_cpu_*() for per-cpu variables")
Reported-by: syzbot+7227d49ef464b1dff36d@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=7227d49ef464b1dff36d
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Tested on an Orange Pi 5 (RK3588S) with KASAN and PROVE_RAW_LOCK_NESTING:
before, the WARN hit from a panthor drm_sched kworker (1 in 4 boots of
the same run); after, 0 lockdep/KASAN reports in 5 boots.

This patch was developed with Claude (Anthropic), which wrote the code
and the commit message. I reviewed every change.
---
 include/linux/lockdep.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/linux/lockdep.h b/include/linux/lockdep.h
index a6451ecbbe9a..d2a6840d03e8 100644
--- a/include/linux/lockdep.h
+++ b/include/linux/lockdep.h
@@ -644,7 +644,7 @@ extern void lockdep_assert_in_softirq_func(void);
 
 # define lockdep_assert_RT_in_threaded_ctx() do {			\
 		WARN_ONCE(debug_locks && !current->lockdep_recursion &&	\
-			  lockdep_hardirq_context() &&			\
+			  this_cpu_read(hardirq_context) &&		\
 			  !(current->hardirq_threaded || current->irq_config),	\
 			  "Not in threaded context on PREEMPT_RT as expected\n");	\
 } while (0)

---
base-commit: 8e7c6217be7f8c016975f5b0954f6736b9ac42cf
change-id: 20261128-lockdep-rt-threaded-b55b31489c1e

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

