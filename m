From: Xuheng Li <xuheng@cs.columbia.edu>
Subject: [PATCH 0/3] KVM: arm64: Fix the hyp pool size on large machines,
 plus two hardening patches
Date: Thu, 05 Nov 2026 22:28:49 +0000
Message-Id: <20261105-hyp-pool-and-map-v1-0-756bb5d8e067@cs.columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBtohAq7SrSwnGqgVBSiiO6et
 HyL/x/InIQz9OqBxKdkCb6AKgXzZv3KKK4YdK1borrB7Y4YQ9jReoeHjTg13E1sLJEhKFlMvMj
 1L4fxfT/QCcPTYgAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793917729; l=1436;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=gQekyKtD9gqE06JU2ATVEtl2lW315Pl8Hsi4FhanixE=;
 b=4VskGk/nnncCTlFFpyv3yW8wjN2DEulU4CGjyKuATzAXd5ZtSIs40RgAyCWjcH90faDMofvwW
 QBW4Q1u4euzD8W3zGQ3dJBTFllXoV432+H67kpL3UW0tDIXSTi0QnmS
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three changes for issues we found in pKVM as part of our research
project.

Patch 1 fixes a 32-bit size computation in hyp_pool_init(): a pool of
4 GiB or more gets a truncated range and maximum order.  hpool and
host_s2_pool reach that size on machines with about 2 TiB of RAM.

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
Xuheng Li (3):
      KVM: arm64: Compute the hyp pool size in 64 bits
      KVM: arm64: Check the host stage-2 PGD allocation for NULL
      KVM: arm64: Don't replace a valid hyp block mapping with a table

 arch/arm64/kvm/hyp/nvhe/mem_protect.c | 3 +++
 arch/arm64/kvm/hyp/nvhe/page_alloc.c  | 6 +++---
 arch/arm64/kvm/hyp/pgtable.c          | 7 +++++++
 3 files changed, 13 insertions(+), 3 deletions(-)
---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261105-hyp-pool-and-map-b5e7be9a1191

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

