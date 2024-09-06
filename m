From: Christoph Lameter <cl@gentwo.org>
Date: Fri, 06 Sep 2024 09:04:36 -0700
Subject: [PATCH v2] SLUB: Add support for per object memory policies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-strict_numa-v2-1-f104e6de6d1e@gentwo.org>
X-B4-Tracking: v=1; b=H4sIABMo22YC/22NsQ7CIBRFf6V5s5gCGlonjYujg5tpTKWP9g2CA
 ayahn+XMDuee3PPXSCgJwywqxbwOFMgZzOIVQV66u2IjIbMIGqxqRveshA96Xizr0fPjN62dym
 5kL2AvHh6NPQptiucD5fjCbocTxSi89/yMfNS/tXNnHGGA2+NUI1WRu1HtPHt1s6P0KWUfoutD
 nauAAAA
To: Vlastimil Babka <vbabka@suse.cz>, Pekka Enberg <penberg@kernel.org>, 
 David Rientjes <rientjes@google.com>, Joonsoo Kim <iamjoonsoo.kim@lge.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Hyeonggon Yoo <42.hyeyoo@gmail.com>, Yang Shi <shy828301@gmail.com>, 
 Christoph Lameter <cl@linux.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Huang Shijie <shijie@os.amperecomputing.com>, 
 "Christoph Lameter (Ampere)" <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725638684; l=3924;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=9Z6f1byj/IKu+iwRNPojSYbVKnkUeb562+j3sxm2IM4=;
 b=aEPyBeGGFT1QmjxLlIwTI8asDa6MXj9OiFp9VoP8MxGQhchv8AOVMDi6+CeRXuHB+YbVNZ3nc
 kuYYoWZ1pbCAPlYn69h/iFNcpKfniy3fHkQv4mqFlUDhinkxrUbYiis
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    The old SLAB allocator used to support memory policies on a per
    allocation bases. In SLUB the memory policies are applied on a
    per page frame / folio bases. Doing so avoids having to check memory
    policies in critical code paths for kmalloc and friends.

    This worked on general well on Intel/AMD/PowerPC because the
    interconnect technology is mature and can minimize the latencies
    through intelligent caching even if a small object is not
    placed optimally.

    However, on ARM we have an emergence of new NUMA interconnect
    technology based more on embedded devices. Caching of remote content
    can currently be ineffective using the standard building blocks / mesh
    available on that platform. Such architectures benefit if each slab
    object is individually placed according to memory policies
    and other restrictions.

    This patch adds another kernel parameter

            slab_strict_numa

    If that is set then a static branch is activated that will cause
    the hotpaths of the allocator to evaluate the current memory
    allocation policy. Each object will be properly placed by
    paying the price of extra processing and SLUB will no longer
    defer to the page allocator to apply memory policies at the
    folio level.

    This patch improves performance of memcached running
    on Ampere Altra 2P system (ARM Neoverse N1 processor)
    by 3.6% due to accurate placement of small kernel objects.

Tested-by: Huang Shijie <shijie@os.amperecomputing.com>
Signed-off-by: Christoph Lameter (Ampere) <cl@gentwo.org>
---
Changes in v2:
- Fix various issues
- Testing
---
 mm/slub.c | 42 ++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 42 insertions(+)

diff --git a/mm/slub.c b/mm/slub.c
index a77f354f8325..2fa7c35e076a 100644
--- a/mm/slub.c
+++ b/mm/slub.c
@@ -218,6 +218,10 @@ DEFINE_STATIC_KEY_FALSE(slub_debug_enabled);
 #endif
 #endif		/* CONFIG_SLUB_DEBUG */
 
+#ifdef CONFIG_NUMA
+DEFINE_STATIC_KEY_FALSE(strict_numa);
+#endif
+
 /* Structure holding parameters for get_partial() call chain */
 struct partial_context {
 	gfp_t flags;
@@ -3865,6 +3869,28 @@ static __always_inline void *__slab_alloc_node(struct kmem_cache *s,
 	object = c->freelist;
 	slab = c->slab;
 
+#ifdef CONFIG_NUMA
+	if (static_branch_unlikely(&strict_numa) &&
+			node == NUMA_NO_NODE) {
+
+		struct mempolicy *mpol = current->mempolicy;
+
+		if (mpol) {
+			/*
+			 * Special BIND rule support. If existing slab
+			 * is in permitted set then do not redirect
+			 * to a particular node.
+			 * Otherwise we apply the memory policy to get
+			 * the node we need to allocate on.
+			 */
+			if (mpol->mode != MPOL_BIND || !slab ||
+					!node_isset(slab_nid(slab), mpol->nodes))
+
+				node = mempolicy_slab_node();
+		}
+	}
+#endif
+
 	if (!USE_LOCKLESS_FAST_PATH() ||
 	    unlikely(!object || !slab || !node_match(slab, node))) {
 		object = __slab_alloc(s, gfpflags, node, addr, c, orig_size);
@@ -5527,6 +5553,22 @@ static int __init setup_slub_min_objects(char *str)
 __setup("slab_min_objects=", setup_slub_min_objects);
 __setup_param("slub_min_objects=", slub_min_objects, setup_slub_min_objects, 0);
 
+#ifdef CONFIG_NUMA
+static int __init setup_slab_strict_numa(char *str)
+{
+	if (nr_node_ids > 1) {
+		static_branch_enable(&strict_numa);
+		printk(KERN_INFO "SLUB: Strict NUMA enabled.\n");
+	} else
+		printk(KERN_WARNING "slab_strict_numa parameter set on non NUMA system.\n");
+
+	return 1;
+}
+
+__setup("slab_strict_numa", setup_slab_strict_numa);
+#endif
+
+
 #ifdef CONFIG_HARDENED_USERCOPY
 /*
  * Rejects incorrectly sized objects and objects that are to be copied

---
base-commit: b831f83e40a24f07c8dcba5be408d93beedc820f
change-id: 20240819-strict_numa-fc59b33123a2

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

