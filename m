From: Xie Bo <xb@ultrarisc.com>
Date: Mon, 10 Aug 2026 09:21:15 +0800
Subject: [PATCH v2] RISC-V: KVM: Serialize IMSIC attributes with vCPU
 migration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-imsic-attr-race-v2-1-00ed95ad321e@ultrarisc.com>
X-B4-Tracking: v=1; b=H4sIAIoneWoC/43Oyw6CMBCF4VchXTukLZeqK9/DsKh1kEmEmmklG
 NJ3t7Bx6/JfnC9nFQGZMIhzsQrGmQL5KYc+FMINdnog0D230FK38qgk0BjIgY2Rga1DkK0x2sq
 6biSKvHox9rTs4rXL3bMfIQ6M9ucYraSpWqVLVRndnEDBcru8n5EtU3Cl8+NGDRSi58/+bVYb+
 P+8Syl9AfhrvaPdAAAA
In-Reply-To: <20260721073612.137259-1-xb@ultrarisc.com>
References: <20260721073612.137259-1-xb@ultrarisc.com>
To: Anup Patel <anup@brainfault.org>
Cc: Atish Patra <atish.patra@linux.dev>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>, kvm@vger.kernel.org, 
 kvm-riscv@lists.infradead.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Xie Bo <xb@ultrarisc.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786324887; l=2118;
 i=xb@ultrarisc.com; s=20260810; h=from:subject:message-id;
 bh=FN+s+dZU8x/9zYsAqO7dZdJ8/YEPF8j1I2LUPLYxSPg=;
 b=At33xJ3dHR0j9wXFxdIzEYGU5MBM29ywdU+QrQSNgCvRQNCU4eMc6niylLaA2OdmR+6z77Yzu
 7ObKeiaeOz/CkmbCVfPYMdMk6cLpWur30kpe8VcTE2Kd5XihS+Wycvq
X-Developer-Key: i=xb@ultrarisc.com; a=ed25519;
 pk=Yb4TfiqO0TRwfKy3wvnt0+tbk0/QQQ42+O1jBrVaWq0=
X-Endpoint-Received: by B4 Relay for xb@ultrarisc.com/20260810 with auth_id=933
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KVM device ioctls are not serialized against KVM_RUN. As a result,
kvm_riscv_aia_imsic_rw_attr() can snapshot the physical CPU and HGEI of
an IMSIC VS-file before a concurrent vCPU migration releases it.

The HGEI can then be allocated to another vCPU before imsic_vsfile_rw()
uses the stale tuple. A GET or SET attribute may consequently access the
new owner's interrupt file.

Serialize the entire IMSIC attribute operation with the target vCPU
mutex. This prevents the VS-file from being migrated and recycled until
the attribute access completes. Acquire the mutex killably so that the
device ioctl remains interruptible while waiting for KVM_RUN to finish.

Fixes: db8b7e97d613 ("RISC-V: KVM: Add in-kernel virtualization of AIA IMSIC")
Cc: stable@vger.kernel.org
Signed-off-by: Xie Bo <xb@ultrarisc.com>
---
Changes in v2:
- Use mutex_lock_killable() and return -EINTR when interrupted.

Link: https://lore.kernel.org/r/20260721073612.137259-1-xb@ultrarisc.com
---
 arch/riscv/kvm/aia_imsic.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/arch/riscv/kvm/aia_imsic.c b/arch/riscv/kvm/aia_imsic.c
index d38f5de08..74f520e57 100644
--- a/arch/riscv/kvm/aia_imsic.c
+++ b/arch/riscv/kvm/aia_imsic.c
@@ -969,9 +969,14 @@ int kvm_riscv_aia_imsic_rw_attr(struct kvm *kvm, unsigned long type,
 	if (!vcpu)
 		return -ENODEV;
 
+	if (mutex_lock_killable(&vcpu->mutex))
+		return -EINTR;
+
 	imsic = vcpu->arch.aia_context.imsic_state;
-	if (!imsic)
-		return -ENODEV;
+	if (!imsic) {
+		rc = -ENODEV;
+		goto out_unlock;
+	}
 	isel = KVM_DEV_RISCV_AIA_IMSIC_GET_ISEL(type);
 
 	read_lock_irqsave(&imsic->vsfile_lock, flags);
@@ -995,6 +1000,8 @@ int kvm_riscv_aia_imsic_rw_attr(struct kvm *kvm, unsigned long type,
 		rc = imsic_vsfile_rw(vsfile_hgei, vsfile_cpu, imsic->nr_eix,
 				     isel, write, val);
 
+out_unlock:
+	mutex_unlock(&vcpu->mutex);
 	return rc;
 }
 

---
base-commit: b95f03f04d475aa6719d15a636ddf32222d55657
change-id: 20260810-imsic-attr-race-06772a04450e

Best regards,
-- 
Xie Bo <xb@ultrarisc.com>

