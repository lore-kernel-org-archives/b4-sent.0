From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:42 +0000
Subject: [PATCH RFC 4/7] pid: use the load bias for "-" probe addresses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-4-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=1901;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=Ba2dqKblhN6fUwK+BhnR3eR4ISE0CjmX2XByv8VZtUc=;
 b=S6zUGCUMncKOWm69Jeq5TaDm8sZ8RDYiJ10tt1Aq9GVCkBiDDL//sbx9uKqbaRKILKMmHOuuE
 uJArfoiWn4wBojjsDXxMdAIJmfBWhLiLNZ77QU5N+VliG5XsDNEaWz+
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The address in pid$pid:a.out:-:ADDR is a link-time address, as printed
by nm.  Since commit 814a29b3 ("pid: ensure pid offset probes perform
lookup with adjusted address"), dt_pid_per_mod() relocates it by the
load address of the first mapping if the mapping is flagged MA_PIC, and
by 0 otherwise.  Both are wrong in some cases:

  - the first mapping's address is the load bias only for objects
    linked at 0, so for a PIE linked elsewhere (lld --image-base) the
    address is too high by the link address;
  - MA_PIC is only set once libproc knows the object is ET_DYN, which
    it does not yet know when attaching to a running process (-p), so
    ADDR is not relocated at all, even for an ordinary PIE.

Either way the lookup fails and the probe is not created.  Use libproc's
load bias (0 for ET_EXEC) instead, keeping the old value as a fallback.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libdtrace/dt_pid.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/libdtrace/dt_pid.c b/libdtrace/dt_pid.c
index 7741e6d9..5d2d044f 100644
--- a/libdtrace/dt_pid.c
+++ b/libdtrace/dt_pid.c
@@ -502,7 +502,15 @@ dt_pid_per_mod(void *arg, const prmap_t *pmp, const char *obj)
 	pp->dpp_dev = pmp->pr_dev;
 	pp->dpp_inum = pmp->pr_inum;
 	pp->dpp_vaddr = pmp->pr_file->first_segment->pr_vaddr;
-	pp->dpp_base = (pmp->pr_mflags & MA_PIC) ? pp->dpp_vaddr : 0;
+
+	/*
+	 * The address in a "-" probe name is a link-time address: add the
+	 * object's load bias.  The first segment's load address is only the
+	 * bias if the object is linked at 0, and MA_PIC is not yet known when
+	 * attaching to a running process.
+	 */
+	if (Paddr_to_load_bias(dpr->dpr_proc, pmp->pr_vaddr, &pp->dpp_base) < 0)
+		pp->dpp_base = (pmp->pr_mflags & MA_PIC) ? pp->dpp_vaddr : 0;
 	pp->dpp_file = pmp->pr_file;
 
 	/*

-- 
2.55.0

