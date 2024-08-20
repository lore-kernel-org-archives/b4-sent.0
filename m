From: Christoph Lameter <cl@gentwo.org>
Date: Mon, 19 Aug 2024 18:29:45 -0700
Subject: [PATCH RFC] SLUB: Add support for per object memory policies
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240819-strict_numa-v1-1-ed19f278c7f7@gentwo.org>
X-B4-Tracking: v=1; b=H4sIAIjxw2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDC0NL3eKSoszkkvi80txE3bRkU8skY2NDI+NEIyWgjoKi1LTMCrBp0Up
 Bbs5KsbW1AK89VbJiAAAA
To: Vlastimil Babka <vbabka@suse.cz>, Pekka Enberg <penberg@kernel.org>, 
 David Rientjes <rientjes@google.com>, Joonsoo Kim <iamjoonsoo.kim@lge.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Hyeonggon Yoo <42.hyeyoo@gmail.com>, Yang Shi <shy828301@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 "Christoph Lameter (Ampere)" <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724117396; l=2985;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=WCkmlka2muGf3df5xwLt0U+IUMuVYP3f3DZ+713T/TY=;
 b=pytFnytVJB7IrVevzcGROanOnrwdyHDWZ/XhESjVY5Qg10L8R19EM7qNT0yVSpn44ZGrEUAL3
 v4iQLyirblXCnXM00TLtKmYTJhOD7PglYdV4OQpBbDKKd9v78bWf3zN
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The old SLAB allocator used to support memory policies on a per
allocation bases. In SLUB the memory policies are applied on a
per page frame / folio bases. Doing so avoids having to check memory
policies in critical code paths for kmalloc and friends.

This worked well on Intel/AMD/PowerPC because the
interconnect technology is mature and can minimize the latencies
through intelligent caching even if some small objects are not
placed optimally.

However, on ARM we have the emergence of new NUMA interconnect
technology based more on embedded devices. Caching of remote content
can currently be ineffective using the standard building blocks / mesh
available on that platform. Such architectures benefit if each slab
object is individually placed according to memory policies.

This patch adds another kernel parameter

	slab_strict_numa

If that is set then a static branch is activated that will cause
the hotpaths of the allocator to evaluate the current memory
allocation policy. Each object will be properly placed by
paying the price of extra processing and SLUB will no longer
defer to the page allocator to apply memory policies at the
folio level.

Signed-off-by: Christoph Lameter (Ampere) <cl@gentwo.org>
---
This is a draft to discuss the issue. It builds but was never run.
---
 mm/slub.c | 27 +++++++++++++++++++++++++++
 1 file changed, 27 insertions(+)

diff --git a/mm/slub.c b/mm/slub.c
index c9d8a2497fd6..c86e7ee9520a 100644
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
@@ -3825,6 +3829,14 @@ static __always_inline void *__slab_alloc_node(struct kmem_cache *s,
 	unsigned long tid;
 	void *object;
 
+#ifdef CONFIG_NUMA
+
+	if (static_branch_unlikely(&strict_numa) && node == NUMA_NO_NODE)
+
+		node = mempolicy_slab_node();
+
+#endif
+
 redo:
 	/*
 	 * Must read kmem_cache cpu data via this cpu ptr. Preemption is
@@ -5523,6 +5535,21 @@ static int __init setup_slub_min_objects(char *str)
 __setup("slab_min_objects=", setup_slub_min_objects);
 __setup_param("slub_min_objects=", slub_min_objects, setup_slub_min_objects, 0);
 
+#ifdef CONFIG_NUMA
+static int __init setup_slab_strict_numa(char *str)
+{
+	if (nr_node_ids > 1)
+		static_branch_enable(&strict_numa);
+	else
+		pr_warn("slab_strict_numa parameter set on non NUMA system.\n");
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
base-commit: 6e4436539ae182dc86d57d13849862bcafaa4709
change-id: 20240819-strict_numa-fc59b33123a2

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

