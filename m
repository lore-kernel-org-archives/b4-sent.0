From: Viorel Cernateanu <vrilutza@gmail.com>
Date: Tue, 06 Oct 2026 21:10:23 +0300
Subject: [PATCH 2/2] x86/kmsan: Don't call instrumented code from
 kmsan_virt_addr_valid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-kmsan-serie-v1-2-07fa860ef3de@gmail.com>
References: <20261006-kmsan-serie-v1-0-07fa860ef3de@gmail.com>
In-Reply-To: <20261006-kmsan-serie-v1-0-07fa860ef3de@gmail.com>
To: Alexander Potapenko <glider@google.com>, Marco Elver <elver@google.com>, 
 Dmitry Vyukov <dvyukov@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Peter Zijlstra <peterz@infradead.org>, Kees Cook <kees@kernel.org>
Cc: Borislav Petkov <bp@suse.de>, kasan-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, Viorel Cernateanu <vrilutza@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791310225; l=3558;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=F/6GUjkmsEc44iwXpibyU3cTQT3QQPi2x9clp1QmJzo=;
 b=y51UBSnmJzZIEzHgGtVEXtakgvcDvS200jITenXhWf3+S/ur2nvwf6xfTDURpod1nh+DcsgEQ
 spuh+Rn93yHCbI7GnTqs8yx/subE5qMz3otCzEy1YPIk9UViXDmEKfr
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_DEBUG_PREEMPT, a KMSAN kernel hangs silently right after
KMSAN is enabled during boot.

kmsan_virt_addr_valid() calls preempt_disable() and pfn_valid(), and
pfn_valid() calls rcu_read_lock_sched(). With CONFIG_DEBUG_PREEMPT both
end up in preempt_count_add(), which is instrumented. Its instrumentation
looks up metadata, which calls kmsan_virt_addr_valid() again, and so on
until the boot stack overflows.

Use a copy of pfn_valid() that disables preemption with the notrace
helpers instead. It is still an RCU-sched read-side critical section,
and it avoids the instrumented preemption and RCU/lockdep helpers on
this path.

Fixes: f6564fce256a ("mm, kmsan: fix infinite recursion due to RCU critical section")
Signed-off-by: Viorel Cernateanu <vrilutza@gmail.com>
Link: https://lore.kernel.org/20240308043448.masllzeqwht45d4j@M910t
---
 arch/x86/include/asm/kmsan.h | 49 +++++++++++++++++++++++++++++---------------
 1 file changed, 33 insertions(+), 16 deletions(-)

diff --git a/arch/x86/include/asm/kmsan.h b/arch/x86/include/asm/kmsan.h
index a71e84d6abab..17effe8be642 100644
--- a/arch/x86/include/asm/kmsan.h
+++ b/arch/x86/include/asm/kmsan.h
@@ -68,6 +68,38 @@ static inline bool kmsan_phys_addr_valid(unsigned long addr)
 		return true;
 }
 
+/*
+ * Same as pfn_valid(), but without rcu_read_lock_sched(). That one calls into
+ * instrumented code: preempt_count_add() with CONFIG_DEBUG_PREEMPT or
+ * CONFIG_TRACE_PREEMPT_TOGGLE, lock_acquire() with CONFIG_DEBUG_LOCK_ALLOC.
+ * Instrumented code looks up metadata itself, so calling it from the metadata
+ * lookup can recurse; with CONFIG_DEBUG_PREEMPT it does, until the stack
+ * overflows.
+ *
+ * Disabling preemption still makes this an RCU-sched read-side critical
+ * section. Preemption is re-enabled without a reschedule, as before, to
+ * avoid entering the scheduler from the metadata lookup.
+ */
+static inline bool kmsan_pfn_valid(unsigned long pfn)
+{
+	struct mem_section *ms;
+	bool ret;
+
+	if (PHYS_PFN(PFN_PHYS(pfn)) != pfn)
+		return false;
+
+	if (pfn_to_section_nr(pfn) >= NR_MEM_SECTIONS)
+		return false;
+	ms = __pfn_to_section(pfn);
+
+	preempt_disable_notrace();
+	ret = valid_section(ms) &&
+	      (early_section(ms) || pfn_section_valid(ms, pfn));
+	preempt_enable_no_resched_notrace();
+
+	return ret;
+}
+
 /*
  * Taken from arch/x86/mm/physaddr.c to avoid using an instrumented version.
  */
@@ -75,7 +107,6 @@ static inline bool kmsan_virt_addr_valid(void *addr)
 {
 	unsigned long x = (unsigned long)addr;
 	unsigned long y = x - __START_KERNEL_map;
-	bool ret;
 
 	/* use the carry flag to determine if x was < __START_KERNEL_map */
 	if (unlikely(x > y)) {
@@ -91,21 +122,7 @@ static inline bool kmsan_virt_addr_valid(void *addr)
 			return false;
 	}
 
-	/*
-	 * pfn_valid() relies on RCU, and may call into the scheduler on exiting
-	 * the critical section. However, this would result in recursion with
-	 * KMSAN. Therefore, disable preemption here, and re-enable preemption
-	 * below while suppressing reschedules to avoid recursion.
-	 *
-	 * Note, this sacrifices occasionally breaking scheduling guarantees.
-	 * Although, a kernel compiled with KMSAN has already given up on any
-	 * performance guarantees due to being heavily instrumented.
-	 */
-	preempt_disable();
-	ret = pfn_valid(x >> PAGE_SHIFT);
-	preempt_enable_no_resched();
-
-	return ret;
+	return kmsan_pfn_valid(x >> PAGE_SHIFT);
 }
 
 #endif /* !MODULE */

-- 
2.53.0

