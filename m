From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Tue, 17 Nov 2026 22:36:41 +0000
Subject: [PATCH RFC 3/7] libproc: add Paddr_to_load_bias()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-b4-bug003-load-bias-v1-3-dcd0f6cde412@d-matrix.ai>
References: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
In-Reply-To: <20261117-b4-bug003-load-bias-v1-0-dcd0f6cde412@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: Nick Alcock <nix@esperi.org.uk>, 
 Kris Van Hees <kris.van.hees@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794955038; l=2156;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=LDD7eY6fQEebFO9lkJUW3O43ywlFHyv32e3keoRksIE=;
 b=AKGSJJXeziONY4nUdLvauabg4/czIbgkYDMO6ODNkfIB0E5YgB7Po9Hphn4BbCMrP/a3Uk4KN
 GCSFu40vyoJD1VGY2US3BhxzEvQytj6fg/ZkOGaoSn1glu3XXA3fgSH
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Return the load bias of the object mapped at a given address, as libproc
already computes it for symbol lookups (from ld.so's link map, or from
the object's first mapping).  The next patch uses it to relocate
link-time addresses given by the user.

Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 libproc/Psymtab.c | 30 ++++++++++++++++++++++++++++++
 libproc/libproc.h |  1 +
 2 files changed, 31 insertions(+)

diff --git a/libproc/Psymtab.c b/libproc/Psymtab.c
index b713e439..afabf794 100644
--- a/libproc/Psymtab.c
+++ b/libproc/Psymtab.c
@@ -2279,6 +2279,36 @@ Pobject_iter(struct ps_prochandle *P, proc_map_f *func, void *cd)
 	return 0;
 }
 
+/*
+ * Given an address in the process, return in *biasp the load bias of the
+ * object mapped there: the difference between its runtime and its
+ * link-time addresses (0 for ET_EXEC objects).  Returns 0 on success, -1
+ * on failure.
+ */
+int
+Paddr_to_load_bias(struct ps_prochandle *P, uintptr_t addr, uintptr_t *biasp)
+{
+	map_info_t *mptr;
+	file_info_t *fptr;
+
+	if (P->state == PS_DEAD)
+		return -1;
+
+	Pupdate_maps(P);
+	Pupdate_lmids(P);
+
+	if ((mptr = Paddr2mptr(P, addr)) == NULL ||
+	    (fptr = mptr->map_file) == NULL)
+		return -1;
+
+	Pbuild_file_symtab(P, fptr);
+	if (fptr->file_elf == NULL)
+		return -1;
+
+	*biasp = fptr->file_dyn_base;
+	return 0;
+}
+
 /*
  * Given a virtual address, return the name of the underlying
  * mapped object (file) as provided by the dynamic linker.
diff --git a/libproc/libproc.h b/libproc/libproc.h
index 59c73051..5cbc7423 100644
--- a/libproc/libproc.h
+++ b/libproc/libproc.h
@@ -256,6 +256,7 @@ typedef int proc_map_f(void *, const prmap_t *, const char *);
 extern int Pobject_iter(struct ps_prochandle *, proc_map_f *, void *);
 
 extern const prmap_t *Paddr_to_map(struct ps_prochandle *, uintptr_t);
+extern int Paddr_to_load_bias(struct ps_prochandle *, uintptr_t, uintptr_t *);
 extern const prmap_t *Pname_to_map(struct ps_prochandle *, const char *);
 extern const prmap_t *Plmid_to_map(struct ps_prochandle *,
     Lmid_t, const char *);

-- 
2.55.0

