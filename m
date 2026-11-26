From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:47 +0100
Subject: [PATCH RFC 7/9] ipc: Register ipc_sysctls as a template
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-7-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4976;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=54HGww1X23ASNOxIGe3Rxq7gJzlT62N2Vt9USaYOQiY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGUvwSVAnNS5lLfxc7WVC/uJB8e3Oz0ob
 bPc1/RP5CyLL4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxlAAoJELqXzVK3
 lkFPgTIMAIR4yCRrf8qNLZiE+iuepvt8fDSt9M1X3AAwFrc+ny59YhNL7QAc3Ko4szYiepSb0cU
 43nc4NArMYz2Wa5IBpKTqp3R/qOpwfQ53vqLschdcs4afJKoaU/4ix/ZuoJp9Y3KVU2P88TAoTp
 I3iqlwwbobpD0wxNQpkr2OBNxljQgBp+wWABEtDc//EUVp+lPQNBBaJWOCnxGGmRd8W26XgHAK+
 x5s2Erb1XZiwdvz8jR8SxiBiLz+whvpvuz8RLpLAm9bxyLpCNzeZZv5VHktDh+ePud9At9jSl/X
 /3IUsvRIoblRzQzfjHhD9Bhw7u0jSqVfphjSK8ckB+WyWu/C9+gERcB0W+84dwI5Os9z+5MEOZd
 2i0xaH3D785woVTYapd1j8xC/Xrv+YoQSRcOMZtRZmSsHFCzLNnpy60RW7nx2J8FTltLWG1IaXK
 cP4Hb2ufYtt5lrOVeL7RUf7qz20ai9s46L+tQmftRO2VfXfGVGM6zfXeSFNsFJp80PHG2WEdsg5
 +Q=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flag SYSCTL_OVERLAY_DATA on every entry of ipc_sysctls that has a .data
pointer and register the table through __register_sysctl_table_tmpl(),
passing the rebased copy that setup_ipc_sysctls() already builds as the
overlay. Free the copy once the call returns and stop freeing
ctl_table_arg in retire_ipc_sysctls(). auto_msgmni has no .data and
stays unflagged.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 ipc/ipc_sysctl.c | 24 ++++++++++++++++--------
 1 file changed, 16 insertions(+), 8 deletions(-)

diff --git a/ipc/ipc_sysctl.c b/ipc/ipc_sysctl.c
index d038d944257f60b3a35b72492c73c41774a73da4..42a249cb58747e75fa76aa94570e5ad23cf8b003 100644
--- a/ipc/ipc_sysctl.c
+++ b/ipc/ipc_sysctl.c
@@ -79,6 +79,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.shm_ctlmax,
 		.maxlen		= sizeof(init_ipc_ns.shm_ctlmax),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_doulongvec_minmax,
 	},
 	{
@@ -86,6 +87,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.shm_ctlall,
 		.maxlen		= sizeof(init_ipc_ns.shm_ctlall),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_doulongvec_minmax,
 	},
 	{
@@ -93,6 +95,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.shm_ctlmni,
 		.maxlen		= sizeof(init_ipc_ns.shm_ctlmni),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &ipc_mni,
@@ -102,6 +105,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.shm_rmid_forced,
 		.maxlen		= sizeof(init_ipc_ns.shm_rmid_forced),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_ipc_dointvec_minmax_orphans,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -111,6 +115,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.msg_ctlmax,
 		.maxlen		= sizeof(init_ipc_ns.msg_ctlmax),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -120,6 +125,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.msg_ctlmni,
 		.maxlen		= sizeof(init_ipc_ns.msg_ctlmni),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &ipc_mni,
@@ -138,6 +144,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.msg_ctlmnb,
 		.maxlen		= sizeof(init_ipc_ns.msg_ctlmnb),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -147,6 +154,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.sem_ctls,
 		.maxlen		= 4*sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_ipc_sem_dointvec,
 	},
 #ifdef CONFIG_CHECKPOINT_RESTORE
@@ -155,6 +163,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.ids[IPC_SEM_IDS].next_id,
 		.maxlen		= sizeof(init_ipc_ns.ids[IPC_SEM_IDS].next_id),
 		.mode		= 0444,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -164,6 +173,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.ids[IPC_MSG_IDS].next_id,
 		.maxlen		= sizeof(init_ipc_ns.ids[IPC_MSG_IDS].next_id),
 		.mode		= 0444,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -173,6 +183,7 @@ static const struct ctl_table ipc_sysctls[] = {
 		.data		= &init_ipc_ns.ids[IPC_SHM_IDS].next_id,
 		.maxlen		= sizeof(init_ipc_ns.ids[IPC_SHM_IDS].next_id),
 		.mode		= 0444,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -290,11 +301,12 @@ bool setup_ipc_sysctls(struct ipc_namespace *ns)
 				tbl[i].data = NULL;
 		}
 
-		ns->ipc_sysctls = __register_sysctl_table(&ns->ipc_set, "kernel", tbl,
-							  ARRAY_SIZE(ipc_sysctls));
-	}
-	if (!ns->ipc_sysctls) {
+		ns->ipc_sysctls = __register_sysctl_table_tmpl(&ns->ipc_set, "kernel",
+							       CTL_TABLE_TMPL(ipc_sysctls),
+							       tbl, ARRAY_SIZE(ipc_sysctls));
 		kfree(tbl);
+	}
+	if (!ns->ipc_sysctls) {
 		retire_sysctl_set(&ns->ipc_set);
 		return false;
 	}
@@ -304,12 +316,8 @@ bool setup_ipc_sysctls(struct ipc_namespace *ns)
 
 void retire_ipc_sysctls(struct ipc_namespace *ns)
 {
-	const struct ctl_table *tbl;
-
-	tbl = ns->ipc_sysctls->ctl_table_arg;
 	unregister_sysctl_table(ns->ipc_sysctls);
 	retire_sysctl_set(&ns->ipc_set);
-	kfree(tbl);
 }
 
 static int __init ipc_sysctl_init(void)

-- 
2.50.1

