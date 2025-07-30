From: Per Larsen <perlarsen@google.com>
Date: Wed, 30 Jul 2025 21:15:04 +0000
Subject: [PATCH v9 1/6] KVM: arm64: Correct return value on host version
 downgrade attempt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250730-virtio-msg-ffa-v9-1-7f1b55c8d149@google.com>
References: <20250730-virtio-msg-ffa-v9-0-7f1b55c8d149@google.com>
In-Reply-To: <20250730-virtio-msg-ffa-v9-0-7f1b55c8d149@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, ahomescu@google.com, armellel@google.com, 
 arve@android.com, ayrton@google.com, qperret@google.com, 
 sebastianene@google.com, qwandor@google.com, 
 Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753910116; l=1399;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=P+lmb3sotGE8m34PBEfN/prSolKXtIpxrlMSQIy5CgE=;
 b=VKzFYOmcY0g8SQT9dFrjRsgwYo/TQGIlpS1AMrLT5Fz0mUdsn2nlcFi9n9U8XRR0V/4CPVnn1
 9X2bF0wPHL4BHihowB+PK5QTAl3dw8KfYS5jViTtx1u6yIQGIVfJnUP
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Once the hypervisor negotiates the FF-A version with the host, it should
remain locked-in. However, it is possible to load FF-A as a module first
supporting version 1.1 and then 1.0.

Without this patch, the FF-A 1.0 driver will use 1.0 data structures to
make calls which the hypervisor will incorrectly interpret as 1.1 data
structures. With this patch, negotiation will fail.

This patch does not change existing functionality in the case where a
FF-A 1.2 driver is loaded after a 1.1 driver; the 1.2 driver will need
to use 1.1 in order to proceed.

Acked-by: Will Deacon <will@kernel.org>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 3369dd0c4009f84ad3cf9481c747bdc57a162370..2c199d40811efb5bfae199c4a67d8ae3d9307357 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -712,7 +712,10 @@ static void do_ffa_version(struct arm_smccc_res *res,
 
 	hyp_spin_lock(&version_lock);
 	if (has_version_negotiated) {
-		res->a0 = hyp_ffa_version;
+		if (FFA_MINOR_VERSION(ffa_req_version) < FFA_MINOR_VERSION(hyp_ffa_version))
+			res->a0 = FFA_RET_NOT_SUPPORTED;
+		else
+			res->a0 = hyp_ffa_version;
 		goto unlock;
 	}
 

-- 
2.50.1.552.g942d659e1b-goog

