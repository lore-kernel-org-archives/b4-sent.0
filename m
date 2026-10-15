From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 15 Oct 2026 03:53:46 +0000
Subject: [PATCH 6/7] dtrace provider: place uprobes by file offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-bug001-uprobe-file-offset-v1-6-bf4c53af8f39@d-matrix.ai>
References: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
In-Reply-To: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=1417;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=7MSt4qugApkP4bcMEtjfu2NgLPYp5aKmXcbB1Djqm04=;
 b=UAHh6NvVqLEhBop3eejdjgOXGhA4eFJ5aKHdRpjTW7JGCxEvxe9c3eDTk+Oyt0HpcD7SV+cVb
 UEBrUcNPtdKBhC7N+YkX0yj06Yi4kY7UgjitKKBV2wNcesjV00IVLfd
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

uprobe_spec() places the dtrace provider's BEGIN, END and ERROR uprobes
on the *_probe() functions in libdtrace.so at the symbol's distance from
the object's first segment, not at its file offset: the same mistake as
in the pid and USDT providers.  With a libdtrace linked by lld,
dtrace:::BEGIN is placed 0x1000 bytes past BEGIN_probe(), never fires,
and every session hangs.

Convert through the mapping that contains the symbol instead.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libdtrace/dt_prov_dtrace.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/libdtrace/dt_prov_dtrace.c b/libdtrace/dt_prov_dtrace.c
index 4b788507..b8437c17 100644
--- a/libdtrace/dt_prov_dtrace.c
+++ b/libdtrace/dt_prov_dtrace.c
@@ -207,11 +207,13 @@ static char *uprobe_spec(pid_t pid, const char *prb)
 		if (mapp == NULL)
 			goto out;
 
-		if (mapp->pr_file->first_segment != mapp)
-			mapp = mapp->pr_file->first_segment;
-
+		/*
+		 * The uprobe spec takes a file offset: convert through the
+		 * mapping that contains the symbol, not the first segment
+		 * (their p_vaddr - p_offset differ, e.g. with LLVM lld).
+		 */
 		asprintf(&spec, "%s:0x%lx", mapp->pr_file->prf_mapname,
-			 sym.st_value - mapp->pr_vaddr);
+			 sym.st_value - mapp->pr_vaddr + mapp->pr_offset);
 	}
 
 out:

-- 
2.55.0

