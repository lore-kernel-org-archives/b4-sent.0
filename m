From: Xuheng Li <xuheng@cs.columbia.edu>
Subject: [PATCH v2 0/3] KVM: arm64: Fix the hyp pool size on large
 machines, plus two hardening patches
Date: Thu, 05 Nov 2026 22:59:47 +0000
Message-Id: <20261105-hyp-pool-and-map-v2-0-44a6ca90190b@cs.columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQqDMBBFryKz7khGiNaueo/iIjHTOqAmJFUq4
 t2beoAu34P//g6Jo3CCW7FD5FWS+DlDdSmgH8z8YhSXGSpV1URK47AFDN6PaGaHkwloNTeWW0P
 UEuRZiPyUz5l8dJkHSW8ft/NhpZ/9E1sJFTa6tla7K6u6ufep7P24TFZMyW6B7jiOLz0pGeS2A
 AAA
X-Change-ID: 20261105-hyp-pool-and-map-b5e7be9a1191
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793919587; l=1934;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=CAOlYbJH00SZ0i+KHyNqqm2Di8dpY/YNVVprTboRUdo=;
 b=c1X/nyAlwsURpe72dwNz4wB9yo7f6Xx60mT0l5jS7LojUn/cgTuWMddWKw/TsCvXlYu41zll8
 XqC4R8vzMtCCkFzXTCd4CKrg+/ZfCIGYmt4qkNKIPTZebWkZn+MPamQ
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three changes for issues we found in pKVM as part of our research
project.

Patch 1 fixes 32-bit size computations in hyp_early_alloc_contig()
and hyp_pool_init().  The hyp page-table and host stage-2 regions reach
4 GiB on machines with about 2 TiB of RAM; the early allocator then
carves them too small, so the two pools overlap and can hand out the
same page twice.

Patch 2 checks the host stage-2 PGD allocation for NULL before using
it.  With patch 1 applied that allocation cannot fail, so this only
turns a mis-sized pool into a clean -ENOMEM instead of a hyp panic.

Patch 3 makes hyp_map_walker() refuse to replace a valid block mapping
with a table, which would skip break-before-make and unmap the rest of
the block.  Nothing in mainline maps into an existing hyp block, so this
is hardening; Android's interface for EL2 modules to map pages can reach
it.

Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
Changes in v2:
- Patch 1: also fix the same overflow in hyp_early_alloc_contig(), which
  makes hpool and host_s2_pool overlap (reported by the Sashiko review of
  v1); describe that in the commit message and add its Fixes: tag.
- Link to v1: https://lore.kernel.org/r/20261105-hyp-pool-and-map-v1-0-756bb5d8e067@cs.columbia.edu

---
Xuheng Li (3):
      KVM: arm64: Compute hyp early-allocation and pool sizes in 64 bits
      KVM: arm64: Check the host stage-2 PGD allocation for NULL
      KVM: arm64: Don't replace a valid hyp block mapping with a table

 arch/arm64/kvm/hyp/nvhe/early_alloc.c | 2 +-
 arch/arm64/kvm/hyp/nvhe/mem_protect.c | 3 +++
 arch/arm64/kvm/hyp/nvhe/page_alloc.c  | 6 +++---
 arch/arm64/kvm/hyp/pgtable.c          | 7 +++++++
 4 files changed, 14 insertions(+), 4 deletions(-)
---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261105-hyp-pool-and-map-b5e7be9a1191

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

