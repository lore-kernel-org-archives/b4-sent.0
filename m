From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 06 Mar 2025 12:29:45 +0100
Subject: [PATCH v2 5/6] sparc: mv sparc sysctls into their own file under
 arch/sparc/kernel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250306-jag-mv_ctltables-v2-5-71b243c8d3f8@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3848;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=hkSbq8mw9Uv98PWKXr8NFUOiogiYljqa0LH7OwMpcTY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfJh2eO5lVLjXgiAsNO3sdOE+S7/E9nKWo7e
 cYViU1dn+HE/YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnyYdnAAoJELqXzVK3
 lkFPIuUL/10CdnnBV2W5FxoLqEWelLIC1A1/yV64PD3YPmjJFsd9eAM5+J+87QWxopqYtrtshB+
 E3Y+u2y6+visLWI7nDh4tUI62vSt8g/jsuA7othOvYgtVrYDnYEzKVOiZObE3emwUs3D2jezcma
 kv1FqagAWhOwh7XGDXY6CkrNow7Zaj1dNC18hb2WCSoDrXKsqtJCvkDyH1reS9KvHYdJkCl/cGt
 ka792gzt6+ZHOiO6YUpOAMHCIRjeCDHOlin+jvbW0hd1TQqbrVbOsMPaZVfmHZysEx1dV+6YFVo
 bWPLjzmBPErrIzyCvDJYbLrusG4a9Y3S9C/oFsBMBB52nDiRTjTbDUUkz85AheJrJZTi7+XlmCc
 OBMUXhjBopF9pDN1dq4+3du2oJNlXZhCuQRZDAo+zNeJtakVPGhRMssFI+xCCtfGX0IiM8ptoWV
 4LNaP0sFNc5lBTRjsLo8ZIdq6e86sTHoFlDn+Lddp2l6sWUWr2RLhm9v93mOVMRoIGLlw+++g75
 8g=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move sparc sysctls (reboot-cmd, stop-a, scons-poweroff and tsb-ratio)
into a new file (arch/sparc/kernel/setup.c). This file will be included
for both 32 and 64 bit sparc. Leave "tsb-ratio" under SPARC64 ifdef as
it was in kernel/sysctl.c. The sysctl table register is called with
arch_initcall placing it after its original place in proc_root_init.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kerenel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 arch/sparc/kernel/Makefile |  1 +
 arch/sparc/kernel/setup.c  | 46 ++++++++++++++++++++++++++++++++++++++++++++++
 kernel/sysctl.c            | 35 -----------------------------------
 3 files changed, 47 insertions(+), 35 deletions(-)

diff --git a/arch/sparc/kernel/Makefile b/arch/sparc/kernel/Makefile
index 58ea4ef9b622bd18f2160b34762c69b48f3de8c6..3453f330e363cffe430806cd00a32b06202088b3 100644
--- a/arch/sparc/kernel/Makefile
+++ b/arch/sparc/kernel/Makefile
@@ -35,6 +35,7 @@ obj-y                   += process.o
 obj-y                   += signal_$(BITS).o
 obj-y                   += sigutil_$(BITS).o
 obj-$(CONFIG_SPARC32)   += ioport.o
+obj-y                   += setup.o
 obj-y                   += setup_$(BITS).o
 obj-y                   += idprom.o
 obj-y                   += sys_sparc_$(BITS).o
diff --git a/arch/sparc/kernel/setup.c b/arch/sparc/kernel/setup.c
new file mode 100644
index 0000000000000000000000000000000000000000..4975867d9001b63b25770334116f2038a561c28c
--- /dev/null
+++ b/arch/sparc/kernel/setup.c
@@ -0,0 +1,46 @@
+// SPDX-License-Identifier: GPL-2.0
+
+#include <asm/setup.h>
+#include <linux/sysctl.h>
+
+static const struct ctl_table sparc_sysctl_table[] = {
+	{
+		.procname	= "reboot-cmd",
+		.data		= reboot_command,
+		.maxlen		= 256,
+		.mode		= 0644,
+		.proc_handler	= proc_dostring,
+	},
+	{
+		.procname	= "stop-a",
+		.data		= &stop_a_enabled,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+	{
+		.procname	= "scons-poweroff",
+		.data		= &scons_pwroff,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+#ifdef CONFIG_SPARC64
+	{
+		.procname	= "tsb-ratio",
+		.data		= &sysctl_tsb_ratio,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+#endif
+};
+
+
+static int __init init_sparc_sysctls(void)
+{
+	register_sysctl_init("kernel", sparc_sysctl_table);
+	return 0;
+}
+
+arch_initcall(init_sparc_sysctls);
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index dc3747cc72d470662879e4f2b7f2651505b7ca90..0dc41eea1dbd34396c323118cfd0e3133c6993a1 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -70,9 +70,6 @@
 #include <asm/nmi.h>
 #include <asm/io.h>
 #endif
-#ifdef CONFIG_SPARC
-#include <asm/setup.h>
-#endif
 #ifdef CONFIG_RT_MUTEXES
 #include <linux/rtmutex.h>
 #endif
@@ -1623,38 +1620,6 @@ static const struct ctl_table kern_table[] = {
 		.extra2		= SYSCTL_ONE,
 	},
 #endif
-#ifdef CONFIG_SPARC
-	{
-		.procname	= "reboot-cmd",
-		.data		= reboot_command,
-		.maxlen		= 256,
-		.mode		= 0644,
-		.proc_handler	= proc_dostring,
-	},
-	{
-		.procname	= "stop-a",
-		.data		= &stop_a_enabled,
-		.maxlen		= sizeof (int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-	{
-		.procname	= "scons-poweroff",
-		.data		= &scons_pwroff,
-		.maxlen		= sizeof (int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
-#ifdef CONFIG_SPARC64
-	{
-		.procname	= "tsb-ratio",
-		.data		= &sysctl_tsb_ratio,
-		.maxlen		= sizeof (int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
 #ifdef CONFIG_PARISC
 	{
 		.procname	= "soft-power",

-- 
2.47.2

