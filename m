From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Sun, 18 Oct 2026 02:50:07 +0000
Subject: [PATCH 1/3] Use a temporary string as scratch space for strlen()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-bug010-strlen-strtab-v1-1-ac5f5bc6f8a0@d-matrix.ai>
References: <20261018-bug010-strlen-strtab-v1-0-ac5f5bc6f8a0@d-matrix.ai>
In-Reply-To: <20261018-bug010-strlen-strtab-v1-0-ac5f5bc6f8a0@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Kris Van Hees <kris.van.hees@oracle.com>, dtrace-devel@oss.oracle.com, 
 Eugene Loh <eugene.loh@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792291829; l=3180;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=Hf27nCqM6dOxLW9NMVLnIsf8KUcmm2ovTznlmGarlSM=;
 b=dagh6PcC2AGj5imNKoRK1ZW4TrHbPONorWSQDmjOvC/FAkOkFnXTQxI4wL586d72d02tVfJsV
 /P4OZks7ox/CPAYVBFKg1Oc6o0IMhoKXsBIpNJ1P3w5TqdnHRBTBj2T
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dt_strlen() measures its argument by copying it with
bpf_probe_read_str() to the end of the string table in the strtab map,
at offset STBSZ.  Commit e0424837 ("Implement strlen() based on
bpf_probe_read_str()") started using that space, which was unused and
sized to hold the largest string.  Commit d9d862b6 ("Add a block of
zeroes to use to initialize BPF maps") then put the block of zeros
there, rounded up to a multiple of 8, and commit e11098e2 ("Add rodata
support") put the read-only data in front of it.  So strlen() of
anything longer than a few characters overwrites the read-only data,
or the block of zeros if there is none, for the rest of the session.

New aggregation data is initialized from the block of zeros and tuple
keys are padded from it.  So after such a strlen(), aggregations such
as @[strlen(probefunc)] = count() give counts like 8753160913407277434,
and keys no longer match the same keys built before it.  inet_ntoa6()
reads a lookup table from the read-only data and formats ::1 as
0:0:0:0:0:0:0:1.

Copy the string to a temporary string instead, as the other string
subroutines do, so that BPF code no longer writes to the strtab map.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 bpf/strlen.c      |  4 +---
 libdtrace/dt_cg.c | 13 ++++++++++---
 2 files changed, 11 insertions(+), 6 deletions(-)

diff --git a/bpf/strlen.c b/bpf/strlen.c
index 5408ed17..4714f44b 100644
--- a/bpf/strlen.c
+++ b/bpf/strlen.c
@@ -12,12 +12,10 @@
 # define noinline	__attribute__((noinline))
 #endif
 
-extern uint64_t STBSZ;
 extern uint64_t STRSZ;
 
-noinline uint64_t dt_strlen(const dt_dctx_t *dctx, const char *str)
+noinline uint64_t dt_strlen(const char *str, char *tmp)
 {
-	char	*tmp = dctx->strtab + (uint64_t)&STBSZ;
 	int64_t	len;
 
 	/*
diff --git a/libdtrace/dt_cg.c b/libdtrace/dt_cg.c
index a77c022c..a58837e0 100644
--- a/libdtrace/dt_cg.c
+++ b/libdtrace/dt_cg.c
@@ -6448,6 +6448,7 @@ dt_cg_subr_strlen(dt_node_t *dnp, dt_irlist_t *dlp, dt_regset_t *drp)
 {
 	dt_ident_t	*idp = dt_dlib_get_func(yypcb->pcb_hdl, "dt_strlen");
 	dt_node_t	*str = dnp->dn_args;
+	uint64_t	off;
 
 	assert(idp != NULL);
 
@@ -6459,14 +6460,20 @@ dt_cg_subr_strlen(dt_node_t *dnp, dt_irlist_t *dlp, dt_regset_t *drp)
 	if (dt_regset_xalloc_args(drp) == -1)
 		longjmp(yypcb->pcb_jmpbuf, EDT_NOREG);
 
-	dt_cg_access_dctx(BPF_REG_1, dlp, drp, -1);
-	emit(dlp, BPF_MOV_REG(BPF_REG_2, str->dn_reg));
+	emit(dlp, BPF_MOV_REG(BPF_REG_1, str->dn_reg));
 	dt_regset_free(drp, str->dn_reg);
-	dt_cg_tstring_free(yypcb, str);
+
+	/* The string is copied to a temporary string to measure it. */
+	off = dt_cg_tstring_xalloc(yypcb);
+	dt_cg_access_dctx(BPF_REG_2, dlp, drp, DCTX_MEM);
+	emit(dlp, BPF_ALU64_IMM(BPF_ADD, BPF_REG_2, off));
+
 	dt_regset_xalloc(drp, BPF_REG_0);
 	emite(dlp,BPF_CALL_FUNC(idp->di_id), idp);
 
 	dt_regset_free_args(drp);
+	dt_cg_tstring_xfree(yypcb, off);
+	dt_cg_tstring_free(yypcb, str);
 	dnp->dn_reg = dt_regset_alloc(drp);
 	if (dnp->dn_reg == -1)
 		longjmp(yypcb->pcb_jmpbuf, EDT_NOREG);

-- 
2.55.0

