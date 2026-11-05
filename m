From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Thu, 05 Nov 2026 22:28:52 +0000
Subject: [PATCH 3/3] KVM: arm64: Don't replace a valid hyp block mapping
 with a table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261105-hyp-pool-and-map-v1-3-756bb5d8e067@cs.columbia.edu>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793917729; l=1509;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=UqwLIs4gUAaU1DFo5IEMy2L+DohqOBeFqpV1fxyeXnM=;
 b=FLN/1if17KjTwirD2Rz8VRHYWeTjz3nnWvVapf24PLDZ6KrUxmcPXokTdK/ubpqkdY/77p2E9
 1RZwNGDprENAgXH5e7C9pN2Tbjy7DQw92MVuxGaz0HR/0ceepxq2bIW
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When kvm_pgtable_hyp_map() is asked to map part of a range that a valid
block mapping already covers, hyp_map_walker_try_leaf() declines, as the
request cannot be a leaf at the block's level.  hyp_map_walker() then
allocates a zeroed table and stores it over the valid block entry.  The
walk descends into the new table and maps the requested pages, but the
rest of the block is now unmapped, and the valid block was replaced
without break-before-make.

No in-tree caller maps into an existing hyp block mapping today, so this
cannot be triggered in mainline.  Fail such a request with -EEXIST
instead, so that a future caller gets an error rather than silently
losing the rest of the block.

Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
 arch/arm64/kvm/hyp/pgtable.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/kvm/hyp/pgtable.c b/arch/arm64/kvm/hyp/pgtable.c
index 9c83837b1..4c731b101 100644
--- a/arch/arm64/kvm/hyp/pgtable.c
+++ b/arch/arm64/kvm/hyp/pgtable.c
@@ -434,6 +434,13 @@ static int hyp_map_walker(const struct kvm_pgtable_visit_ctx *ctx,
 	if (WARN_ON(ctx->level == KVM_PGTABLE_LAST_LEVEL))
 		return -EINVAL;
 
+	/*
+	 * Replacing a valid block with a table would need break-before-make,
+	 * and the new table would leave the rest of the block unmapped.
+	 */
+	if (WARN_ON(kvm_pte_valid(ctx->old)))
+		return -EEXIST;
+
 	childp = (kvm_pte_t *)mm_ops->zalloc_page(NULL);
 	if (!childp)
 		return -ENOMEM;

-- 
2.53.0

