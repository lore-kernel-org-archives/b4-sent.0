From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 10:30:06 +0000
Subject: [PATCH 5.15.y] KVM: x86: pull kvm->srcu read-side to
 kvm_arch_vcpu_ioctl_run
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-kvm-515c-v1-1-f6ed4b86ea53@certik.com>
X-B4-Tracking: v=1; b=H4sIAC0KCGsC/zWMyw7CIBAAf6XZs9QuCRj8FeMB6GLxQRu2Npqm/
 y5oPM5kMisw5UgMx2aFTEvkOKYCuGvADzZdSMS+MMhOakSpxW15CIXKCwyuOzhtgjEWSj5lCvH
 1XZ1AtajaN5x/np/uSn6un1o6yyRctskPVTGlfh7Hu6h+///Dtn0Aa2Gu350AAAA=
X-Change-ID: 20261126-kvm-515c-1fb07b69f99a
To: stable@vger.kernel.org
Cc: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, kvm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795689005; l=7380;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=UljxdmpkWDBB5/v7UALESq95ZPnbEhtWB4FRDaX9S40=;
 b=/zobWmt7+gj7Yu6ZAccSe5CtnUXlG/YW5RbvvguJbm2eLyaSAiSmkyR3rp7m6H7WPntJ8S4j/
 lFqWfJ2E8SpDhZRWtE+frwtT0xqo4q7iHRW1T62itYtsKlpE0PQjCwS
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
[ adapted to 5.15.y: also moves the Xen post-run reader; folds in 2d08935682ac ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
5.15.y took 4bcdd831d9d0 ("KVM: x86: Acquire kvm->srcu when handling
KVM_SET_VCPU_EVENTS") as 5f35099fa3d5, but not this one. Without it
KVM_RUN still reaches kvm_vcpu_ioctl_x86_set_vcpu_events() through
sync_regs() before kvm->srcu is held, so the CVE-2024-46830 fix only
covers the KVM_SET_VCPU_EVENTS ioctl. 6.1.y and newer already have
this commit.

It folds in the follow-up 2d08935682ac ("KVM: x86: Don't re-acquire
SRCU lock in complete_emulated_io()"). Without it, emulated MMIO and
PIO completion would overwrite the outer SRCU index this patch takes.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of the touched objects, base vs
  patched, no new warnings
- booted a PROVE_LOCKING/PROVE_RCU kernel as a nested KVM host under
  QEMU, no lockdep or RCU splats. sync_regs_test passes. The evmcs,
  smm and state selftests stop at the same IA32_PERF_CAPABILITIES
  setup step on base and patched in this nested setup.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 arch/x86/kvm/x86.c | 31 +++++++++++++------------------
 1 file changed, 13 insertions(+), 18 deletions(-)

diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 135073c12859..73ac8a0f97fb 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -9105,6 +9105,7 @@ static int dm_request_for_irq_injection(struct kvm_vcpu *vcpu)
 		likely(!pic_in_kernel(vcpu->kvm));
 }
 
+/* Called within kvm->srcu read side.  */
 static void post_kvm_run_save(struct kvm_vcpu *vcpu)
 {
 	struct kvm_run *kvm_run = vcpu->run;
@@ -9113,16 +9114,9 @@ static void post_kvm_run_save(struct kvm_vcpu *vcpu)
 	kvm_run->cr8 = kvm_get_cr8(vcpu);
 	kvm_run->apic_base = kvm_get_apic_base(vcpu);
 
-	/*
-	 * The call to kvm_ready_for_interrupt_injection() may end up in
-	 * kvm_xen_has_interrupt() which may require the srcu lock to be
-	 * held, to protect against changes in the vcpu_info address.
-	 */
-	vcpu->srcu_idx = srcu_read_lock(&vcpu->kvm->srcu);
 	kvm_run->ready_for_interrupt_injection =
 		pic_in_kernel(vcpu->kvm) ||
 		kvm_vcpu_ready_for_interrupt_injection(vcpu);
-	srcu_read_unlock(&vcpu->kvm->srcu, vcpu->srcu_idx);
 
 	if (is_smm(vcpu))
 		kvm_run->flags |= KVM_RUN_X86_SMM;
@@ -9756,6 +9750,7 @@ void __kvm_request_immediate_exit(struct kvm_vcpu *vcpu)
 EXPORT_SYMBOL_GPL(__kvm_request_immediate_exit);
 
 /*
+ * Called within kvm->srcu read side.
  * Returns 1 to let vcpu_run() continue the guest execution loop without
  * exiting to the userspace.  Otherwise, the value will be returned to the
  * userspace.
@@ -10122,6 +10117,7 @@ static int vcpu_enter_guest(struct kvm_vcpu *vcpu)
 	return r;
 }
 
+/* Called within kvm->srcu read side.  */
 static inline int vcpu_block(struct kvm *kvm, struct kvm_vcpu *vcpu)
 {
 	bool hv_timer;
@@ -10182,12 +10178,12 @@ static inline bool kvm_vcpu_running(struct kvm_vcpu *vcpu)
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
@@ -10222,25 +10218,18 @@ static int vcpu_run(struct kvm_vcpu *vcpu)
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
@@ -10375,6 +10364,7 @@ static void kvm_put_guest_fpu(struct kvm_vcpu *vcpu)
 int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 {
 	struct kvm_run *kvm_run = vcpu->run;
+	struct kvm *kvm = vcpu->kvm;
 	int r;
 
 	vcpu_load(vcpu);
@@ -10382,6 +10372,7 @@ int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 	kvm_run->flags = 0;
 	kvm_load_guest_fpu(vcpu);
 
+	vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
 	if (unlikely(vcpu->arch.mp_state == KVM_MP_STATE_UNINITIALIZED)) {
 		if (kvm_run->immediate_exit) {
 			r = -EINTR;
@@ -10392,7 +10383,10 @@ int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 		 * use before KVM has ever run the vCPU.
 		 */
 		WARN_ON_ONCE(kvm_lapic_hv_timer_in_use(vcpu));
+		srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
 		kvm_vcpu_block(vcpu);
+		vcpu->srcu_idx = srcu_read_lock(&kvm->srcu);
+
 		if (kvm_apic_accept_events(vcpu) < 0) {
 			r = 0;
 			goto out;
@@ -10446,8 +10440,9 @@ int kvm_arch_vcpu_ioctl_run(struct kvm_vcpu *vcpu)
 	if (kvm_run->kvm_valid_regs)
 		store_regs(vcpu);
 	post_kvm_run_save(vcpu);
-	kvm_sigset_deactivate(vcpu);
+	srcu_read_unlock(&kvm->srcu, vcpu->srcu_idx);
 
+	kvm_sigset_deactivate(vcpu);
 	vcpu_put(vcpu);
 	return r;
 }

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261126-kvm-515c-1fb07b69f99a

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

