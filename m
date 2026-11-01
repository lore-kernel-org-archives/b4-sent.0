From: Viorel Cernateanu <vrilutza@gmail.com>
Date: Sun, 01 Nov 2026 19:04:36 +0200
Subject: [PATCH v2 1/4] x86/mm: Don't randomize the CPU entry area with
 KMSAN
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-kmsan-serie-v2-1-f97f66dc57ef@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793552692; l=1962;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=3GnlWiRUuop6GUO7x6h5NkCg48nWG8mPXHhT2pkVM5I=;
 b=yKz6MZ9gYqyG+QuCK81CgBR/q2zsFoBHJwnWKEvwQ6EyvvaGBEtoqNWRB3Iz2r9tvXCtvXbik
 qf1R5WMpACrA7a4Vnzww4SNVFt8w/FhpREa3DOYYxUVlJc+Mp+u3K2y
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

arch_kmsan_get_meta_or_null() derives the CPU number from the offset
of an address within the CPU entry area. This assumes that the areas
are laid out in CPU order.

With KASLR, init_cea_offsets() assigns each CPU a random slot. The
metadata lookup treats that slot number as a CPU number and can pass
an out-of-range index to get_cpu_entry_area().

On an Ivy Bridge laptop, this causes a KMSAN kernel to oops during
boot while the hard lockup detector sets up its perf event. A QEMU
test that reads one byte from the current CPU's GDT alias reproduces
the out-of-bounds access:

  UBSAN: array-index-out-of-bounds in arch/x86/mm/cpu_entry_area.c:25:9
  index 2100006 is out of range for type 'unsigned long[64]'
  RIP: 0010:get_cpu_entry_area+0x14/0x50

Keep the CPU entry areas in CPU order when KMSAN is enabled. This
allows the metadata lookup to identify the CPU directly, without
searching every CPU's area on each lookup.

This disables CPU entry area randomization for KMSAN kernels.
Kernel text randomization remains enabled.

Fixes: 97e3d26b5e5f ("x86/mm: Randomize per-cpu entry area")
Suggested-by: Alexander Potapenko <glider@google.com>
Signed-off-by: Viorel Cernateanu <vrilutza@gmail.com>
---
 arch/x86/mm/cpu_entry_area.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/arch/x86/mm/cpu_entry_area.c b/arch/x86/mm/cpu_entry_area.c
index 575f863f3c75..ce9b5d0e968d 100644
--- a/arch/x86/mm/cpu_entry_area.c
+++ b/arch/x86/mm/cpu_entry_area.c
@@ -30,7 +30,11 @@ static __init void init_cea_offsets(void)
 	unsigned int max_cea;
 	unsigned int i, j;
 
-	if (!kaslr_enabled()) {
+	/*
+	 * KMSAN works out the CPU of a CPU entry area address from its offset,
+	 * see arch_kmsan_get_meta_or_null(), so keep the areas in CPU order.
+	 */
+	if (!kaslr_enabled() || IS_ENABLED(CONFIG_KMSAN)) {
 		for_each_possible_cpu(i)
 			per_cpu(_cea_offset, i) = i;
 		return;

-- 
2.53.0

