From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 15 Oct 2026 03:53:44 +0000
Subject: [PATCH 4/7] usdt: place uprobes by file offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-bug001-uprobe-file-offset-v1-4-bf4c53af8f39@d-matrix.ai>
References: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
In-Reply-To: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=1722;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=MVfhUrCORXTWzNlqLhdWM7r7PjrLGHSXdp2ioG6pJ78=;
 b=CWKaKa6FzTcrpHb4W24ZkgDBPxqmJ8iYZEer+HICuuuEWToUTO3+gGW4X7OiWcK2ZBglvB+x8
 zrDMeMlzS8QD10jRjCCVZEzgodwzkqR7R1cnnA71U+CmF1+Li67jjWt
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dt_pid_create_usdt_probes_proc() converts each tracepoint address from
dtprobed to a uprobe offset by subtracting the load address of the
object's first segment.  That gives the address's distance from the
first segment, not its file offset: the same mistake as in the pid
provider, with the same effect on lld-linked executables and libraries.
Every USDT and is-enabled probe is placed 0x1000 bytes past its site.
In a small object, that address lies outside any executable mapping, so
the probe never fires and is-enabled stays false; otherwise the probe
fires in other code or makes enabling fail for the whole process
(ENOTSUPP).

Convert through the mapping that contains the address instead.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libdtrace/dt_pid.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/libdtrace/dt_pid.c b/libdtrace/dt_pid.c
index 582862e4..7741e6d9 100644
--- a/libdtrace/dt_pid.c
+++ b/libdtrace/dt_pid.c
@@ -1087,7 +1087,14 @@ dt_pid_create_usdt_probes_proc(dtrace_hdl_t *dtp, pid_t pid, dt_proc_t *dpr,
 			psp.pps_dev = pmp->pr_dev;
 			psp.pps_inum = pmp->pr_inum;
 			psp.pps_pid = dpr->dpr_pid;
-			psp.pps_off = tp->tracepoint.addr - pmp->pr_file->first_segment->pr_vaddr;
+			/*
+			 * uprobes are placed by file offset: convert through
+			 * the mapping that contains the tracepoint.  That need
+			 * not be the first segment, and its p_vaddr - p_offset
+			 * can differ from the first segment's (LLVM lld).
+			 */
+			psp.pps_off = tp->tracepoint.addr - pmp->pr_vaddr +
+				      pmp->pr_offset;
 			psp.pps_nameoff = 0;
 
 			if (nargv) {

-- 
2.55.0

