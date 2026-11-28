From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 18:28:30 +0000
Subject: [PATCH 6.6.y] KVM: arm64: vgic-v3: take an LPI reference in
 vgic_v3_save_pending_tables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-vgic-66-v1-1-42c9b298dd47@certik.com>
X-B4-Tracking: v=1; b=H4sIAE0dC2sC/y2MQQ7CIBAAv9Ls2a2AKVG/YjwA3bZrDBi2Npqmf
 xfU40wms4JQZhI4NytkWlg4xQJ610CYXBwJuS8MRhmrtTniMnJAa9EPBwqdOnXKaSj1I9PAr+/
 pAra17RuuPy1Pf6Mw10sNvRNCn10MU1VCsZ9TumP1+/8dtu0Da8cLZZoAAAA=
X-Change-ID: 20261128-vgic-66-bf3ec50950a1
To: stable@vger.kernel.org
Cc: Qihang <q.h.hack.winter@gmail.com>, Oliver Upton <oupton@kernel.org>, 
 Marc Zyngier <maz@kernel.org>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795890509; l=5156;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=UY6rhXp3UTm9G5h9OzeaO1EkD8Fe6erxDeZcgb6uqxg=;
 b=+ewcjb/ddFuW/9+OrDUyaqW3XuFCj+IVrSuckw+tB9NHxweBuNnj+TlG5JSHuL/hDzOu9ofO5
 wOf6YUcp9IaB7mnKWlMTiwNQHvCJ8rqfOUk6n7MCOjyX3mxGyUsN36k
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Qihang <q.h.hack.winter@gmail.com>

commit f5b8f203bfc07a5a257dff859e66d2c500f9f509 upstream.

vgic_v3_save_pending_tables() iterates dist->lpi_xa using xa_for_each()
and dereferences the returned struct vgic_irq in the loop body without
holding a reference on the LPI.

The xarray iterator only provides temporary RCU coverage while looking up
the current entry. That is not sufficient for this loop body, which reads
fields from struct vgic_irq and performs guest memory accesses before the
iteration completes.

A concurrent path can trigger this race: the irqfd cached injection path
(vgic_its_inject_cached_translation) obtains a transient LPI reference
via vgic_its_check_cache() without holding kvm->lock, vcpu->mutex,
config_lock, or its_lock. If guest ITS DISCARD then drops the cache and
ITE references under its_lock, the transient inject reference may become
the final one. When vgic_put_irq() drops it, the LPI is erased from
lpi_xa and freed via kfree_rcu(). Meanwhile, vgic_v3_save_pending_tables()
may still hold a stale pointer obtained from the xarray iterator and
dereference it after the RCU grace period completes.

Fix this by re-fetching each iterated LPI via vgic_get_irq(), which takes
a stable reference, and dropping it with vgic_put_irq() on all paths.
This matches the pattern already used by other lpi_xa iterators in the
vgic ITS code.

Cc: stable@vger.kernel.org
Signed-off-by: Qihang <q.h.hack.winter@gmail.com>
Reviewed-by: Marc Zyngier <maz@kernel.org>
Link: https://patch.msgid.link/20260807025534.34125-1-q.h.hack.winter@gmail.com
Signed-off-by: Oliver Upton <oupton@kernel.org>
[ adapted to 6.6.y: pin each LPI under the list lock before use ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This one never made it to 6.6.y. 6.12.y got it as 4000462866bc, but
6.6 still keeps LPIs on lpi_list_head rather than the lpi_xa xarray,
so the upstream patch doesn't apply. The backport takes a reference on
each LPI under lpi_list_lock, drops the lock for the guest memory
accesses, then retakes it to step to the next entry and drop the
reference with __vgic_put_lpi_locked(). That's the same idea as
upstream's vgic_get_irq()/vgic_put_irq() pairing.

Tested on 6.6 (e2bb30811e06): arm64 W=1 build of vgic-v3.o, base vs
patched, no new warnings. Both kernels booted under QEMU TCG with KVM
initialized. The KVM vgic_init selftest fails the same way on both at
memslot deletion, so it doesn't cover this path, and I didn't hit the
race itself. Build and boot only.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 arch/arm64/kvm/vgic/vgic-v3.c | 22 +++++++++++++++++-----
 1 file changed, 17 insertions(+), 5 deletions(-)

diff --git a/arch/arm64/kvm/vgic/vgic-v3.c b/arch/arm64/kvm/vgic/vgic-v3.c
index 3dfc8b84e03e..a34c1b95964e 100644
--- a/arch/arm64/kvm/vgic/vgic-v3.c
+++ b/arch/arm64/kvm/vgic/vgic-v3.c
@@ -377,9 +377,11 @@ static void map_all_vpes(struct kvm *kvm)
 int vgic_v3_save_pending_tables(struct kvm *kvm)
 {
 	struct vgic_dist *dist = &kvm->arch.vgic;
-	struct vgic_irq *irq;
+	struct list_head *head = &dist->lpi_list_head;
+	struct vgic_irq *irq, *next;
 	gpa_t last_ptr = ~(gpa_t)0;
 	bool vlpi_avail = false;
+	unsigned long flags;
 	int ret = 0;
 	u8 val;
 
@@ -396,16 +398,21 @@ int vgic_v3_save_pending_tables(struct kvm *kvm)
 		vlpi_avail = true;
 	}
 
-	list_for_each_entry(irq, &dist->lpi_list_head, lpi_list) {
+	raw_spin_lock_irqsave(&dist->lpi_list_lock, flags);
+	for (irq = list_first_entry(head, struct vgic_irq, lpi_list);
+	     !list_entry_is_head(irq, head, lpi_list); irq = next) {
 		int byte_offset, bit_nr;
 		struct kvm_vcpu *vcpu;
 		gpa_t pendbase, ptr;
 		bool is_pending;
 		bool stored;
 
+		vgic_get_irq_kref(irq);
+		raw_spin_unlock_irqrestore(&dist->lpi_list_lock, flags);
+
 		vcpu = irq->target_vcpu;
 		if (!vcpu)
-			continue;
+			goto put_irq;
 
 		pendbase = GICR_PENDBASER_ADDRESS(vcpu->arch.vgic_cpu.pendbaser);
 
@@ -416,7 +423,7 @@ int vgic_v3_save_pending_tables(struct kvm *kvm)
 		if (ptr != last_ptr) {
 			ret = kvm_read_guest_lock(kvm, ptr, &val, 1);
 			if (ret)
-				goto out;
+				goto put_irq;
 			last_ptr = ptr;
 		}
 
@@ -428,7 +435,7 @@ int vgic_v3_save_pending_tables(struct kvm *kvm)
 			vgic_v4_get_vlpi_state(irq, &is_pending);
 
 		if (stored == is_pending)
-			continue;
+			goto put_irq;
 
 		if (is_pending)
 			val |= 1 << bit_nr;
@@ -436,11 +443,16 @@ int vgic_v3_save_pending_tables(struct kvm *kvm)
 			val &= ~(1 << bit_nr);
 
 		ret = vgic_write_guest_lock(kvm, ptr, &val, 1);
+put_irq:
+		raw_spin_lock_irqsave(&dist->lpi_list_lock, flags);
+		next = list_next_entry(irq, lpi_list);
+		__vgic_put_lpi_locked(kvm, irq);
 		if (ret)
 			goto out;
 	}
 
 out:
+	raw_spin_unlock_irqrestore(&dist->lpi_list_lock, flags);
 	if (vlpi_avail)
 		map_all_vpes(kvm);
 

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261128-vgic-66-bf3ec50950a1

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

