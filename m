From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 10:31:57 +0000
Subject: [PATCH 5.10.y v2 1/2] KVM: x86: pull kvm->srcu read-side to
 kvm_arch_vcpu_ioctl_run
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-kvm-510d-v2-1-bcba96aa2088@certik.com>
References: <20261126-kvm-510d-v2-0-bcba96aa2088@certik.com>
In-Reply-To: <20261126-kvm-510d-v2-0-bcba96aa2088@certik.com>
To: stable@vger.kernel.org
Cc: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, kvm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795689116; l=5395;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=aWlRKTULD3CULaHPvBETo5OWJQzrTM787U9y9afMXqY=;
 b=/Zc0OGramgsMxtQpZ9yJX9U88b3svJgKHqE3rON3D809yG9SntKymh1C5aJrFPIaa6AvADnb4
 HR23ixzMHWbAVlEZhGr74cbBn9vN8CqB173FIxmrhWohp/DkNkiDnni
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Paolo Bonzini <pbonzini@redhat.com>

commit 8d25b7beca7ed6ca34f53f0f8abd009e2be15d94 upstream.

kvm_arch_vcpu_ioctl_run is already doing srcu_read_lock/unlock in two
places, namely vcpu_run and post_kvm_run_save, and a third is actually
needed around the call to vcpu->arch.complete_userspace_io to avoid
the following splat:

  WARNING: suspicious RCU usage
  arch/x86/kvm/pmu.c:190 suspicious rcu_dereference_check() usage!
  other info that might help us debug this:
  rcu_scheduler_active = 2, debug_locks = 1
  1 lock held by CPU 28/KVM/370841:
  #0: ff11004089f280b8 (&vcpu->mutex){+.+.}-{3:3}, at: kvm_vcpu_ioctl+0x87/0x730 [kvm]
  Call Trace:
   <TASK>
   dump_stack_lvl+0x59/0x73
   reprogram_fixed_counter+0x15d/0x1a0 [kvm]
   kvm_pmu_trigger_event+0x1a3/0x260 [kvm]
   ? free_moved_vector+0x1b4/0x1e0
   complete_fast_pio_in+0x8a/0xd0 [kvm]

This splat is not at all unexpected, since complete_userspace_io callbacks
can execute similar code to vmexits.  For example, SVM with nrips=false
will call into the emulator from svm_skip_emulated_instruction().

While it's tempting to never acquire kvm->srcu for an uninitialized vCPU,
practically speaking there's no penalty to acquiring kvm->srcu "early"
as the KVM_MP_STATE_UNINITIALIZED path is a one-time thing per vCPU.  On
the other hand, seemingly innocuous helpers like kvm_apic_accept_events()
and sync_regs() can theoretically reach code that might access
SRCU-protected data structures, e.g. sync_regs() can trigger forced
existing of nested mode via kvm_vcpu_ioctl_x86_set_vcpu_events().

Reported-by: Like Xu <likexu@tencent.com>
Co-developed-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Paolo Bonzini <pbonzini@redhat.com>
[ adapted to 5.10.y: keep wants_to_run, no Xen reader; folds in 2d08935682ac ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 arch/x86/kvm/x86.c | 24 +++++++++++++-----------
 1 file changed, 13 insertions(+), 11 deletions(-)

diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 58660d5de141..69ab4e317422 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -8486,6 +8486,7 @@ static int dm_request_for_irq_injection(struct kvm_vcpu *vcpu)
 		likely(!pic_in_kernel(vcpu->kvm));
 }
 
+/* Called within kvm->srcu read side.  */
 static void post_kvm_run_save(struct kvm_vcpu *vcpu)
 {
 	struct kvm_run *kvm_run = vcpu->run;
@@ -9098,6 +9099,7 @@ void __kvm_request_immediate_exit(struct kvm_vcpu *vcpu)
 EXPORT_SYMBOL_GPL(__kvm_request_immediate_exit);
 
 /*
+ * Called within kvm->srcu read side.
  * Returns 1 to let vcpu_run() continue the guest execution loop without
  * exiting to the userspace.  Otherwise, the value will be returned to the
  * userspace.
@@ -9421,6 +9423,7 @@ static int vcpu_enter_guest(struct kvm_vcpu *vcpu)
 	return r;
 }
 
+/* Called within kvm->srcu read side.  */
 static inline int vcpu_block(struct kvm *kvm, struct kvm_vcpu *vcpu)
 {
 	if (!kvm_arch_vcpu_runnable(vcpu) &&
@@ -9463,12 +9466,12 @@ static inline bool kvm_vcpu_running(struct kvm_vcpu *vcpu)
 		!vcpu->arch.apf.halted);
 }
 
+/* Called within kvm->srcu read side.  */
 static int vcpu_run(struct kvm_vcpu *vcpu)
 {
 	int r;
 	struct kvm *kvm = vcpu->kvm;
 
-	vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
 	vcpu->arch.l1tf_flush_l1d = true;
 
 	for (;;) {
@@ -9503,25 +9506,18 @@ static int vcpu_run(struct kvm_vcpu *vcpu)
 		if (__xfer_to_guest_mode_work_pending()) {
 			srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
 			r = xfer_to_guest_mode_handle_work(vcpu);
+			vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
 			if (r)
 				return r;
-			vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
 		}
 	}
 
-	srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
-
 	return r;
 }
 
 static inline int complete_emulated_io(struct kvm_vcpu *vcpu)
 {
-	int r;
-
-	vcpu->srcu_idx = srcu_read_lock(&vcpu->kvm->srcu);
-	r = kvm_emulate_instruction(vcpu, EMULTYPE_NO_DECODE);
-	srcu_read_unlock(&vcpu->kvm->srcu, vcpu->srcu_idx);
-	return r;
+	return kvm_emulate_instruction(vcpu, EMULTYPE_NO_DECODE);
 }
 
 static int complete_emulated_pio(struct kvm_vcpu *vcpu)
@@ -9646,18 +9642,23 @@ static void kvm_put_guest_fpu(struct kvm_vcpu *vcpu)
 int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 {
 	struct kvm_run *kvm_run = vcpu->run;
+	struct kvm *kvm = vcpu->kvm;
 	int r;
 
 	vcpu_load(vcpu);
 	kvm_sigset_activate(vcpu);
 	kvm_load_guest_fpu(vcpu);
 
+	vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
 	if (unlikely(vcpu->arch.mp_state == KVM_MP_STATE_UNINITIALIZED)) {
 		if (!vcpu->wants_to_run) {
 			r = -EINTR;
 			goto out;
 		}
+		srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
 		kvm_vcpu_block(vcpu);
+		vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
+
 		kvm_apic_accept_events(vcpu);
 		kvm_clear_request(KVM_REQ_UNHALT, vcpu);
 		r = -EAGAIN;
@@ -9707,8 +9708,9 @@ int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 	if (kvm_run->kvm_valid_regs)
 		store_regs(vcpu);
 	post_kvm_run_save(vcpu);
-	kvm_sigset_deactivate(vcpu);
+	srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
 
+	kvm_sigset_deactivate(vcpu);
 	vcpu_put(vcpu);
 	return r;
 }

-- 
2.43.0

