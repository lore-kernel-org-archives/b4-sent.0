From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 22:59:48 +0000
Subject: [PATCH v2 1/3] KVM: arm64: Compute hyp early-allocation and pool
 sizes in 64 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-hyp-pool-and-map-v2-1-44a6ca90190b@cs.columbia.edu>
References: <20261105-hyp-pool-and-map-v2-0-44a6ca90190b@cs.columbia.edu>
In-Reply-To: <20261105-hyp-pool-and-map-v2-0-44a6ca90190b@cs.columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793919587; l=3382;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=X5zU9gd0/pnazNbILmVOr0uKyLVNYG+93eBtX8egCgU=;
 b=LqShZxLLsCWkqR33ccGO7h/LdAeTf+PNFAx+Xe+7n2OfRV+wV5cEeW1Lv5RF0HlLlcrurlta8
 6w2qFGnPnc1AnsuA1wFVdjo55XDX/DwojSoNMruLzn/SrazrlO+hX6L
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hyp_early_alloc_contig() and hyp_pool_init() both take a page count as
an unsigned int and compute the size in bytes as nr_pages << PAGE_SHIFT
in 32 bits.  For 4 GiB or more (nr_pages >= 2^20 with 4 KiB pages) the
shift overflows.

Two of the regions that pKVM carves out at boot are sized from the
amount of memory: hyp_s1_pgtable_pages() for the hyp page tables (hpool)
and host_s2_pgtable_pages() for the host stage-2 pool both provision
page-granular tables for all of memory, about one page per 2 MiB of
RAM, so they reach 4 GiB on a machine with about 2 TiB of RAM.  Arm
systems of that size exist, for example AWS Graviton4 x8g.metal-48xl
instances (3 TiB) and Ampere Altra Max servers (up to 4 TiB per
socket).

On such a machine, divide_memory_pool() gets a truncated hyp page-table
region from hyp_early_alloc_contig(), so the host stage-2 region and the
FF-A proxy pages that follow it start inside the range that hpool will
own.  hyp_pool_init() then attaches all nr_pages pages of each pool to
its free lists, so hpool and host_s2_pool share pages and the same page
can be handed out twice, for example as a hyp stage-1 table and as a
host stage-2 table.  hyp_pool_init() also derives range_end and
max_order from the truncated size, so most of each pool is treated as
external order-0 pages; on a host whose IPA size makes the host stage-2
PGD a multi-page allocation (for example a 42-bit PARange), that
allocation fails and host_s2_zalloc_pages_exact() uses the NULL result.

Compute both sizes in 64 bits.

Fixes: e75960408723 ("KVM: arm64: Introduce an early Hyp page allocator")
Fixes: 8e17c66249e9 ("KVM: arm64: Introduce a Hyp buddy page allocator")
Cc: stable@vger.kernel.org
Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
 arch/arm64/kvm/hyp/nvhe/early_alloc.c | 2 +-
 arch/arm64/kvm/hyp/nvhe/page_alloc.c  | 6 +++---
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/early_alloc.c b/arch/arm64/kvm/hyp/nvhe/early_alloc.c
index 00de04153..f435f89be 100644
--- a/arch/arm64/kvm/hyp/nvhe/early_alloc.c
+++ b/arch/arm64/kvm/hyp/nvhe/early_alloc.c
@@ -23,7 +23,7 @@ unsigned long hyp_early_alloc_nr_used_pages(void)
 
 void *hyp_early_alloc_contig(unsigned int nr_pages)
 {
-	unsigned long size = (nr_pages << PAGE_SHIFT);
+	unsigned long size = (unsigned long)nr_pages << PAGE_SHIFT;
 	void *ret = (void *)cur;
 
 	if (!nr_pages)
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

