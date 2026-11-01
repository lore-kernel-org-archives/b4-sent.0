From: Viorel Cernateanu <vrilutza@gmail.com>
Date: Sun, 01 Nov 2026 19:04:37 +0200
Subject: [PATCH v2 2/4] x86/kmsan: Use the per-CPU area base for metadata
 lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-kmsan-serie-v2-2-f97f66dc57ef@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793552692; l=2372;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=NoOANBIkTTfd/eqBkNAgT+oIrASIhNAW1KDPRJHc8EE=;
 b=QwxnxeGnXDmOd0DLmmsnWf6hS/U2H9z5w0zqfUe3FwI30/q+cMZZ3cIhxbu4zEaIwpmDEOOgW
 Qh8H+LP1/BxCCn5PY4EV0iqampEubxUsI2yfqO1JYZ8zM0xSpo3c+ME
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The per-CPU entry areas start at CPU_ENTRY_AREA_PER_CPU, one page
above CPU_ENTRY_AREA_BASE, after the read-only IDT page.

arch_kmsan_get_meta_or_null() computes the CPU number relative to
CPU_ENTRY_AREA_BASE. With the areas laid out in CPU order, this
attributes the last page of each CPU's area to the next CPU. The
subsequent offset check rejects the address, so KMSAN cannot find
its metadata. At the end of the populated area, the lookup can also
select a CPU that is not possible.

Compute the CPU number relative to CPU_ENTRY_AREA_PER_CPU and
exclude the IDT page from the lookup. Check that the resulting CPU
is within nr_cpu_ids and possible before accessing its per-CPU data.

Remove the always-false negative check on the unsigned offset.

Fixes: ce732a7520b0 ("x86: kmsan: handle CPU entry area")
Signed-off-by: Viorel Cernateanu <vrilutza@gmail.com>
---
 arch/x86/include/asm/kmsan.h | 14 +++++++++-----
 1 file changed, 9 insertions(+), 5 deletions(-)

diff --git a/arch/x86/include/asm/kmsan.h b/arch/x86/include/asm/kmsan.h
index d91b37f5b4bb..c6715b2db0dc 100644
--- a/arch/x86/include/asm/kmsan.h
+++ b/arch/x86/include/asm/kmsan.h
@@ -13,6 +13,7 @@
 
 #include <asm/cpu_entry_area.h>
 #include <asm/processor.h>
+#include <linux/cpumask.h>
 #include <linux/mmzone.h>
 
 DECLARE_PER_CPU(char[CPU_ENTRY_AREA_SIZE], cpu_entry_area_shadow);
@@ -32,14 +33,17 @@ static inline void *arch_kmsan_get_meta_or_null(void *addr, bool is_origin)
 	unsigned long addr64 = (unsigned long)addr;
 	char *metadata_array;
 	unsigned long off;
-	int cpu;
+	unsigned int cpu;
 
-	if ((addr64 < CPU_ENTRY_AREA_BASE) ||
-	    (addr64 >= (CPU_ENTRY_AREA_BASE + CPU_ENTRY_AREA_MAP_SIZE)))
+	/* The per-CPU areas start after the read-only IDT page. */
+	if (addr64 < CPU_ENTRY_AREA_PER_CPU ||
+	    addr64 >= CPU_ENTRY_AREA_BASE + CPU_ENTRY_AREA_MAP_SIZE)
+		return NULL;
+	cpu = (addr64 - CPU_ENTRY_AREA_PER_CPU) / CPU_ENTRY_AREA_SIZE;
+	if (cpu >= nr_cpu_ids || !cpu_possible(cpu))
 		return NULL;
-	cpu = (addr64 - CPU_ENTRY_AREA_BASE) / CPU_ENTRY_AREA_SIZE;
 	off = addr64 - (unsigned long)get_cpu_entry_area(cpu);
-	if ((off < 0) || (off >= CPU_ENTRY_AREA_SIZE))
+	if (off >= CPU_ENTRY_AREA_SIZE)
 		return NULL;
 	metadata_array = is_origin ? cpu_entry_area_origin :
 				     cpu_entry_area_shadow;

-- 
2.53.0

