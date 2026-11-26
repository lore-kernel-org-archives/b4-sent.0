From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 12:14:15 +0000
Subject: [PATCH 5.15.y] bpf: Clear buf on error in __bpf_get_task_stack
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so1b-bpf-515-v1-1-03acb4631a9c@certik.com>
X-B4-Tracking: v=1; b=H4sIAJYiCGsC/02NzQrCMBCEX6Xs2a3dYCL4KuIhP1sbkaRkqyil7
 26iF4/zMfPNCsIlssCpW6HwM0rMqQbadeAnm66MMdQMalCGSBmUTA7dPKImjcRWG6fDcDBHqJO
 58BhfX90ZdE+6f8Plx+XhbuyX5mpNZ4XRFZv81JBwCkvOd2x8//8B2/YBv3Z7dqUAAAA=
X-Change-ID: 20261126-so1b-bpf-515-1ea56b5d0467
To: stable@vger.kernel.org
Cc: Jiri Olsa <jolsa@kernel.org>, Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 bpf@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795695254; l=2361;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=BMDL3A0/tlxrmRgMDwvaLHJhFSpu3XBsNg3zFHP17+0=;
 b=3R3df+Bn1R7wlrDwKrYQSJttf6fYzizf/dcs5kvvNK63mwzoA0ekqGyvSSPO9WfjqbqtuNx7E
 i/fpGuNQpdXDhsKSwBUniKdHR3MfZRPROVB6te5LSmHAAnoIFq5hFX3
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Jiri Olsa <jolsa@kernel.org>

commit f5d242825ca417bb6afe35fde6e8880f97ca43fb upstream.

Both bpf_get_task_stack and bpf_get_task_stack_sleepable helpers that
use __bpf_get_task_stack have buf defined as ARG_PTR_TO_UNINIT_MEM
argument and we should initialize the buf on every return path.

Adding missing buf memset for __bpf_get_task_stack fail paths. This
provides deterministic buffer contents, which is useful when the buffer
is used directly as a map key.

Fixes: 06ab134ce8ec ("bpf: Refcount task stack in bpf_get_task_stack")
Fixes: b992f01e6615 ("bpf: Guard against accessing NULL pt_regs in bpf_get_task_stack()")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Signed-off-by: Jiri Olsa <jolsa@kernel.org>
Signed-off-by: Andrii Nakryiko <andrii@kernel.org>
Link: https://lore.kernel.org/bpf/20260803210149.296496-10-jolsa@kernel.org
[ adapted to 5.15.y: use bpf_get_task_stack() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix. This branch has no
__bpf_get_task_stack(); the same code sits directly in
bpf_get_task_stack(), so the two memsets go there.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of kernel/bpf/stackmap.o, base vs
  patched, no new warnings
- booted the patched kernel under QEMU/KVM. I didn't run a BPF test
  that hits the two error paths.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 kernel/bpf/stackmap.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/kernel/bpf/stackmap.c b/kernel/bpf/stackmap.c
index e04571c1833f..ca1a15c94724 100644
--- a/kernel/bpf/stackmap.c
+++ b/kernel/bpf/stackmap.c
@@ -530,14 +530,17 @@ BPF_CALL_4(bpf_get_task_stack, struct task_struct *, task, void *, buf,
 	struct pt_regs *regs;
 	long res = -EINVAL;
 
-	if (!try_get_task_stack(task))
+	if (!try_get_task_stack(task)) {
+		memset(buf, 0, size);
 		return -EFAULT;
+	}
 
 	regs = task_pt_regs(task);
 	if (regs)
 		res = __bpf_get_stack(regs, task, NULL, buf, size, flags);
+	else
+		memset(buf, 0, size);
 	put_task_stack(task);
-
 	return res;
 }
 

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261126-so1b-bpf-515-1ea56b5d0467

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

