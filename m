From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 13 Mar 2025 17:22:24 +0100
Subject: [PATCH v3 2/5] signal: Move signal ctl tables into signal.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250313-jag-mv_ctltables-v3-2-91f3bb434d27@kernel.org>
References: <20250313-jag-mv_ctltables-v3-0-91f3bb434d27@kernel.org>
In-Reply-To: <20250313-jag-mv_ctltables-v3-0-91f3bb434d27@kernel.org>
To: Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Andreas Larsson <andreas@gaisler.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, sparclinux@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1894;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=fhQlgeM7080CJWOaBZsIZyVJ5TKnwevZMcoSC2ybdZQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfTBkkHnWszfEhy1e1lBTDKXa5AVaVkp4UmM
 Mf3INLp/NWLE4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn0wZJAAoJELqXzVK3
 lkFPeKgMAI2vXzhLEtEoUGaLnXiuYrqG/XYoXCD+SLcm00pOPFPqons9QovrJlAapqzvcqCQzFA
 HNlFrhEfHgB7xls52RQjy6TWlfE0J4Y0nTA6GzJUbfkSrwdeAGoF3U/w1Oit2JhyYvd23Lh9tE1
 jrlgCCI/EoDZPLNP8I+CFLudtZAK0E6jqnCnhShWMj+/77np2jK3vtemPnQfMVTuUsDKFPIURnk
 KyRDBivTYPucZ2xF8jaEo1dju1lURmq7e+zGY3HwBJCyB/3ANZnhxGN/ysxDcCK6gL+CmoOZLiF
 ufex5uNJkfxo3nVyrhjYWcU0ag6H+SRnScwf9si9hRfaedc1+BTyW643ctz6W9zlK8wMgNhWiTi
 Wzq7RUPf7ghdguR9pvBLk8KPiBe5rqFCTHIvWa3plO2D0PrBCVq1dXw0ev+ze+cccljLResrI2g
 ltEqwYGXWc/syYoM1LLVj/cZDDP63E0fX8ExFlA+PEbQGu0vvZQa/gtNwNctjtpwSyxCFG+NId6
 9o=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move print-fatal-signals into its own const ctl table array in
kernel/signal.c. This is part of a greater effort to move ctl tables
into their respective subsystems which will reduce the merge conflicts
in kerenel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/signal.c | 11 +++++++++++
 kernel/sysctl.c |  8 --------
 2 files changed, 11 insertions(+), 8 deletions(-)

diff --git a/kernel/signal.c b/kernel/signal.c
index 875e97f6205a2c9daecf5bece5d53ed09667f747..347b74800f927f70a1912457f96e833cd03c642d 100644
--- a/kernel/signal.c
+++ b/kernel/signal.c
@@ -4962,9 +4962,20 @@ static const struct ctl_table signal_debug_table[] = {
 #endif
 };
 
+static const struct ctl_table signal_table[] = {
+	{
+		.procname	= "print-fatal-signals",
+		.data		= &print_fatal_signals,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+};
+
 static int __init init_signal_sysctls(void)
 {
 	register_sysctl_init("debug", signal_debug_table);
+	register_sysctl_init("kernel", signal_table);
 	return 0;
 }
 early_initcall(init_signal_sysctls);
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 7759b1ed7221f588f49ec3d81b19aeb4d2fdf2f7..6514c13800a453dd970ce60040ca8a791f831e17 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -25,7 +25,6 @@
 #include <linux/slab.h>
 #include <linux/sysctl.h>
 #include <linux/bitmap.h>
-#include <linux/signal.h>
 #include <linux/printk.h>
 #include <linux/proc_fs.h>
 #include <linux/security.h>
@@ -1626,13 +1625,6 @@ static const struct ctl_table kern_table[] = {
 		.extra2		= SYSCTL_ONE,
 	},
 #endif
-	{
-		.procname	= "print-fatal-signals",
-		.data		= &print_fatal_signals,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
 #ifdef CONFIG_SPARC
 	{
 		.procname	= "reboot-cmd",

-- 
2.47.2

