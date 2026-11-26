From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 10:31:58 +0000
Subject: [PATCH 5.10.y v2 2/2] KVM: x86: Acquire kvm->srcu when handling
 KVM_SET_VCPU_EVENTS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-kvm-510d-v2-2-bcba96aa2088@certik.com>
References: <20261126-kvm-510d-v2-0-bcba96aa2088@certik.com>
In-Reply-To: <20261126-kvm-510d-v2-0-bcba96aa2088@certik.com>
To: stable@vger.kernel.org
Cc: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, kvm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795689116; l=3140;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=PMK0gZrBAmRQrVrXOfeI0jd8iITYPjI9GzoyJjp5PyQ=;
 b=AsNEqMlI3dBGqzOWLi52zGIO5UhAN1dWaR5vo5DfilLwILCQivK0vI/dLLcKXv5gMX6lGoj2f
 5Nd/fukKfjZAugt/rMjZ6/vW6yPksZRXjnGnE2WfM5pnDrYWGqGPl1P
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

commit 4bcdd831d9d01e0fb64faea50732b59b2ee88da1 upstream.

Grab kvm->srcu when processing KVM_SET_VCPU_EVENTS, as KVM will forcibly
leave nested VMX/SVM if SMM mode is being toggled, and leaving nested VMX
reads guest memory.

Note, kvm_vcpu_ioctl_x86_set_vcpu_events() can also be called from KVM_RUN
via sync_regs(), which already holds SRCU.  I.e. trying to precisely use
kvm_vcpu_srcu_read_lock() around the problematic SMM code would cause
problems.  Acquiring SRCU isn't all that expensive, so for simplicity,
grab it unconditionally for KVM_SET_VCPU_EVENTS.

 =============================
 WARNING: suspicious RCU usage
 6.10.0-rc7-332d2c1d713e-next-vm #552 Not tainted
 -----------------------------
 include/linux/kvm_host.h:1027 suspicious rcu_dereference_check() usage!

 other info that might help us debug this:

 rcu_scheduler_active = 2, debug_locks = 1
 1 lock held by repro/1071:
  #0: ffff88811e424430 (&vcpu->mutex){+.+.}-{3:3}, at: kvm_vcpu_ioctl+0x7d/0x970 [kvm]

 stack backtrace:
 CPU: 15 PID: 1071 Comm: repro Not tainted 6.10.0-rc7-332d2c1d713e-next-vm #552
 Hardware name: QEMU Standard PC (Q35 + ICH9, 2009), BIOS 0.0.0 02/06/2015
 Call Trace:
  <TASK>
  dump_stack_lvl+0x7f/0x90
  lockdep_rcu_suspicious+0x13f/0x1a0
  kvm_vcpu_gfn_to_memslot+0x168/0x190 [kvm]
  kvm_vcpu_read_guest+0x3e/0x90 [kvm]
  nested_vmx_load_msr+0x6b/0x1d0 [kvm_intel]
  load_vmcs12_host_state+0x432/0xb40 [kvm_intel]
  vmx_leave_nested+0x30/0x40 [kvm_intel]
  kvm_vcpu_ioctl_x86_set_vcpu_events+0x15d/0x2b0 [kvm]
  kvm_arch_vcpu_ioctl+0x1107/0x1750 [kvm]
  ? mark_held_locks+0x49/0x70
  ? kvm_vcpu_ioctl+0x7d/0x970 [kvm]
  ? kvm_vcpu_ioctl+0x497/0x970 [kvm]
  kvm_vcpu_ioctl+0x497/0x970 [kvm]
  ? lock_acquire+0xba/0x2d0
  ? find_held_lock+0x2b/0x80
  ? do_user_addr_fault+0x40c/0x6f0
  ? lock_release+0xb7/0x270
  __x64_sys_ioctl+0x82/0xb0
  do_syscall_64+0x6c/0x170
  entry_SYSCALL_64_after_hwframe+0x4b/0x53
 RIP: 0033:0x7ff11eb1b539
  </TASK>

Fixes: f7e570780efc ("KVM: x86: Forcibly leave nested virt when SMM state is toggled")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/r/20240723232055.3643811-1-seanjc@google.com
Signed-off-by: Sean Christopherson <seanjc@google.com>
[ adapted to 5.10.y: open-coded srcu_read_lock() as in the 5.15.y backport ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

 arch/x86/kvm/x86.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 69ab4e317422..d0bbf595dd47 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -4970,7 +4970,9 @@ long kvm_arch_vcpu_ioctl(struct file *filp,
 		if (copy_from_user(&events, argp, sizeof(struct kvm_vcpu_events)))
 			break;
 
+		vcpu->srcu_idx = srcu_read_lock(&vcpu->kvm->srcu);
 		r = kvm_vcpu_ioctl_x86_set_vcpu_events(vcpu, &events);
+		srcu_read_unlock(&vcpu->kvm->srcu, vcpu->srcu_idx);
 		break;
 	}
 	case KVM_GET_DEBUGREGS: {

-- 
2.43.0

