From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:48 +0100
Subject: [PATCH RFC 8/9] ipc: Register mq_sysctls as a template
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-8-d7fc9cc9b03e@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2968;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=WkQNr6QnWoumKVxyewSSlZ9tzXOb2ucls8i2JZ231Ug=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGYrbDOl6KkAQLkQYC3EcXdsceyF87xgq
 rrHsSB5YX02q4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxmAAoJELqXzVK3
 lkFPJgAL/A6cdr0GRDrKF/B80MWYZTZqDRohMggTUeQdBzrDwqcU2tVGBxU7mLJq/E88lCWqPM2
 3b3FsML3WG3jFhBeDUs0AUrbM4LF1pjOmasf4uwI+jA/Httyl4nl3CtlMRJeN3beA7sdNRdakmD
 wu/qkaq5BGsIh8SAxt8m3Q6vLwscikzkJ0u8H4hjrzOUSu4MoKoinxIA01G+f7rFwsSC5pF38sk
 ETn1JJuJ+4YCZhR7EUMZJC7MLTGb8ZYuzvbg6jeoKRO+dTsL/sOa6n+T1U55kpw537DzvIMfiHH
 LQvgPXk57ne/v2tY472d7rDSV1eW3Tts/yV7iUg3h178npeoRSOJNqkq0EmPwe3rl1PuieCt2Oc
 SuoZW4WZmFsk+4/Bfxz7nzOekoVUURlRnSgkARCxfRPsRiuJSIUv+UAgG3HhDGdjs4DMb3lJRxE
 WI3m4dH8lag+CFxcqxlz3ljGxO4di2VAR2t8hN71DVwY8XVmDU9NsErUhMnfy+GwqB+ghdbcmD7
 Ls=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flag SYSCTL_OVERLAY_DATA on all five entries of mq_sysctls and register
the table through __register_sysctl_table_tmpl(), passing the rebased
copy that setup_mq_sysctls() already builds as the overlay. Free the
copy once the call returns and stop freeing ctl_table_arg in
retire_mq_sysctls().

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 ipc/mq_sysctl.c | 20 +++++++++++---------
 1 file changed, 11 insertions(+), 9 deletions(-)

diff --git a/ipc/mq_sysctl.c b/ipc/mq_sysctl.c
index 0dd12e1c9f53ef07092ca3b638335a438d273a8c..d98c90595fabedc30fa565c8e0ca16ec3399bcf4 100644
--- a/ipc/mq_sysctl.c
+++ b/ipc/mq_sysctl.c
@@ -26,6 +26,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_queues_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec,
 	},
 	{
@@ -33,6 +34,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msg_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_max_limit_min,
 		.extra2		= &msg_max_limit_max,
@@ -42,6 +44,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msgsize_max,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_maxsize_limit_min,
 		.extra2		= &msg_maxsize_limit_max,
@@ -51,6 +54,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msg_default,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_max_limit_min,
 		.extra2		= &msg_max_limit_max,
@@ -60,6 +64,7 @@ static const struct ctl_table mq_sysctls[] = {
 		.data		= &init_ipc_ns.mq_msgsize_default,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &msg_maxsize_limit_min,
 		.extra2		= &msg_maxsize_limit_max,
@@ -143,12 +148,13 @@ bool setup_mq_sysctls(struct ipc_namespace *ns)
 				tbl[i].data = NULL;
 		}
 
-		ns->mq_sysctls = __register_sysctl_table(&ns->mq_set,
-							 "fs/mqueue", tbl,
-							 ARRAY_SIZE(mq_sysctls));
-	}
-	if (!ns->mq_sysctls) {
+		ns->mq_sysctls = __register_sysctl_table_tmpl(&ns->mq_set,
+							      "fs/mqueue",
+							      CTL_TABLE_TMPL(mq_sysctls),
+							      tbl, ARRAY_SIZE(mq_sysctls));
 		kfree(tbl);
+	}
+	if (!ns->mq_sysctls) {
 		retire_sysctl_set(&ns->mq_set);
 		return false;
 	}
@@ -158,10 +164,6 @@ bool setup_mq_sysctls(struct ipc_namespace *ns)
 
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

