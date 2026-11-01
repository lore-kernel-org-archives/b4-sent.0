From: Viorel Cernateanu <vrilutza@gmail.com>
Date: Sun, 01 Nov 2026 19:04:38 +0200
Subject: [PATCH v2 3/4] mm: Factor __pfn_valid() out of pfn_valid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-kmsan-serie-v2-3-f97f66dc57ef@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793552692; l=3241;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=dsg65O1UX/YgTMqtnmluSfWLq95yf8DD327IK6k7U4k=;
 b=TEbLB8WV9dS41IpUSxXS+cmQiZqUbRgRqNwMEIswcGyuuFjl7gBgh/jU/GoafzgI93HvfF4qB
 ZRiBLb6tGcFCgF7stfJjEwxtZdf3wGeWLfE2On3O5wDgjsAMVjkGMp4
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KMSAN needs to validate a PFN during metadata lookup without entering
instrumented code. Calling pfn_valid() also calls
rcu_read_lock_sched(), which can enter instrumented code and recurse
into the metadata lookup.

Extract the PFN checks into __pfn_valid(), whose caller must already
be in an RCU-sched read-side critical section. Keep pfn_valid() as
the wrapper that acquires and releases that protection.

This lets KMSAN reuse the existing PFN validation while providing
the required protection without instrumented helpers.

The wrapper now also holds the RCU-sched read lock during the
initial range checks, which previously ran before acquiring it.

Suggested-by: Alexander Potapenko <glider@google.com>
Signed-off-by: Viorel Cernateanu <vrilutza@gmail.com>
---
 include/linux/mmzone.h | 42 +++++++++++++++++++++++++-----------------
 1 file changed, 25 insertions(+), 17 deletions(-)

diff --git a/include/linux/mmzone.h b/include/linux/mmzone.h
index ecd1ebd49756..819042264088 100644
--- a/include/linux/mmzone.h
+++ b/include/linux/mmzone.h
@@ -2266,21 +2266,13 @@ static inline bool pfn_section_first_valid(struct mem_section *ms, unsigned long
 #endif
 
 #ifndef CONFIG_HAVE_ARCH_PFN_VALID
-/**
- * pfn_valid - check if there is a valid memory map entry for a PFN
- * @pfn: the page frame number to check
- *
- * Check if there is a valid memory map entry aka struct page for the @pfn.
- * Note, that availability of the memory map entry does not imply that
- * there is actual usable memory at that @pfn. The struct page may
- * represent a hole or an unusable page frame.
- *
- * Return: 1 for PFNs that have memory map entries and 0 otherwise
+/*
+ * Like pfn_valid(), but the caller must be in an RCU-sched read-side critical
+ * section, for example by disabling preemption.
  */
-static inline int pfn_valid(unsigned long pfn)
+static inline int __pfn_valid(unsigned long pfn)
 {
 	struct mem_section *ms;
-	int ret;
 
 	/*
 	 * Ensure the upper PAGE_SHIFT bits are clear in the
@@ -2294,16 +2286,32 @@ static inline int pfn_valid(unsigned long pfn)
 	if (pfn_to_section_nr(pfn) >= NR_MEM_SECTIONS)
 		return 0;
 	ms = __pfn_to_section(pfn);
-	rcu_read_lock_sched();
-	if (!valid_section(ms)) {
-		rcu_read_unlock_sched();
+	if (!valid_section(ms))
 		return 0;
-	}
 	/*
 	 * Traditionally early sections always returned pfn_valid() for
 	 * the entire section-sized span.
 	 */
-	ret = early_section(ms) || pfn_section_valid(ms, pfn);
+	return early_section(ms) || pfn_section_valid(ms, pfn);
+}
+
+/**
+ * pfn_valid - check if there is a valid memory map entry for a PFN
+ * @pfn: the page frame number to check
+ *
+ * Check if there is a valid memory map entry aka struct page for the @pfn.
+ * Note, that availability of the memory map entry does not imply that
+ * there is actual usable memory at that @pfn. The struct page may
+ * represent a hole or an unusable page frame.
+ *
+ * Return: 1 for PFNs that have memory map entries and 0 otherwise
+ */
+static inline int pfn_valid(unsigned long pfn)
+{
+	int ret;
+
+	rcu_read_lock_sched();
+	ret = __pfn_valid(pfn);
 	rcu_read_unlock_sched();
 
 	return ret;

-- 
2.53.0

