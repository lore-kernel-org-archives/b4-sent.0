From: "Christoph Lameter (Ampere)" <cl@gentwo.org>
Date: Mon, 19 Aug 2024 11:30:15 -0700
Subject: [PATCH v2] Avoid memory barrier in read_seqcount() through load
 acquire
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240819-seq_optimize-v2-1-9d0da82b022f@gentwo.org>
X-B4-Tracking: v=1; b=H4sIADaPw2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIxMDC0Nj3eLUwvj8gpLM3MyqVF0zi2QTCzNLs2RzSwsloJaCotS0zAqwcdG
 xtbUA0UUVFF4AAAA=
To: Catalin Marinas <catalin.marinas@arm.com>, 
 Will Deacon <will@kernel.org>, Peter Zijlstra <peterz@infradead.org>, 
 Ingo Molnar <mingo@redhat.com>, Waiman Long <longman@redhat.com>, 
 Boqun Feng <boqun.feng@gmail.com>
Cc: Linus Torvalds <torvalds@linux-foundation.org>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-arch@vger.kernel.org, "Christoph Lameter (Ampere)" <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724092223; l=5831;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=33u86Z1NtTj5I1hzjsT/8J5bCWwIeort9/FFXzrHRO8=;
 b=xjoqKpuJtKmVY/p7XqcrNDj6VvwsP/litDEErvD8DiwRs7UAnTdP/zYFWneATI5cWwAHPBQAe
 ONJwSIhLrBvD2MOb674/6mx5xNjsJr7TwjTFsCE/PjBfuy4IL4vKzRA
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some architectures support load acquire which can save us a memory
barrier and save some cycles.

A typical sequence

	do {
		seq = read_seqcount_begin(&s);
		<something>
	} while (read_seqcount_retry(&s, seq);

requires 13 cycles on ARM64 for an empty loop. Two read memory
barriers are needed. One for each of the seqcount_* functions.

We can replace the first read barrier with a load acquire of
the seqcount which saves us one barrier.

On ARM64 doing so reduces the cycle count from 13 to 8.

This is a general improvement for the ARM64 architecture and not
specific to a certain processor. The cycle count here was
obtained on a Neoverse N1 (Ampere Altra).

The ARM documentation states that load acquire is more effective
than a load plus barrier. In general that tends to be true on all
compute platforms that support both.

See (as quoted by Linus Torvalds):
   https://developer.arm.com/documentation/102336/0100/Load-Acquire-and-Store-Release-instructions

 "Weaker ordering requirements that are imposed by Load-Acquire and
  Store-Release instructions allow for micro-architectural
  optimizations, which could reduce some of the performance impacts that
  are otherwise imposed by an explicit memory barrier.

  If the ordering requirement is satisfied using either a Load-Acquire
  or Store-Release, then it would be preferable to use these
  instructions instead of a DMB"

Signed-off-by: Christoph Lameter (Ampere) <cl@gentwo.org>
---
V1->V2
- Describe the benefit of load acquire vs barriers
- Explain the CONFIG_ARCH_HAS_ACQUIRE_RELEASE option better
---
 arch/Kconfig            |  8 ++++++++
 arch/arm64/Kconfig      |  1 +
 include/linux/seqlock.h | 41 +++++++++++++++++++++++++++++++++++++++++
 3 files changed, 50 insertions(+)

diff --git a/arch/Kconfig b/arch/Kconfig
index 975dd22a2dbd..3c270f496231 100644
--- a/arch/Kconfig
+++ b/arch/Kconfig
@@ -1600,6 +1600,14 @@ config ARCH_HAS_KERNEL_FPU_SUPPORT
 	  Architectures that select this option can run floating-point code in
 	  the kernel, as described in Documentation/core-api/floating-point.rst.
 
+config ARCH_HAS_ACQUIRE_RELEASE
+	bool
+	help
+	  Setting ARCH_HAS_ACQUIRE_RELEASE indicates that the architecture
+	  supports load acquire and release. Typically these are more effective
+	  than memory barriers. Code will prefer the use of load acquire and
+	  store release over memory barriers if this option is enabled.
+
 source "kernel/gcov/Kconfig"
 
 source "scripts/gcc-plugins/Kconfig"
diff --git a/arch/arm64/Kconfig b/arch/arm64/Kconfig
index a2f8ff354ca6..19e34fff145f 100644
--- a/arch/arm64/Kconfig
+++ b/arch/arm64/Kconfig
@@ -39,6 +39,7 @@ config ARM64
 	select ARCH_HAS_PTE_DEVMAP
 	select ARCH_HAS_PTE_SPECIAL
 	select ARCH_HAS_HW_PTE_YOUNG
+	select ARCH_HAS_ACQUIRE_RELEASE
 	select ARCH_HAS_SETUP_DMA_OPS
 	select ARCH_HAS_SET_DIRECT_MAP
 	select ARCH_HAS_SET_MEMORY
diff --git a/include/linux/seqlock.h b/include/linux/seqlock.h
index d90d8ee29d81..353fcf32b800 100644
--- a/include/linux/seqlock.h
+++ b/include/linux/seqlock.h
@@ -176,6 +176,28 @@ __seqprop_##lockname##_sequence(const seqcount_##lockname##_t *s)	\
 	return seq;							\
 }									\
 									\
+static __always_inline unsigned						\
+__seqprop_##lockname##_sequence_acquire(const seqcount_##lockname##_t *s) \
+{									\
+	unsigned seq = smp_load_acquire(&s->seqcount.sequence);		\
+									\
+	if (!IS_ENABLED(CONFIG_PREEMPT_RT))				\
+		return seq;						\
+									\
+	if (preemptible && unlikely(seq & 1)) {				\
+		__SEQ_LOCK(lockbase##_lock(s->lock));			\
+		__SEQ_LOCK(lockbase##_unlock(s->lock));			\
+									\
+		/*							\
+		 * Re-read the sequence counter since the (possibly	\
+		 * preempted) writer made progress.			\
+		 */							\
+		seq = smp_load_acquire(&s->seqcount.sequence);		\
+	}								\
+									\
+	return seq;							\
+}									\
+									\
 static __always_inline bool						\
 __seqprop_##lockname##_preemptible(const seqcount_##lockname##_t *s)	\
 {									\
@@ -211,6 +233,11 @@ static inline unsigned __seqprop_sequence(const seqcount_t *s)
 	return READ_ONCE(s->sequence);
 }
 
+static inline unsigned __seqprop_sequence_acquire(const seqcount_t *s)
+{
+	return smp_load_acquire(&s->sequence);
+}
+
 static inline bool __seqprop_preemptible(const seqcount_t *s)
 {
 	return false;
@@ -259,6 +286,7 @@ SEQCOUNT_LOCKNAME(mutex,        struct mutex,    true,     mutex)
 #define seqprop_ptr(s)			__seqprop(s, ptr)(s)
 #define seqprop_const_ptr(s)		__seqprop(s, const_ptr)(s)
 #define seqprop_sequence(s)		__seqprop(s, sequence)(s)
+#define seqprop_sequence_acquire(s)	__seqprop(s, sequence_acquire)(s)
 #define seqprop_preemptible(s)		__seqprop(s, preemptible)(s)
 #define seqprop_assert(s)		__seqprop(s, assert)(s)
 
@@ -293,6 +321,18 @@ SEQCOUNT_LOCKNAME(mutex,        struct mutex,    true,     mutex)
  *
  * Return: count to be passed to read_seqcount_retry()
  */
+#ifdef CONFIG_ARCH_HAS_ACQUIRE_RELEASE
+#define raw_read_seqcount_begin(s)					\
+({									\
+	unsigned _seq;							\
+									\
+	while ((_seq = seqprop_sequence_acquire(s)) & 1)		\
+		cpu_relax();						\
+									\
+	kcsan_atomic_next(KCSAN_SEQLOCK_REGION_MAX);			\
+	_seq;								\
+})
+#else
 #define raw_read_seqcount_begin(s)					\
 ({									\
 	unsigned _seq = __read_seqcount_begin(s);			\
@@ -300,6 +340,7 @@ SEQCOUNT_LOCKNAME(mutex,        struct mutex,    true,     mutex)
 	smp_rmb();							\
 	_seq;								\
 })
+#endif
 
 /**
  * read_seqcount_begin() - begin a seqcount_t read critical section

---
base-commit: b0da640826ba3b6506b4996a6b23a429235e6923
change-id: 20240813-seq_optimize-68c48696c798

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

