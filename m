From: Viorel Cernateanu <vrilutza@gmail.com>
Subject: [PATCH v2 0/4] x86/kmsan: Fix two bugs in the metadata lookup
Date: Sun, 01 Nov 2026 19:04:35 +0200
Message-Id: <20261101-kmsan-serie-v2-0-f97f66dc57ef@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OwQ6CMAyGX4XsbE03EhRPvofh0I0CUxlkw0Ulv
 LsMrh6/9v+/dhaBveUgLtksPEcb7OBWUIdMmI5cy2DrlYVCVUjEAh59IAdbCzjPEVHLsjQs1sb
 oubHvzXardg4vfWczJUVKaAoM2pMzXRrtGk1fgqjSvrNhGvxneyfK5Pl/OUpAwFND5wK5yWu+t
 j3Z59EMvaiWZfkBwydlCdgAAAA=
X-Change-ID: 20261006-kmsan-serie-e33000b199ce
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793552692; l=3024;
 i=vrilutza@gmail.com; s=lenovo-20261005; h=from:subject:message-id;
 bh=70IlPx1AKJ8+cqwvWRwobdqND9Oht8b+HJuyYoNKqmg=;
 b=FdDO8TSJQ+sj2UKnZMnNeYqMDmWCZVcKj/oNKlP7ur1VuKC10ya7OWVdZ7KEcPuzmH5QOLV9D
 REcYDbXZA/nDm+/qM0rMMa8PViACooI+H01bEDMiM1InW/oheZrWwAo
X-Developer-Key: i=vrilutza@gmail.com; a=ed25519;
 pk=HttZd2ffphVYTK/pvlflateaij8E4SdPd6Y+xDQMqDU=
X-Endpoint-Received: by B4 Relay for vrilutza@gmail.com/lenovo-20261005 with auth_id=1115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two fixes for the KMSAN metadata lookup on x86, found while running
KMSAN kernels with KASLR and with CONFIG_DEBUG_PREEMPT.

Patches 1 and 2 fix the CPU lookup for addresses in the CPU entry area.
With KASLR, the lookup treats a randomized slot as a CPU number. With
the areas in CPU order, it still attributes the last page of each CPU's
area to the next CPU.

Patches 3 and 4 fix a recursion with CONFIG_DEBUG_PREEMPT: the metadata
lookup ends up in the instrumented preempt_count_add(), and the kernel
hangs right after KMSAN is enabled. Patch 3 factors __pfn_valid() out
of pfn_valid() so that patch 4 can use it.

I tested the cumulative series with the v1 configurations, against the
same unpatched base:

- QEMU reproduces the GDT lookup failure and the metadata boundary
  failures on the base. The corresponding tests pass with v2, including
  the metadata tests with and without KASLR.
- With CONFIG_DEBUG_PREEMPT, the base hangs immediately after KMSAN
  starts. The candidate completes all six boots, three with KASLR and
  three without.
- On an Ivy Bridge laptop, the candidate boots with KASLR using a
  minimal init, and the GDT and metadata tests pass on all four CPUs.
- An x86_64_defconfig build without KMSAN boots to init.

I have not tested CONFIG_DEBUG_LOCK_ALLOC or measured the performance
difference.

s390's kmsan_virt_addr_valid() also calls preempt_disable() and reaches
pfn_valid() through virt_addr_valid(). This series does not change the
s390 code, but patch 3 refactors the generic pfn_valid() used on that
path. With an s390 defconfig plus KMSAN and CONFIG_DEBUG_PREEMPT, I
only compiled mm/kmsan/, arch/s390/mm/ and a few mm objects that use
pfn_valid(), with no warnings before or after the series. With
CONFIG_DEBUG_PREEMPT, the s390 metadata lookup still calls
preempt_count_add(). I have not built a full s390 kernel or run it.

---
Changes in v2:
- Keep the CPU entry areas in CPU order with KMSAN instead of searching
  all possible CPUs on each lookup (Alexander, Peter).
- Move the one-page offset fix into its own patch.
- Factor __pfn_valid() out of pfn_valid() instead of adding a KMSAN
  copy of it (Alexander).
- Rebase onto current mainline.
- Link to v1: https://patch.msgid.link/20261006-kmsan-serie-v1-0-07fa860ef3de@gmail.com

---
Viorel Cernateanu (4):
      x86/mm: Don't randomize the CPU entry area with KMSAN
      x86/kmsan: Use the per-CPU area base for metadata lookup
      mm: Factor __pfn_valid() out of pfn_valid()
      x86/kmsan: Don't call instrumented code from kmsan_virt_addr_valid()

 arch/x86/include/asm/kmsan.h | 31 +++++++++++++++++++------------
 arch/x86/mm/cpu_entry_area.c |  6 +++++-
 include/linux/mmzone.h       | 42 +++++++++++++++++++++++++-----------------
 3 files changed, 49 insertions(+), 30 deletions(-)
---
base-commit: cbbddb6b08cc9900a87cccaa9b22bbe06aa4f50a
change-id: 20261006-kmsan-serie-e33000b199ce

Best regards,
--  
Viorel Cernateanu <vrilutza@gmail.com>

