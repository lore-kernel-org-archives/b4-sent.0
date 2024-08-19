From: Christoph Lameter <cl@gentwo.org>
Date: Mon, 19 Aug 2024 11:54:05 -0700
Subject: [PATCH] Reenable NUMA policy support in the slab allocator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240819-numa_policy-v1-1-f096cff543ee@gentwo.org>
X-B4-Tracking: v=1; b=H4sIAMyUw2YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCwMz3bzS3MT4gvyczORKXVNDC4s0E5OkRIMUCyWgjoKi1LTMCrBp0bG
 1tQCMAoOGXQAAAA==
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Pekka Enberg <penberg@kernel.org>, 
 David Rientjes <rientjes@google.com>, Joonsoo Kim <iamjoonsoo.kim@lge.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Vlastimil Babka <vbabka@suse.cz>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Hyeonggon Yoo <42.hyeyoo@gmail.com>, Yang Shi <shy828301@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, stable@kernel.org, 
 Christoph Lameter <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724093662; l=2013;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=OdcUj5iCsDbP03VJBF3jAH+o1SUhMTMBiGyFaXIVG7g=;
 b=gt+6QhcxVDLtFNAaF7Ic9x8x+uWCYrJj/boApPxkXOD0mMiKbIrYlvMiqR9Sh7PT1It4+B+Eo
 x0tBHn9Rn92DAmzESSk0AYEKhcsKgQLpO4nDXPiEsJ/U2J39Nf8okst
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Revert commit 8014c46ad991 ("slub: use alloc_pages_node() in alloc_slab_page()").

The patch disabled the numa policy support in the slab allocator. It
did not consider that alloc_pages() uses memory policies but
alloc_pages_node() does not.

As a result of this patch slab memory allocations are no longer spread via
interleave policy across all available NUMA nodes on bootup. Instead
all slab memory is allocated close to the boot processor. This leads to
an imbalance of memory accesses on NUMA systems.

Also applications using MPOL_INTERLEAVE as a memory policy will no longer
spread slab allocations over all nodes in the interleave set but allocate
memory locally. This may also result in unbalanced allocations
on a single numa node.

SLUB does not apply memory policies to individual object allocations.
However, it relies on the page allocators support of memory policies
through alloc_pages() to do the NUMA memory allocations on a per
folio or page level. SLUB also applies memory policies when retrieving
partial allocated slab pages from the partial list.

Fixes: 8014c46ad991 ("slub: use alloc_pages_node() in alloc_slab_page()")
Cc: stable@kernel.org
Signed-off-by: Christoph Lameter <cl@gentwo.org>
---
 mm/slub.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/mm/slub.c b/mm/slub.c
index c9d8a2497fd6..4dea3c7df5ad 100644
--- a/mm/slub.c
+++ b/mm/slub.c
@@ -2318,7 +2318,11 @@ static inline struct slab *alloc_slab_page(gfp_t flags, int node,
 	struct slab *slab;
 	unsigned int order = oo_order(oo);
 
-	folio = (struct folio *)alloc_pages_node(node, flags, order);
+	if (node == NUMA_NO_NODE)
+		folio = (struct folio *)alloc_pages(flags, order);
+	else
+		folio = (struct folio *)__alloc_pages_node(node, flags, order);
+
 	if (!folio)
 		return NULL;
 

---
base-commit: b0da640826ba3b6506b4996a6b23a429235e6923
change-id: 20240806-numa_policy-5188f44ba0d8

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

