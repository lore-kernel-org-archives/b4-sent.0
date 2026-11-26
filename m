From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH 5.10.y v2 0/2] KVM: x86: complete SRCU coverage for vCPU
 events
Date: Thu, 26 Nov 2026 10:31:56 +0000
Message-Id: <20261126-kvm-510d-v2-0-bcba96aa2088@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJwKCGsC/zWMywrCMBAAf6Xs2a2b0ATxV8RDHquNj0SSWpTSf
 zdRPM4wzAKFc+AC+26BzHMoIcUKctOBG008MwZfGSRJLYTUeJ3vqAR51M4N5HdKEQ1Q80fmU3h
 9VwdQvaD+DcefL097YTe1TyutKYw2m+jGpgpHP6V0w+a3/z+s6wfjFa5bnQAAAA==
X-Change-ID: 20261126-kvm-510d-6cc40d855004
To: stable@vger.kernel.org
Cc: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, kvm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795689116; l=1912;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=tZO36opxcxWmYFpvOATral8/1zZH55TXraMh88jDJHk=;
 b=ApqeA9bExi8qy5tP2NK4EbBv7S1Mr2DckuKO99gynUeL6IjtL5NAD+cf9KHmI7oU7Tf0QJPDq
 tQbMQPpPnoXCFCuyTRlREdUYQqUQ9ICQiOpDRBFU95yyRn3U0YE1ug7
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

v1 was a single patch: the 5.15.y version of commit 4bcdd831d9d0 ("KVM:
x86: Acquire kvm->srcu when handling KVM_SET_VCPU_EVENTS"). On 5.10 that
isn't enough. KVM_RUN also reaches kvm_vcpu_ioctl_x86_set_vcpu_events()
through sync_regs(), and on 5.10 that happens before vcpu_run() takes
kvm->srcu. Upstream covers that path with commit 8d25b7beca7e ("KVM:
x86: pull kvm->srcu read-side to kvm_arch_vcpu_ioctl_run"), which 5.10
doesn't have.

Patch 1 is that commit with its follow-up commit 2d08935682ac ("KVM:
x86: Don't re-acquire SRCU lock in complete_emulated_io()") folded in,
so emulated MMIO and PIO completion can't overwrite the outer SRCU
index. Patch 2 is the v1 patch.

Tested on v5.10.275:
- x86_64 allmodconfig W=1 build of the touched objects, base vs
  patched, no new warnings
- booted a PROVE_LOCKING/PROVE_RCU kernel as a nested KVM host under
  QEMU and ran the evmcs, smm, state and sync_regs selftests. All pass
  with no lockdep or RCU splats. vmx_preemption_timer_test fails the
  same way on base and patched in this nested setup.

5.15.y has the SET_VCPU_EVENTS fix but not patch 1, so I'm sending patch
1 for 5.15.y separately.

Changes in v2:
- v1 <CAFaZ9eoOtFxAansjaUbA-CDNQLcVAVJre2R9vaTQONG9MYUEng@mail.gmail.com>
  only had patch 2 and missed the sync_regs() path. Added patch 1.
- resent through a whitespace-safe path, v1 was also damaged by my
  mail client.

Thanks,
Dickson

---
Paolo Bonzini (1):
      KVM: x86: pull kvm->srcu read-side to kvm_arch_vcpu_ioctl_run

Sean Christopherson (1):
      KVM: x86: Acquire kvm->srcu when handling KVM_SET_VCPU_EVENTS

 arch/x86/kvm/x86.c | 26 +++++++++++++++-----------
 1 file changed, 15 insertions(+), 11 deletions(-)
---
base-commit: 99112ea818e35b606397c84fbc05e6fadb6ea162
change-id: 20261126-kvm-510d-6cc40d855004

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

