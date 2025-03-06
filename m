From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 06 Mar 2025 12:29:41 +0100
Subject: [PATCH v2 1/6] panic: Move panic ctl tables into panic.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-jag-mv_ctltables-v2-1-71b243c8d3f8@kernel.org>
References: <20250306-jag-mv_ctltables-v2-0-71b243c8d3f8@kernel.org>
In-Reply-To: <20250306-jag-mv_ctltables-v2-0-71b243c8d3f8@kernel.org>
To: Kees Cook <kees@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>, Heiko Carstens <hca@linux.ibm.com>, 
 Vasily Gorbik <gor@linux.ibm.com>, 
 Alexander Gordeev <agordeev@linux.ibm.com>, 
 Christian Borntraeger <borntraeger@linux.ibm.com>, 
 Sven Schnelle <svens@linux.ibm.com>, 
 Gerald Schaefer <gerald.schaefer@linux.ibm.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, sparclinux@vger.kernel.org, 
 linux-s390@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3223;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=99SvQXLjoPiWd0/gxkEdf3AsdJ/IenQsyJp3SptYBS0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfJh2UQmfyhQ+EURZAkXCrvML2DKQGqYGu4r
 aqjXVDEii6Yi4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnyYdlAAoJELqXzVK3
 lkFPdYAL/j/eLPROZngY5rs5T5RaG4XQ/S80kGl9A+zpvq7RocnU8PM8Pc7vCZaCUN5AaJs86xy
 nILcjVhHH4miZlpoNJlyIAxgadB/xyzrwYGGClLFUlH5vk2KfU51blKWPkY1MURehM45fGvKmPI
 d1vCwcBkbaJoOPOu0h6HFEqxNU/fCalmQQACoIaw32o298YJ9sl1zqxIEcbOgB6S86NZaEz67V8
 5UMaJQe7g+5y4bixa6gjKKQZ/stWF5fNu6AlcHqYZBz10aiaXRX0/ucaSrpBY54T+zox+ukxpEO
 JiPCRQCIR9IGXLX8PcTrTDe21NqX89Z3shcCI2ciUNfP//GduQsnMHiTrjUQstTYUIQTvrLwnwG
 8kyvBiZTBR78AFImMgCQ9TpfVYnFGCYMMFIcB1OXH9zub6zyV6kFyX9vAP6uwisccl6nWBIo5RZ
 WbSO9xaefycxW8NJsDn5VPoZQfm6xb1GQM4P61CkaYmcLVVv/SMLGmRvhy0C2CKo75meAIiAFp7
 H4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move panic, panic_on_oops, panic_print, panic_on_warn into
kerne/panic.c. This is part of a greater effort to move ctl tables into
their respective subsystems which will reduce the merge conflicts in
kerenel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/panic.c  | 30 ++++++++++++++++++++++++++++++
 kernel/sysctl.c | 31 -------------------------------
 2 files changed, 30 insertions(+), 31 deletions(-)

diff --git a/kernel/panic.c b/kernel/panic.c
index d8635d5cecb2505da1c08a4f70814e9b87ac3b37..f9bf88f4c26216cd5a93754378a36ea1e841472a 100644
--- a/kernel/panic.c
+++ b/kernel/panic.c
@@ -96,6 +96,36 @@ static const struct ctl_table kern_panic_table[] = {
 		.extra2         = SYSCTL_ONE,
 	},
 #endif
+	{
+		.procname	= "panic",
+		.data		= &panic_timeout,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+	{
+		.procname	= "panic_on_oops",
+		.data		= &panic_on_oops,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+	{
+		.procname	= "panic_print",
+		.data		= &panic_print,
+		.maxlen		= sizeof(unsigned long),
+		.mode		= 0644,
+		.proc_handler	= proc_doulongvec_minmax,
+	},
+	{
+		.procname	= "panic_on_warn",
+		.data		= &panic_on_warn,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec_minmax,
+		.extra1		= SYSCTL_ZERO,
+		.extra2		= SYSCTL_ONE,
+	},
 	{
 		.procname       = "warn_limit",
 		.data           = &warn_limit,
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index cb57da499ebb1216cefb3705694ab62028fee03e..7759b1ed7221f588f49ec3d81b19aeb4d2fdf2f7 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -26,7 +26,6 @@
 #include <linux/sysctl.h>
 #include <linux/bitmap.h>
 #include <linux/signal.h>
-#include <linux/panic.h>
 #include <linux/printk.h>
 #include <linux/proc_fs.h>
 #include <linux/security.h>
@@ -1610,13 +1609,6 @@ int proc_do_static_key(const struct ctl_table *table, int write,
 }
 
 static const struct ctl_table kern_table[] = {
-	{
-		.procname	= "panic",
-		.data		= &panic_timeout,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
 #ifdef CONFIG_PROC_SYSCTL
 	{
 		.procname	= "tainted",
@@ -1803,20 +1795,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_dointvec,
 	},
 #endif
-	{
-		.procname	= "panic_on_oops",
-		.data		= &panic_on_oops,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-	{
-		.procname	= "panic_print",
-		.data		= &panic_print,
-		.maxlen		= sizeof(unsigned long),
-		.mode		= 0644,
-		.proc_handler	= proc_doulongvec_minmax,
-	},
 	{
 		.procname	= "ngroups_max",
 		.data		= (void *)&ngroups_max,
@@ -1990,15 +1968,6 @@ static const struct ctl_table kern_table[] = {
 		.extra2		= SYSCTL_ONE_THOUSAND,
 	},
 #endif
-	{
-		.procname	= "panic_on_warn",
-		.data		= &panic_on_warn,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec_minmax,
-		.extra1		= SYSCTL_ZERO,
-		.extra2		= SYSCTL_ONE,
-	},
 #ifdef CONFIG_TREE_RCU
 	{
 		.procname	= "panic_on_rcu_stall",

-- 
2.47.2

