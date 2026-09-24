From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 24 Sep 2026 16:34:12 +0200
Subject: [PATCH RFC 4/4] mqueue: Use sysctl context to register mq_sysctls
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-lklm-sysctl-headerctx-template-v1-4-b25e51c66ba7@kernel.org>
References: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
In-Reply-To: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
To: Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 =?utf-8?q?Ondrej_Mosn=C3=A1=C4=8Dek?= <omosnacek@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Ryan Roberts <ryan.roberts@arm.com>, Serge Hallyn <serge@hallyn.com>, 
 "Eric W . Biederman" <ebiederm@xmission.com>, 
 Alexey Gladkov <legion@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3874;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=o8Ivuo115RG3Gnyh0w0ci6a+LxxW9zv9H1SSi6sfwRs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGq1NOYuvejxMBuIEfO8RppDIlzPWSdUBOoAX
 fGT3fbNSmfimokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqtTTmAAoJELqXzVK3
 lkFP71IL/R4u69KikxhWkenT+/5rloXOFT2/sDz2C7nBh6Fw83As8+9QoLHCC80j5qW+/5Mjvcn
 T67EMZAIrBBJWzOHEa2rzSGc8VV82wyz+nLKIH9Aao3499TR3NbF2Dti2YOlVYvszqhCQDrZ0fP
 Jp6gw4e18Z4VH2uCZ9pIs2VjpLmIGR5d0+DKGQtuXYrjpTaOf1TLk16gN/f7hMIuC/cpcDZ4Bur
 NUurxyBx/0LVVUCMax1hTnsS5lILPDCAPrVfhF7LxrIGrTNx1ezdid9npgV9PyaBrZoaotN6nM5
 E5NIo1x1dRVxNANOhXvAbJnCEfgRt27ucB1GSL6hXGAxYCgmqy5q2b/qOGbMfvLF9ms65dLFPwv
 H1QmsslaMZ7XB+KRvyljZSrRirRZBnUkfSYJ3NZuRumyja2lIqDlZjp1aJhWFz1v73SRPOmCPY1
 kUGnb5xiBOyIwEdIvHgYRGG0R9vxaCcPORNGPEu8A7kN6I1RsjLHNgeR2jgfu48M2eiJ70AzCk7
 Es=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the mq_sysctls array copy with a sysctl context kept in the
ctl_table_header. Flag each entry with CTL_TABLE_F_CTX_DATA to overlay
the ctl_table entry before calling the proc_handler.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 ipc/mq_sysctl.c | 44 ++++++++++----------------------------------
 1 file changed, 10 insertions(+), 34 deletions(-)

diff --git a/ipc/mq_sysctl.c b/ipc/mq_sysctl.c
index 0dd12e1c9f53ef07092ca3b638335a438d273a8c..9919e2d3a11a48a3e84c6c42d564e71dd60711da 100644
--- a/ipc/mq_sysctl.c
+++ b/ipc/mq_sysctl.c
@@ -11,7 +11,6 @@
 
 #include <linux/stat.h>
 #include <linux/capability.h>
-#include <linux/slab.h>
 #include <linux/cred.h>
 
 static int msg_max_limit_min = MIN_MSGMAX;
@@ -26,6 +25,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_queues_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= CTL_TABLE_F_CTX_DATA,
 		.proc_handler	= proc_dointvec,
 	},
 	{
@@ -33,6 +33,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msg_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= CTL_TABLE_F_CTX_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_max_limit_min,
 		.extra2		= &msg_max_limit_max,
@@ -42,6 +43,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msgsize_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= CTL_TABLE_F_CTX_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_maxsize_limit_min,
 		.extra2		= &msg_maxsize_limit_max,
@@ -51,6 +53,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msg_default,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= CTL_TABLE_F_CTX_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_max_limit_min,
 		.extra2		= &msg_max_limit_max,
@@ -60,6 +63,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msgsize_default,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= CTL_TABLE_F_CTX_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_maxsize_limit_min,
 		.extra2		= &msg_maxsize_limit_max,
@@ -116,39 +120,15 @@ static struct ctl_table_root set_root = {
 
 bool setup_mq_sysctls(struct ipc_namespace *ns)
 {
-	struct ctl_table *tbl;
+	struct sysctl_context ctx = SYSCTL_CTX(ns, &init_ipc_ns);
 
 	setup_sysctl_set(&ns->mq_set, &set_root, set_is_seen);
 
-	tbl = kmemdup(mq_sysctls, sizeof(mq_sysctls), GFP_KERNEL);
-	if (tbl) {
-		int i;
-
-		for (i = 0; i < ARRAY_SIZE(mq_sysctls); i++) {
-			if (tbl[i].data == &init_ipc_ns.mq_queues_max)
-				tbl[i].data = &ns->mq_queues_max;
-
-			else if (tbl[i].data == &init_ipc_ns.mq_msg_max)
-				tbl[i].data = &ns->mq_msg_max;
-
-			else if (tbl[i].data == &init_ipc_ns.mq_msgsize_max)
-				tbl[i].data = &ns->mq_msgsize_max;
-
-			else if (tbl[i].data == &init_ipc_ns.mq_msg_default)
-				tbl[i].data = &ns->mq_msg_default;
-
-			else if (tbl[i].data == &init_ipc_ns.mq_msgsize_default)
-				tbl[i].data = &ns->mq_msgsize_default;
-			else
-				tbl[i].data = NULL;
-		}
-
-		ns->mq_sysctls = __register_sysctl_table(&ns->mq_set,
-							 "fs/mqueue", tbl,
-							 ARRAY_SIZE(mq_sysctls));
-	}
+	ns->mq_sysctls = __register_sysctl_table_ctx(&ns->mq_set, "fs/mqueue",
+						     mq_sysctls,
+						     ARRAY_SIZE(mq_sysctls),
+						     &ctx);
 	if (!ns->mq_sysctls) {
-		kfree(tbl);
 		retire_sysctl_set(&ns->mq_set);
 		return false;
 	}
@@ -158,10 +138,6 @@ bool setup_mq_sysctls(struct ipc_namespace *ns)
 
 void retire_mq_sysctls(struct ipc_namespace *ns)
 {
-	const struct ctl_table *tbl;
-
-	tbl = ns->mq_sysctls->ctl_table_arg;
 	unregister_sysctl_table(ns->mq_sysctls);
 	retire_sysctl_set(&ns->mq_set);
-	kfree(tbl);
 }

-- 
2.50.1

