From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 15 Oct 2026 03:53:42 +0000
Subject: [PATCH 2/7] pid: place uprobes by file offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-bug001-uprobe-file-offset-v1-2-bf4c53af8f39@d-matrix.ai>
References: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
In-Reply-To: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=4999;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=WMqB3ZSg3mKaEfCHPDnVZAakcFamb9AGtHJssMrHGDY=;
 b=jbZnGECol9MYvKvzmQrUbSGeYqSQ1gwFZAgg8wnKv9sBaoR11+Wgu1a+DUrB51EvfajQDR1uf
 IqZ37cfukHKDhx4VVK1VkXlxeSpYnlQtwNn7bOxJRzWzq6MDjX/P5PB
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dt_pid_per_sym() computes a probe's uprobe offset as

    pps_off = st_value - pp->dpp_vaddr

i.e. the symbol's distance from the object's first segment, but
perf_event_open() takes a file offset.  The two are equal only if the
segment holding the symbol has the same p_vaddr - p_offset as the first
segment.  That holds for GNU ld's default layout.  LLVM lld packs
segments in the file, so its text segment's p_vaddr - p_offset is 0x1000
larger than the first segment's (on x86_64).

On lld-linked objects, every pid probe is therefore placed 0x1000 bytes
past its target.  Depending on what is there, the probe never fires,
fires in unrelated code, puts a breakpoint inside an instruction, or is
rejected by the kernel (ENOTSUPP).

Add dt_pid_file_offset(), which converts through the mapping that
contains the address (addr - pr_vaddr + pr_offset), and use it for all
pid probe offsets, falling back to the old computation if no mapping
contains the address.  libbpf resolves function uprobes the same way.
Offsets in GNU ld objects do not change.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libdtrace/dt_pid.c | 40 ++++++++++++++++++++++++++++++++++++----
 1 file changed, 36 insertions(+), 4 deletions(-)

diff --git a/libdtrace/dt_pid.c b/libdtrace/dt_pid.c
index 7e6e5d90..582862e4 100644
--- a/libdtrace/dt_pid.c
+++ b/libdtrace/dt_pid.c
@@ -57,12 +57,42 @@ typedef struct dt_pid_probe {
 	const char *dpp_fname;
 	uintptr_t dpp_base;
 	uintptr_t dpp_vaddr;
+	const prmap_file_t *dpp_file;
 	Lmid_t dpp_lmid;
 	uint_t dpp_nmatches;
 	GElf_Sym dpp_last;
 	uint_t dpp_last_taken;
 } dt_pid_probe_t;
 
+/*
+ * Convert an address in the victim into an offset in the file that backs the
+ * mapping containing it, which is what uprobes are placed by.
+ *
+ * Subtracting the load address of the first segment instead gives a file
+ * offset only if the segment containing the address has the same
+ * p_vaddr - p_offset as the first segment, as the text segment does with
+ * GNU ld.  LLVM lld packs segments in the file but starts each on a new page
+ * in memory, so probes in its text segment would land a page off.
+ */
+static uint64_t
+dt_pid_file_offset(const dt_pid_probe_t *pp, uintptr_t addr)
+{
+	const prmap_file_t *prf = pp->dpp_file;
+	size_t i;
+
+	if (prf != NULL) {
+		for (i = 0; i < prf->prf_num_mappings; i++) {
+			const prmap_t *pmp = prf->prf_mappings[i];
+
+			if (addr >= pmp->pr_vaddr &&
+			    addr < pmp->pr_vaddr + pmp->pr_size)
+				return addr - pmp->pr_vaddr + pmp->pr_offset;
+		}
+	}
+
+	return addr - pp->dpp_vaddr;
+}
+
 /*
  * Compose the lmid and object name into the canonical representation. We
  * omit the lmid for the default link map for convenience.
@@ -184,7 +214,7 @@ dt_pid_per_sym(dt_pid_probe_t *pp, const GElf_Sym *symp, const char *func)
 	psp->pps_fn = strdup(pp->dpp_fname);
 	psp->pps_fun = (char *) func;
 	psp->pps_nameoff = 0;
-	psp->pps_off = symp->st_value - pp->dpp_vaddr;
+	psp->pps_off = dt_pid_file_offset(pp, symp->st_value);
 
 	/*
 	 * The special function "-" means the probe name is an absolute
@@ -215,7 +245,7 @@ dt_pid_per_sym(dt_pid_probe_t *pp, const GElf_Sym *symp, const char *func)
 		}
 
 		psp->pps_prb = (char*)pp->dpp_name;
-		psp->pps_off = off - pp->dpp_vaddr;
+		psp->pps_off = dt_pid_file_offset(pp, off);
 
 		if (dt_pid_create_one_probe(pp->dpp_pr, dtp, psp, DTPPT_ABSOFFSETS) < 0)
 			rc = dt_pid_error(dtp, dpr, D_PROC_CREATEFAIL,
@@ -270,7 +300,7 @@ dt_pid_per_sym(dt_pid_probe_t *pp, const GElf_Sym *symp, const char *func)
 		}
 
 		psp->pps_nameoff = off;
-		psp->pps_off = symp->st_value - pp->dpp_vaddr + off;
+		psp->pps_off = dt_pid_file_offset(pp, symp->st_value + off);
 		if (dt_pid_create_one_probe(pp->dpp_pr, dtp,
 					psp, DTPPT_OFFSETS) < 0) {
 			rc = dt_pid_error(dtp, dpr, D_PROC_CREATEFAIL,
@@ -395,7 +425,7 @@ dt_pid_per_sym(dt_pid_probe_t *pp, const GElf_Sym *symp, const char *func)
 				continue;
 
 			psp->pps_nameoff = off;
-			psp->pps_off = symp->st_value - pp->dpp_vaddr + off;
+			psp->pps_off = dt_pid_file_offset(pp, symp->st_value + off);
 			if (dt_pid_create_one_probe(pp->dpp_pr, dtp,
 						psp, DTPPT_OFFSETS) >= 0)
 				nmatches++;
@@ -473,6 +503,7 @@ dt_pid_per_mod(void *arg, const prmap_t *pmp, const char *obj)
 	pp->dpp_inum = pmp->pr_inum;
 	pp->dpp_vaddr = pmp->pr_file->first_segment->pr_vaddr;
 	pp->dpp_base = (pmp->pr_mflags & MA_PIC) ? pp->dpp_vaddr : 0;
+	pp->dpp_file = pmp->pr_file;
 
 	/*
 	 * Note: if an execve() happens in the victim after this point, the
@@ -671,6 +702,7 @@ dt_pid_create_pid_probes_proc(dtrace_probedesc_t *pdp, dtrace_hdl_t *dtp,
 	pp.dpp_name = pdp->prb[0] != '\0' ? pdp->prb : "*";
 	pp.dpp_last_taken = 0;
 	pp.dpp_fname = NULL;
+	pp.dpp_file = NULL;
 
 	if (strcmp(pp.dpp_func, "-") == 0) {
 		const prmap_t *aout, *pmp;

-- 
2.55.0

