From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 13:07:17 +0000
Subject: [PATCH 5.10.y-cip] KVM: SVM: Inject #UD for INVLPGA if EFER.SVME=0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cip-svm-510-v1-1-a9cc8da73701@certik.com>
X-B4-Tracking: v=1; b=H4sIAISACWsC/02NSw7CMBBDr1LNmilJpFLEVRCLfKZ0ECRVplSgq
 ncngQ1L28/2CkKZSeDUrJBpYeEUi9C7Bvxo45WQQ9FglDlobXr0PKEsD+y0wkDBGN+7Iw0KSmP
 KNPDru3aGrtWqfVceLr9Mnu5Gfq5zlXZWCF220Y/VEophTumO1d//3cC2fQBA6w6bpwAAAA==
X-Change-ID: 20261127-cip-svm-510-ded22c7b8ef0
To: cip-dev@lists.cip-project.org
Cc: Pavel Machek <pavel@nabladev.com>, 
 Nobuhiro Iwamatsu <nobuhiro.iwamatsu.x90@mail.toshiba>, 
 Ulrich Hecht <uli@fpond.eu>, Kevin Cheng <chengkev@google.com>, 
 kvm@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795784836; l=1964;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=UKLupv1I54lhHtmKvF2aNY9MdYYKj1h36BecxzAIQ9k=;
 b=ianuIF86t5yrt1iLKHDJIxEKIqrxzMI8OAsLc3N7S9iijcYpvnHzfwjd4+8R+7rAbTKCb/krL
 7SZXCim+GAxBnOgc44fnOoFEuE63qj8hdafdPtaB+rKPcfEcRXpIVVv
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kevin Cheng <chengkev@google.com>

commit d99df02ff427f461102230f9c5b90a6c64ee8e23 upstream.

INVLPGA should cause a #UD when EFER.SVME is not set. Add a check to
properly inject #UD when EFER.SVME=0.

Fixes: ff092385e828 ("KVM: SVM: Implement INVLPGA")
Cc: stable@vger.kernel.org
Signed-off-by: Kevin Cheng <chengkev@google.com>
Reviewed-by: Yosry Ahmed <yosry.ahmed@linux.dev>
Link: https://patch.msgid.link/20260228033328.2285047-3-chengkev@google.com
[sean: tag for stable@]
Signed-off-by: Sean Christopherson <seanjc@google.com>
[ adapted to 5.10.y-cip: pass the vcpu_svm argument to the branch's permission helper ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
The 5.10 nested SVM permission helper takes a struct vcpu_svm pointer.
The backport passes that pointer from the INVLPGA handler.

Tested on 5.10.272-cip79: arch/x86/kvm/svm/svm.o built with W=1
before and after the patch, with no new diagnostics. The same paired
build passed on the 5.10.275-cip80 tip. On v5.10.275, svm_vmcall_test
passed in a QEMU TCG EPYC guest and skipped in the Intel/KVM guest.
The runtime test was not rerun on the CIP tip.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 arch/x86/kvm/svm/svm.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/x86/kvm/svm/svm.c b/arch/x86/kvm/svm/svm.c
index 41a4ee2aaa4c..f7862a5b686f 100644
--- a/arch/x86/kvm/svm/svm.c
+++ b/arch/x86/kvm/svm/svm.c
@@ -2162,6 +2162,9 @@ static int invlpga_interception(struct vcpu_svm *svm)
 {
 	struct kvm_vcpu *vcpu = &svm->vcpu;
 
+	if (nested_svm_check_permissions(svm))
+		return 1;
+
 	trace_kvm_invlpga(svm->vmcb->save.rip, kvm_rcx_read(&svm->vcpu),
 			  kvm_rax_read(&svm->vcpu));
 

---
base-commit: bd8b111cdf1d9897bf4d826b7305a9c16bfe5f71
change-id: 20261127-cip-svm-510-ded22c7b8ef0

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

