From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 11:45:01 +0000
Subject: [PATCH 5.10.y] bpf: Clear buf on error in __bpf_get_task_stack
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-so1b-bpf-510-v1-1-24bed4a57fa0@certik.com>
X-B4-Tracking: v=1; b=H4sIALwbCGsC/02NzQ6CMBCEX4Xs2cX+pAR8FeOhLYvUmJZ00WgI7
 26rF4/zZeabDZhyIIZTs0GmZ+CQYgny0ICfbbwShrFkUEJ1UqoOOUmHbpnQSIGD1ZoM9UYPPZT
 JkmkKr6/uDKaVon3D5cf54W7k1+qqTWeZ0GUb/VwRUxzXlO5Y+fH/A/b9A+rlmNulAAAA
X-Change-ID: 20261126-so1b-bpf-510-9a33e5e85398
To: stable@vger.kernel.org
Cc: Jiri Olsa <jolsa@kernel.org>, Andrii Nakryiko <andrii@kernel.org>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 bpf@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795693500; l=2361;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=hk81rXf0b1uO73SLKT7st7p0Z3no78nTgTSXqVZ7P4c=;
 b=/NzVrZ8AD7J2/dfD/q/IdzP5o6jbwiocZ4hZI5XE0uA8mo6JD697/nCYEbkVq/6dSUQg4vGzr
 0kxx+wVy2V2Dtaulo5Xuw/ITq6qyJCtOzu/EhvYsKsYhUHmcIT2gKNs
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
[ adapted to 5.10.y: use bpf_get_task_stack() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix. This branch has no
__bpf_get_task_stack(); the same code sits directly in
bpf_get_task_stack(), so the two memsets go there.

Tested on v5.10.275:
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
index 3ec76cb5f240..c9a9cfbca4ae 100644
--- a/kernel/bpf/stackmap.c
+++ b/kernel/bpf/stackmap.c
@@ -670,14 +670,17 @@ BPF_CALL_4(bpf_get_task_stack, struct task_struct *, task, void *, buf,
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
base-commit: 99112ea818e35b606397c84fbc05e6fadb6ea162
change-id: 20261126-so1b-bpf-510-9a33e5e85398

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

