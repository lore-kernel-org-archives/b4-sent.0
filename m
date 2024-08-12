From: Christoph Lameter <cl@gentwo.org>
Date: Mon, 12 Aug 2024 10:55:06 -0700
Subject: [PATCH] Reenable NUMA policy support in the slab allocator
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240812-numa_policy-v1-1-1732602b976c@gentwo.org>
X-B4-Tracking: v=1; b=H4sIAHlMumYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCwMz3bzS3MT4gvyczORKXVNDC4s0E5OkRIMUCyWgjoKi1LTMCrBp0bG
 1tQCMAoOGXQAAAA==
To: "Matthew Wilcox (Oracle)" <willy@infradead.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Pekka Enberg <penberg@kernel.org>, 
 David Rientjes <rientjes@google.com>, Joonsoo Kim <iamjoonsoo.kim@lge.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Vlastimil Babka <vbabka@suse.cz>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Hyeonggon Yoo <42.hyeyoo@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Christoph Lameter <cl@gentwo.org>
X-Mailer: b4 0.15-dev-37811
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723485315; l=2030;
 i=cl@gentwo.org; s=20240811; h=from:subject:message-id;
 bh=oIsOUj+s52JxQUrLe0TMZXCQFfAgTyXqoXTDzKem1MA=;
 b=Z286VwSdQVPVNRMc582ozWP7NFSxGLmQwBaCtj9kzM80sRwA6XOkZDFrPl4wKma09vPviLxBh
 p5zaM/WaXQaCAi00LCfffQoEJ69rjA3c7EcHqnOIkayhvpRYMQaRcRQ
X-Developer-Key: i=cl@gentwo.org; a=ed25519;
 pk=I7gqGwDi9drzCReFIuf2k9de1FI1BGibsshXI0DIvq8=
X-Endpoint-Received: by B4 Relay for cl@gentwo.org/20240811 with auth_id=194
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Revert commit 8014c46ad991f05b15ffbc0c6ae130bdf911187b
("slub: use alloc_pages_node() in alloc_slab_page()").

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
on a single node if f.e. a certain process does the memory allocation on
behalf of all the other processes.

SLUB does not apply memory policies to individual object allocations.
However, it relies on the page allocators support of memory policies
through alloc_pages() to do the NUMA memory allocations on a per
folio or page level. SLUB also applies memory policies when retrieving
partial allocated slab pages from the partial list.

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
base-commit: d74da846046aeec9333e802f5918bd3261fb5509
change-id: 20240806-numa_policy-5188f44ba0d8

Best regards,
-- 
Christoph Lameter <cl@gentwo.org>

