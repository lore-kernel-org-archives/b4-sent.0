From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 12:46:51 +0800
Subject: [PATCH bpf v2] bpf: bound arena allocations to the user VMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-03-bpf-arena-vmalloc-oob-v2-5f6209c1a20e-v2-1-b2a9906e9676@pm.me>
X-B4-Tracking: v=1; b=H4sIALpzAmsC/yWN0W7CMAxFfwX5GQvH8ULhVyYenNSBoNJWyag2I
 f597fZ4j67OeUGzWqzBefeCaktpZRrXwfsdpJuOV8PSrxuYODjHjFGQPMY5o1YbFZeHDsOUcJo
 iLowfOTCdklMmQ8oU4il7UjFYjXO1XL7/ap+wKuDyD9sz3i19bZ3tFrUZxqpjum2o2qA/uMFDE
 nEk2QfhXo9MLggJB/YmnefOB7Xc953B+/0LMRrYLNoAAAA=
X-Change-ID: 20261122-b4-03-bpf-arena-vmalloc-oob-v2-5f6209c1a20e-0f06b9f30a4e
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>
Cc: Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, bpf@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795322826; l=7440;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=DPOtTXYJ4A1Nsdzdq03zG2Y5kDlcW+p1iolpXZYER2w=;
 b=DA4j9fo2bRLcEcu9pwke58tYN2uokIfmZv5IhsOq04QPUxGY+/ZKHUdhW5CZAj5aAJ3QUxoo/
 6hySkBljCgLAkwQ1KLnhrUauSnQhllFZHf+su0Y5fIiZblytKkqtIH0
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf_arena_alloc_pages() hands out page ranges from the arena's range
tree, which is initialized to max_entries pages, while the kernel
mapping of those pages is built at kern_vm_start + (u32)user_addr.
The fixed-address path and bpf_arena_free_pages() both assume that a
returned range stays inside the user VMA, so that its lower 32 bits
do not wrap past the end of the arena's 4 GiB kernel vm area:

    long page_cnt_max = (user_vm_end - user_vm_start) >> PAGE_SHIFT;
    ...
    if (uaddr) {
            ...
            if (pgoff > page_cnt_max - page_cnt)
                    return 0;   /* bound only on the fixed-address path */
    }
    ret = arena_adjust_tree(arena, uaddr, page_cnt, &pgoff);
    ...
    uaddr32 = (u32)(user_vm_start + pgoff * PAGE_SIZE);

When map_extra is not given, arena_map_alloc() does not know the user
address and accepts any mmap() length up to max_entries pages, and
arena_get_unmapped_area() only requires that the mapping does not cross
a 4 GiB boundary.  A process can therefore mmap() a VMA that ends
exactly at a 4 GiB boundary while max_entries is much larger: for
max_entries = 2^20 and a 288-page VMA at 0xffee0000, the range tree
still holds free pages past the VMA, and arena_adjust_tree() hands
them out on the uaddr == 0 path with no bound on pgoff + page_cnt
against page_cnt_max.  A program that first allocates 287 pages and
then asks for 288 more receives pgoff = 287, uaddr32 = 0xfffff000,
and arena_alloc_pages() maps 288 pages at kern_vm_start + 0xfffff000:
one page inside the VMA, then the arena's upper guard pages, and then
258 pages into the vmalloc area past the end of the arena's own
vmap area - installing PTEs into address space the arena does not own
and returning a "success" pointer to the caller.

The damage cannot be undone: arena_free_pages() clips every free to
the VMA, so the pages mapped past kern_vm_start + 4 GiB are never
freed, arena_map_free() only walks the arena's own area, and the stale
PTEs and leaked pages survive the destruction of the map.  A second
arena whose kernel area happens to follow the first one receives
PTEs for pages it does not own; its user-visible arena_vm_fault()
finds them with vmalloc_to_page() and maps another map's pages into
its own user VMA.  When the walk instead reaches an already-mapped
foreign PTE, apply_range_set_cb() reports

    WARNING: kernel/bpf/arena.c:190 at apply_range_set_cb+0x4d9/0x830

after failing to install into the neighbour's page.  Any program that
may use an arena map (CAP_BPF, or an arena delegated through a BPF
token from a user namespace) can reach this; no race is needed.

Fix this on both sides.  On the first mmap() of a map created without
map_extra, mark [vma_pages, max_entries) as allocated in the range
tree, because nothing outside the VMA can ever be freed or mapped
without wrapping; no program can allocate before user_vm_start is
set, and the same mmap() path already serializes on arena->lock.  And
reject pgoff ranges past the VMA in arena_adjust_tree() with -ERANGE,
mirroring the existing page_cnt_max check of the fixed-address path,
so that even a stale tree entry cannot hand out an unwrappable range.

This issue was found through LLM-assisted code audit and manual code
inspection of kernel/bpf/arena.c, and then checked with a Z3 SMT model
and reproduced locally with a custom BPF test program in an x86-64
QEMU/KVM guest running v7.4-rc3 with KASAN, UBSAN, lockdep, and
DEBUG_OBJECTS enabled.

With a map created without map_extra and a 288-page VMA ending at a
4 GiB boundary, calling bpf_arena_alloc_pages() reproduced both the
out-of-VMA vmalloc mapping into an adjacent arena and the
WARNING: kernel/bpf/arena.c:190 at apply_range_set_cb().  After
applying the patch, the wrapped allocation returns NULL while in-VMA
allocations continue to succeed with no kernel warnings.

A test case and full validation logs are available on request.

Fixes: 317460317a02 ("bpf: Introduce bpf_arena.")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
Changes in v2:
- Resend via B4 Relay because the original email gained extra blank lines.
- Document how the issue was found and verified.
- No code changes.
- Link to v1: https://lore.kernel.org/r/20261122031025.9771-1-fadouse@pm.me
---
 kernel/bpf/arena.c | 44 ++++++++++++++++++++++++++++++++++++++++++--
 1 file changed, 42 insertions(+), 2 deletions(-)

diff --git a/kernel/bpf/arena.c b/kernel/bpf/arena.c
index ec2bda1a6eb..8adc2d589c7 100644
--- a/kernel/bpf/arena.c
+++ b/kernel/bpf/arena.c
@@ -694,6 +694,34 @@ static int arena_map_mmap(struct bpf_map *map, struct vm_area_struct *vma)
 	if (remember_vma(arena, vma))
 		return -ENOMEM;
 
+	if (!arena->user_vm_start && vma_pages(vma) < map->max_entries) {
+		/*
+		 * The range tree spans max_entries pages, but the user VMA
+		 * set below is smaller and its lower 32 bits do not wrap
+		 * past the 32-bit boundary.  Mark the pages past the VMA as
+		 * allocated so that bpf_arena_alloc_pages() can never hand
+		 * out a range that would be mapped past the end of the
+		 * arena's kernel vm area and could never be freed.
+		 */
+		unsigned long flags;
+		int ret = -EBUSY;
+
+		if (!raw_res_spin_lock_irqsave(&arena->spinlock, flags)) {
+			ret = range_tree_clear(&arena->rt, vma_pages(vma),
+					       map->max_entries - vma_pages(vma));
+			raw_res_spin_unlock_irqrestore(&arena->spinlock, flags);
+			WARN_ON_ONCE(ret);
+		}
+		if (ret) {
+			struct vma_list *vml = vma->vm_private_data;
+
+			list_del(&vml->head);
+			vma->vm_private_data = NULL;
+			kfree(vml);
+			return ret;
+		}
+	}
+
 	arena->user_vm_start = vma->vm_start;
 	arena->user_vm_end = vma->vm_end;
 	/*
@@ -743,7 +771,8 @@ static u64 clear_lo32(u64 val)
 	return val & ~(u64)~0U;
 }
 
-static int arena_adjust_tree(struct bpf_arena *arena, long uaddr, long page_cnt, long *pgoff)
+static int arena_adjust_tree(struct bpf_arena *arena, long uaddr, long page_cnt,
+			     long page_cnt_max, long *pgoff)
 {
 	int ret;
 
@@ -759,6 +788,17 @@ static int arena_adjust_tree(struct bpf_arena *arena, long uaddr, long page_cnt,
 	if (ret < 0)
 		return ret;
 
+	/*
+	 * The range tree spans max_entries pages, but when map_extra was
+	 * not given at arena creation time the user VMA, and hence the
+	 * range whose lower 32 bits do not wrap past the 32-bit boundary,
+	 * can be smaller.  A pgoff past the VMA would wrap uaddr32 past
+	 * the 32-bit boundary, be mapped past the end of the arena's
+	 * kernel vm area, and could never be freed, so reject it.
+	 */
+	if (ret > page_cnt_max - page_cnt)
+		return -ERANGE;
+
 	*pgoff = ret;
 
 	return range_tree_clear(&arena->rt, *pgoff, page_cnt);
@@ -812,7 +852,7 @@ static long arena_alloc_pages(struct bpf_arena *arena, long uaddr, long page_cnt
 	if (raw_res_spin_lock_irqsave(&arena->spinlock, flags))
 		goto out_free_pages;
 
-	ret = arena_adjust_tree(arena, uaddr, page_cnt, &pgoff);
+	ret = arena_adjust_tree(arena, uaddr, page_cnt, page_cnt_max, &pgoff);
 	if (ret) {
 		raw_res_spin_unlock_irqrestore(&arena->spinlock, flags);
 		goto out_free_pages;

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-03-bpf-arena-vmalloc-oob-v2-5f6209c1a20e-0f06b9f30a4e

Best regards,
--  
YanXin Li <fadouse@pm.me>

