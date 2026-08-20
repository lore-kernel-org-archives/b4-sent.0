From: Kim Mankyum <mankyum.kim@samsung.com>
Date: Thu, 20 Aug 2026 14:42:31 +0900
Subject: [PATCH] KVM: arm64: Allow smaller FF-A RX/TX buffers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-master-v1-1-ea602b6d3860@samsung.com>
X-B4-Tracking: v=1; b=H4sIAMeThmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCyMD3dzE4pLUIl1TcyMTQ4tEY1OLxCQloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0AKBR3YWoAAAA=
X-Change-ID: 20260820-master-572418a358ab
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>, 
 Will Deacon <will@kernel.org>
Cc: Fuad Tabba <fuad.tabba@linux.dev>, Andrew Walbran <qwandor@google.com>, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Kim Mankyum <mankyum.kim@samsung.com>
X-Mailer: b4 0.17-dev-1f2f7
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787204579; l=1770;
 i=mankyum.kim@samsung.com; s=20260820; h=from:subject:message-id;
 bh=U52efmJXTVzb8RMYHZnmIqS8t9rchcBRv6qyuCeV+Vg=;
 b=dDXmHg0ktieaSq7oXc09SObUbo7VHQ21lTUDunWXpSJKaBcfxUJ7WC6oIQiaHrtskS44NfKup
 tFGxEU6qfnFDF5d75K/eI0rdDEMiR7aGY8u05cYXrDNN49hdefDtAnZ
X-Developer-Key: i=mankyum.kim@samsung.com; a=ed25519;
 pk=HN6chQ/xsDvZkhMY6iO4umFaQcr/drgbOI/tEzVYrSg=
X-Endpoint-Received: by B4 Relay for mankyum.kim@samsung.com/20260820 with auth_id=964
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pKVM currently requires the host to map PAGE_SIZE worth of RX/TX
buffers, as do_ffa_rxtx_map() requires the FF-A page count to match
the capacity of the hypervisor RX/TX buffers.

This is unnecessarily restrictive when the kernel page size is larger
than the minimum RX/TX buffer size advertised by the SPMC. For
example, with a 16K kernel and an SPMC advertising a minimum RX/TX
buffer size of 4K, a host request with a page count of one is rejected
by pKVM.

hyp_ffa_post_init() already allows an SPMC whose minimum RX/TX buffer
size is smaller than PAGE_SIZE, and the page count supplied by the host
is forwarded unchanged when mapping the hypervisor buffers into the
SPMC.

Allow RX/TX buffers smaller than the capacity of the hypervisor buffers
while continuing to reject requests which exceed it.

Fixes: 9d0c6a9af9e3 ("KVM: arm64: Handle FFA_RXTX_MAP and FFA_RXTX_UNMAP calls from the host")
Signed-off-by: Kim Mankyum <mankyum.kim@samsung.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index a327c2bbb6b6..594d1112b5f9 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -239,7 +239,8 @@ static void do_ffa_rxtx_map(struct arm_smccc_1_2_regs *res,
 	int ret = 0;
 	void *rx_virt, *tx_virt;
 
-	if (npages != (KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE) / FFA_PAGE_SIZE) {
+	if (!npages ||
+	    npages > (KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE) / FFA_PAGE_SIZE) {
 		ret = FFA_RET_INVALID_PARAMETERS;
 		goto out;
 	}

---
base-commit: cb8a75eec0877810b50aa1c5a833f929525cd2ee
change-id: 20260820-master-572418a358ab

Best regards,
--  
Kim Mankyum <mankyum.kim@samsung.com>

