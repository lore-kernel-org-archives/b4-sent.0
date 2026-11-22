From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 20:35:36 +0800
Subject: [PATCH bpf v4 1/2] bpf: bound arena allocations to the user VMA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-1-d542d1233623@pm.me>
References: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-0-d542d1233623@pm.me>
In-Reply-To: <20261122-b4-03-bpf-arena-vmalloc-oob-v4-8090cdc58ff8-v4-0-d542d1233623@pm.me>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795350970; l=3854;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=NydRQKFXTXjxJi7zfPj1uOAvJMlBbK7Axhfoiyd0aNI=;
 b=bZgyB0O70KqrBqCTyh4nuOAUMlqdRdmQqJMTbqIhaKz7NM3HzkWae3OT3hSYll3PKjH9dHnFi
 A6opsC1BliVBVdg4BwChZYsjBbbTQVwgY/VHtG4mf02mErpSPOyoM3o
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An arena map initializes its free range tree to max_entries pages. When
map_extra is zero, the first mmap() may cover fewer pages. Fixed-address
allocations are bounded by the VMA size, but automatic allocations use
range_tree_find() across the whole tree and can select a range beyond
the VMA. arena_free_pages() clips frees to the VMA, so these pages
cannot be released through the arena kfunc.

With 4 KiB pages, set max_entries to 1 << 20 and mmap() a 288-page VMA
at 0xffee0000, ending at the next 4 GiB boundary. A 287-page
automatic allocation takes offsets [0, 287). A subsequent 288-page
allocation starts at offset 287, so its kernel mapping starts at
kern_vm_start + 0xfffff000. One page lies within the 4 GiB data band,
eight lie in the arena's upper half-guard, and 279 lie beyond its
requested vmalloc area. The first of those 279 is the vmalloc guard
page. The remaining 278 lie beyond the full reservation. The current
apply_to_page_range() path can install PTEs there. An unpatched local
test returned a non-NULL pointer for this allocation. Another run
triggered a WARNING in apply_range_set_cb() on a non-scratch PTE.

Out-of-VMA offsets need not wrap the low 32 bits. For example, when
the user VMA starts at a 4 GiB aligned address, they can still map
inside the arena's kernel area. They remain invalid because the VMA
does not cover them. The range-tree conversion replaced the bounded
mtree_alloc_range() search with range_tree_find() over max_entries.
The later switch from vm_area_map_pages() to apply_to_page_range()
removed the vm_struct bounds check, allowing these selections to
reach beyond the arena's vmalloc reservation.

On the first mmap() without map_extra, remove [vma_pages, max_entries)
from the free range tree before publishing the VMA bounds. The VMA
size is fixed after this mmap(), and the fault, reserve and free paths
do not add offsets outside it. Automatic allocations consequently
stay inside the VMA.

This issue was found through LLM-assisted code audit and manual code
inspection of kernel/bpf/arena.c, then checked with a Z3 SMT model and
a custom BPF test in an x86-64 QEMU/KVM guest. The test kernel
identified itself as 7.4.0-rc3-84074-gc44104f3642d. KASAN, UBSAN,
lockdep and DEBUG_OBJECTS were enabled. After the patch, the
288-page request returns NULL, the 287-page in-VMA request succeeds,
and the test reports no kernel warnings.

Fixes: b795379757eb ("bpf: Introduce range_tree data structure and use it in bpf arena")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
 kernel/bpf/arena.c | 25 +++++++++++++++++++++++++
 1 file changed, 25 insertions(+)

diff --git a/kernel/bpf/arena.c b/kernel/bpf/arena.c
index ec2bda1a6eb..94321dec638 100644
--- a/kernel/bpf/arena.c
+++ b/kernel/bpf/arena.c
@@ -694,6 +694,31 @@ static int arena_map_mmap(struct bpf_map *map, struct vm_area_struct *vma)
 	if (remember_vma(arena, vma))
 		return -ENOMEM;
 
+	if (!arena->user_vm_start && vma_pages(vma) < map->max_entries) {
+		/*
+		 * Without map_extra, the first mmap() can be shorter than
+		 * max_entries.  Remove offsets outside the VMA from the free
+		 * range tree so automatic allocations stay within the VMA.
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

-- 
Git-157)

