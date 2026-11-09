From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Mon, 09 Nov 2026 22:13:35 +0000
Subject: [PATCH v3] KVM: arm64: Don't replace a valid hyp block mapping
 with a table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-hyp-block-map-v3-1-bd70e67eb0bf@cs.columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNL3YzKAt2knPzkbN3cxAJdg2RDyzSLVEsTI5MkJaCegqLUtMwKsHn
 RsbW1AAtSsWxfAAAA
X-Change-ID: 20261109-hyp-block-map-0c19f8e9424b
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>
Cc: Vincent Donnefort <vdonnefort@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>, Quentin Perret <qperret@google.com>, 
 Will Deacon <will@kernel.org>, Mostafa Saleh <smostafa@google.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, 
 Mark Rutland <mark.rutland@arm.com>, Joey Gouly <joey.gouly@arm.com>, 
 Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794262414; l=3910;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=RIFjoI85KP24Rv3faoa4T6ksq6aQB6AW6n6O+fZ4Jw8=;
 b=j9SVzqCiLPkNYh1JWfLZitE9GNR+YyVV3Ivtx30mdQziJtNsmwtvPjrAxpTl0xi4hvgf6t9DV
 V55yyGreT2AB+KHnSiw9xKu79OZs9NymAKLF9eebBOAkIIPPYE1xU6K
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

The same check now catches a conflicting remap of an existing leaf, so
drop the WARN_ON() from hyp_map_walker_try_leaf(): every caller checks
the error, and a WARN is fatal at EL2.  Do the check before the
last-level WARN_ON(), which is kept for internal errors, and update the
kernel-doc of kvm_pgtable_hyp_map() to match.

Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
This is patch 3/3 of v2, sent alone: 1/3 is superseded by Mostafa's
"KVM: arm64: Use consistent type for pool size" [1], and 2/3 is dropped.

With the WARN_ON() gone from hyp_map_walker_try_leaf(), a conflicting
remap through the EL1 path (__create_hyp_mappings()) also returns
-EEXIST without a warning, where it used to warn and return -EINVAL.

[1] https://lore.kernel.org/r/20261106172750.2678873-1-smostafa@google.com
---
Changes in v3:
- Drop the WARN_ON() from the new check and from
  hyp_map_walker_try_leaf(), and update the kernel-doc of
  kvm_pgtable_hyp_map() (Vincent, Fuad).
- Do the check before the last-level WARN_ON(), so that a conflicting
  page-level mapping returns -EEXIST instead of reaching it.
- Link to v2: https://lore.kernel.org/r/20261105-hyp-pool-and-map-v2-3-44a6ca90190b@cs.columbia.edu
---
 arch/arm64/include/asm/kvm_pgtable.h |  2 +-
 arch/arm64/kvm/hyp/pgtable.c         | 10 +++++++++-
 2 files changed, 10 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/include/asm/kvm_pgtable.h b/arch/arm64/include/asm/kvm_pgtable.h
index 1c9c57cd6..6d6ed8596 100644
--- a/arch/arm64/include/asm/kvm_pgtable.h
+++ b/arch/arm64/include/asm/kvm_pgtable.h
@@ -508,7 +508,7 @@ void kvm_pgtable_hyp_destroy(struct kvm_pgtable *pgt);
  * If device attributes are not explicitly requested in @prot, then the
  * mapping will be normal, cacheable. Attempts to install a new mapping
  * for a virtual address that is already mapped will be rejected with an
- * error and a WARN().
+ * error.
  *
  * Return: 0 on success, negative error code on failure.
  */
diff --git a/arch/arm64/kvm/hyp/pgtable.c b/arch/arm64/kvm/hyp/pgtable.c
index 9c83837b1..94a59f29a 100644
--- a/arch/arm64/kvm/hyp/pgtable.c
+++ b/arch/arm64/kvm/hyp/pgtable.c
@@ -414,7 +414,7 @@ static bool hyp_map_walker_try_leaf(const struct kvm_pgtable_visit_ctx *ctx,
 		return true;
 	if (!kvm_pte_valid(ctx->old))
 		ctx->mm_ops->get_page(ctx->ptep);
-	else if (WARN_ON((ctx->old ^ new) & ~KVM_PTE_LEAF_ATTR_HI_SW))
+	else if ((ctx->old ^ new) & ~KVM_PTE_LEAF_ATTR_HI_SW)
 		return false;
 
 	smp_store_release(ctx->ptep, new);
@@ -431,6 +431,14 @@ static int hyp_map_walker(const struct kvm_pgtable_visit_ctx *ctx,
 	if (hyp_map_walker_try_leaf(ctx, data))
 		return 0;
 
+	/*
+	 * A valid entry here is a leaf that conflicts with the request.
+	 * Replacing a block with a table would need break-before-make, and
+	 * would leave the rest of the block unmapped.
+	 */
+	if (kvm_pte_valid(ctx->old))
+		return -EEXIST;
+
 	if (WARN_ON(ctx->level == KVM_PGTABLE_LAST_LEVEL))
 		return -EINVAL;
 

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261109-hyp-block-map-0c19f8e9424b

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

