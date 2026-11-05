From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 22:28:51 +0000
Subject: [PATCH 2/3] KVM: arm64: Check the host stage-2 PGD allocation for
 NULL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-hyp-pool-and-map-v1-2-756bb5d8e067@cs.columbia.edu>
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
 Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793917729; l=1285;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=XdIMBDSmGASRQbiHAq1YVe0xT84zqEKj8tGXxAjv0Fc=;
 b=zdxMZTP1ibxSaWoIJZCsCe1ZYXxUtb0lDuKtMIn1ad4RQ5OA8he3O6H1zy9UIpexvI1IJQU+e
 voejNVx2PkuDEQWrUzeAPzgPZ8jUMFUElP2T1SshCeE144SQiVs1u5O
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

host_s2_zalloc_pages_exact() passes the result of hyp_alloc_pages() to
hyp_split_page(hyp_virt_to_page(addr)) without checking it for NULL.
If the host stage-2 pool cannot supply the PGD, hyp_virt_to_page(NULL)
yields a bogus struct hyp_page, and hyp_split_page() reads and writes
through it, which ends in a hyp panic during pKVM initialisation
although kvm_pgtable_stage2_init() is prepared to fail with -ENOMEM.

The pool is sized so that this allocation, the first one made from it,
cannot fail, so nothing in mainline reaches this path once the pool
size is computed correctly.  Return NULL early anyway, so that a
mis-sized pool makes initialisation fail cleanly.

Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
 arch/arm64/kvm/hyp/nvhe/mem_protect.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/mem_protect.c b/arch/arm64/kvm/hyp/nvhe/mem_protect.c
index d4c332a91..ee0848f2e 100644
--- a/arch/arm64/kvm/hyp/nvhe/mem_protect.c
+++ b/arch/arm64/kvm/hyp/nvhe/mem_protect.c
@@ -85,6 +85,9 @@ static void *host_s2_zalloc_pages_exact(size_t size)
 {
 	void *addr = hyp_alloc_pages(&host_s2_pool, get_order(size));
 
+	if (!addr)
+		return NULL;
+
 	hyp_split_page(hyp_virt_to_page(addr));
 
 	/*

-- 
2.53.0

