From: Viorel Cernateanu <vrilutza@gmail.com>
Date: Sun, 01 Nov 2026 19:04:39 +0200
Subject: [PATCH v2 4/4] x86/kmsan: Don't call instrumented code from
 kmsan_virt_addr_valid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-kmsan-serie-v2-4-f97f66dc57ef@gmail.com>
References: <20261101-kmsan-serie-v2-0-f97f66dc57ef@gmail.com>
In-Reply-To: <20261101-kmsan-serie-v2-0-f97f66dc57ef@gmail.com>
To: Dave Hansen <dave.hansen@linux.intel.com>, 
 Andy Lutomirski <luto@kernel.org>, Peter Zijlstra <peterz@infradead.org>, 
 Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Alexander Potapenko <glider@google.com>, 
 Marco Elver <elver@google.com>, Dmitry Vyukov <dvyukov@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Kairui Song <kasong@tencent.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Kees Cook <kees@kernel.org>
Cc: Borislav Petkov <bp@suse.de>, linux-kernel@vger.kernel.org, 
 kasan-dev@googlegroups.com, linux-mm@kvack.org, 
 Ilya Leoshkevich <iii@linux.ibm.com>, 
 Viorel Cernateanu <vrilutza@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793552692; l=2610;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=4lXdVBpJSiUWkUV4FYeTn6HuAjrb93rQ9oQKVwzlb6A=;
 b=o1OjIlZvUzgJ+zlmu7Rc0edi0aBd0UOWa/X09z9NOQ1Xbdz5UwRFALG2LG7nc3rQ/JH/tX7Ot
 u/YA3JxtV/ZB3DyUgm46sTQ12cCCQq2/9XlO0o6B9q31clwrM1b0+oi
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With CONFIG_DEBUG_PREEMPT enabled, a KMSAN kernel hangs during boot
immediately after KMSAN is enabled.

kmsan_virt_addr_valid() calls preempt_disable() and pfn_valid(), which
in turn calls rcu_read_lock_sched(). With CONFIG_DEBUG_PREEMPT, these
paths call the instrumented preempt_count_add(). Its instrumentation
requests metadata and re-enters kmsan_virt_addr_valid(), causing
recursion.

Use preempt_disable_notrace() and __pfn_valid() to validate the PFN
without entering those instrumented helpers. Disabling preemption
provides the RCU-sched read-side protection required by __pfn_valid().

Use preempt_enable_no_resched_notrace() on exit to avoid both
instrumentation and a reschedule from the metadata lookup.

Fixes: f6564fce256a ("mm, kmsan: fix infinite recursion due to RCU critical section")
Link: https://lore.kernel.org/20240308043448.masllzeqwht45d4j@M910t
Suggested-by: Alexander Potapenko <glider@google.com>
Signed-off-by: Viorel Cernateanu <vrilutza@gmail.com>
---
 arch/x86/include/asm/kmsan.h | 17 ++++++++++-------
 1 file changed, 10 insertions(+), 7 deletions(-)

diff --git a/arch/x86/include/asm/kmsan.h b/arch/x86/include/asm/kmsan.h
index c6715b2db0dc..e36df95439df 100644
--- a/arch/x86/include/asm/kmsan.h
+++ b/arch/x86/include/asm/kmsan.h
@@ -85,18 +85,21 @@ static inline bool kmsan_virt_addr_valid(void *addr)
 	}
 
 	/*
-	 * pfn_valid() relies on RCU, and may call into the scheduler on exiting
-	 * the critical section. However, this would result in recursion with
-	 * KMSAN. Therefore, disable preemption here, and re-enable preemption
-	 * below while suppressing reschedules to avoid recursion.
+	 * pfn_valid() takes rcu_read_lock_sched(), which can call instrumented
+	 * code (preempt_count_add() with CONFIG_DEBUG_PREEMPT, lock_acquire()
+	 * with CONFIG_DEBUG_LOCK_ALLOC). That code looks up metadata itself and
+	 * would recurse here. Disable preemption with the notrace helpers
+	 * instead, which keeps this an RCU-sched read-side critical section,
+	 * and re-enable it without a reschedule to avoid entering the scheduler
+	 * from the metadata lookup.
 	 *
 	 * Note, this sacrifices occasionally breaking scheduling guarantees.
 	 * Although, a kernel compiled with KMSAN has already given up on any
 	 * performance guarantees due to being heavily instrumented.
 	 */
-	preempt_disable();
-	ret = pfn_valid(x >> PAGE_SHIFT);
-	preempt_enable_no_resched();
+	preempt_disable_notrace();
+	ret = __pfn_valid(x >> PAGE_SHIFT);
+	preempt_enable_no_resched_notrace();
 
 	return ret;
 }

-- 
2.53.0

