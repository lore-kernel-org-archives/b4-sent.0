From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 06 Mar 2025 12:29:44 +0100
Subject: [PATCH v2 4/6] stack_tracer: move sysctl registration to
 kernel/trace/trace_stack.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-jag-mv_ctltables-v2-4-71b243c8d3f8@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1944;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=pNjcBvmaJVdCgzpg/FmoYLnX8KqZ21YzHmxlpf6uAsM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfJh2alAR7cgQ9qnoQ1dS1TtnuKGA+eVEsFK
 VJ3ED1gF8zG84kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnyYdmAAoJELqXzVK3
 lkFPccsL/R6gdkbabbHbYIySeuZWAhaEq69GXChzsk4MkziXKdS1nqhAQRyagOvwm3v4TLsQ5wn
 EeSA8nqBfgCSzv3Zc4J8jPsoIB1r/WAYBivWOm9s4+nlfGKX853EnYVMzFQoQda+uxN4nXvqdD5
 jYnjRDFXtobyLtlB3wEXvxHsLU2BwzRKeSk0U6ymKOaFutC5iLl3Ts/i2pgTqhUVtGR9xDE/AUl
 FvZKvdvnGnTcWq0kPwYcFDeADGJqtJwOZBFXF6B+du5+Qfc/mFesuMLMN1gNg/4pX4XMoSHS+GR
 phhE6S6SwL/M/XUCsM2Hq0JGz6fJBzfrbEC+thYwoxiGtDKAA2ZcrY/au+3bqtzQ06U674AeYRH
 saCxNzr960/eGSe4Hn6RkOY02dvH3Uy0e1MDCwE8qe00EGCWf6iUe8lTPHetI0nUOqcujw+td2r
 9uMmTB1rt7y7AC+VnEahIQQxPWfR4PP2ojmk2bwBptsB3O58TTI9c2RPCsqZaDAR0/SBlU6HEi5
 eI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move stack_tracer_enabled into trace_stack_sysctl_table. This is part of
a greater effort to move ctl tables into their respective subsystems
which will reduce the merge conflicts in kerenel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c            | 10 ----------
 kernel/trace/trace_stack.c | 20 ++++++++++++++++++++
 2 files changed, 20 insertions(+), 10 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index baa250e223a26bafc39cb7a7d7635b4f7f5dcf56..dc3747cc72d470662879e4f2b7f2651505b7ca90 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -68,7 +68,6 @@
 
 #ifdef CONFIG_X86
 #include <asm/nmi.h>
-#include <asm/stacktrace.h>
 #include <asm/io.h>
 #endif
 #ifdef CONFIG_SPARC
@@ -1674,15 +1673,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_dointvec,
 	},
 #endif
-#ifdef CONFIG_STACK_TRACER
-	{
-		.procname	= "stack_tracer_enabled",
-		.data		= &stack_tracer_enabled,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= stack_trace_sysctl,
-	},
-#endif
 #ifdef CONFIG_MODULES
 	{
 		.procname	= "modprobe",
diff --git a/kernel/trace/trace_stack.c b/kernel/trace/trace_stack.c
index 14c6f272c4d8a382070d45e1cf0ee97db38831c9..b7ffbc1da8357f9c252cb8936c8f789daa97eb9a 100644
--- a/kernel/trace/trace_stack.c
+++ b/kernel/trace/trace_stack.c
@@ -578,3 +578,23 @@ static __init int stack_trace_init(void)
 }
 
 device_initcall(stack_trace_init);
+
+
+static const struct ctl_table trace_stack_sysctl_table[] = {
+	{
+		.procname	= "stack_tracer_enabled",
+		.data		= &stack_tracer_enabled,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= stack_trace_sysctl,
+	},
+};
+
+static int __init init_trace_stack_sysctls(void)
+{
+	register_sysctl_init("kernel", trace_stack_sysctl_table);
+	return 0;
+}
+subsys_initcall(init_trace_stack_sysctls);
+
+

-- 
2.47.2

