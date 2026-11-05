From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 22:28:50 +0000
Subject: [PATCH 1/3] KVM: arm64: Compute the hyp pool size in 64 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-hyp-pool-and-map-v1-1-756bb5d8e067@cs.columbia.edu>
References: <20261105-hyp-pool-and-map-v1-0-756bb5d8e067@cs.columbia.edu>
In-Reply-To: <20261105-hyp-pool-and-map-v1-0-756bb5d8e067@cs.columbia.edu>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>
Cc: Quentin Perret <qperret@google.com>, Will Deacon <will@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, 
 Mark Rutland <mark.rutland@arm.com>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xuheng Li <xuheng@cs.columbia.edu>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793917729; l=2873;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=UxuVgBjPBETyOHIqHbEHAWaoxXnBBnvVmnBeY1ybafA=;
 b=j9yH+aaCv6O2qR5kWkR35pr2U+iHzJ4e49Ta/xuKRt8WMXlEXE3VrDsW3x/tw1Ag3OsxxiFMq
 s0jXWQBw68lBQs2POH+PpP/WYzowh9qbNa32gIpdjHLnA3+Krye1ZQ8
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hyp_pool_init() takes the pool size as an unsigned int number of pages
and computes the size in bytes as nr_pages << PAGE_SHIFT, in 32 bits.
For a pool of 4 GiB or more (nr_pages >= 2^20 with 4 KiB pages) the
shift overflows, and both pool->range_end and pool->max_order are
derived from the truncated size.

The two large pools are sized from the amount of memory:
hyp_s1_pgtable_pages() for hpool and host_s2_pgtable_pages() for
host_s2_pool both provision page-granular tables for all of memory,
about one page per 2 MiB of RAM, so they reach 4 GiB on a machine with
about 2 TiB of RAM.  Arm systems of that size exist, for example AWS
Graviton4 x8g.metal-48xl instances (3 TiB) and Ampere Altra Max
servers (up to 4 TiB per socket).

With a truncated range_end, most of the pool lies outside
[range_start, range_end), so __hyp_attach_page() treats those pages as
external order-0 pages that never coalesce, and the pool cannot satisfy
multi-page allocations.  What that does depends on the host's IPA size,
since the only multi-page allocation from these pools is the host
stage-2 PGD in host_s2_zalloc_pages_exact():

 - With a 44- or 48-bit PARange the PGD is a single page.  pKVM boots,
   but both pools run with a wrong range and maximum order, and any
   later multi-page allocation from them would fail.

 - With a 42-bit PARange the PGD is eight concatenated level-1 tables.
   Its allocation fails, and host_s2_zalloc_pages_exact() calls
   hyp_split_page() on the result before checking it for NULL, so pKVM
   initialisation operates on a bogus struct hyp_page instead of failing
   with -ENOMEM.

Compute the size in 64 bits.

Fixes: 8e17c66249e9 ("KVM: arm64: Introduce a Hyp buddy page allocator")
Cc: stable@vger.kernel.org
Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
 arch/arm64/kvm/hyp/nvhe/page_alloc.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/page_alloc.c b/arch/arm64/kvm/hyp/nvhe/page_alloc.c
index 57f86aa0f..e7c10d2f7 100644
--- a/arch/arm64/kvm/hyp/nvhe/page_alloc.c
+++ b/arch/arm64/kvm/hyp/nvhe/page_alloc.c
@@ -233,16 +233,16 @@ int hyp_pool_init(struct hyp_pool *pool, u64 pfn, unsigned int nr_pages,
 		  unsigned int reserved_pages)
 {
 	phys_addr_t phys = hyp_pfn_to_phys(pfn);
+	u64 size = (u64)nr_pages << PAGE_SHIFT;
 	struct hyp_page *p;
 	int i;
 
 	hyp_spin_lock_init(&pool->lock);
-	pool->max_order = min(MAX_PAGE_ORDER,
-			      get_order(nr_pages << PAGE_SHIFT));
+	pool->max_order = min(MAX_PAGE_ORDER, get_order(size));
 	for (i = 0; i <= pool->max_order; i++)
 		INIT_LIST_HEAD(&pool->free_area[i]);
 	pool->range_start = phys;
-	pool->range_end = phys + (nr_pages << PAGE_SHIFT);
+	pool->range_end = phys + size;
 
 	/* Init the vmemmap portion */
 	p = hyp_phys_to_page(phys);

-- 
2.53.0

