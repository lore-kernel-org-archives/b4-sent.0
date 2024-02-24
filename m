From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 24 Feb 2024 18:42:23 +0100
Subject: [PATCH v2 2/7] sparc32: Fix build with trapbase
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240224-sam-fix-sparc32-all-builds-v2-2-1f186603c5c4@ravnborg.org>
References: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
In-Reply-To: <20240224-sam-fix-sparc32-all-builds-v2-0-1f186603c5c4@ravnborg.org>
To: "Maciej W. Rozycki" <macro@orcam.me.uk>, sparclinux@vger.kernel.org, 
 Andreas Larsson <andreas@gaisler.com>, Randy Dunlap <rdunlap@infradead.org>
Cc: Miquel Raynal <miquel.raynal@bootlin.com>, 
 linux-parport@lists.infradead.org, "David S. Miller" <davem@davemloft.net>, 
 Arnd Bergmann <arnd@arndb.de>, linux-kernel@vger.kernel.org, 
 Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708796545; l=4806;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=yODVsKtXRLRL5P00tESgJdJda/SYlfy6l2Y847zfeCU=;
 b=9FtF0vthGV5KV/hPt5Yc5TbLmZTI0ewIdffIWFA7tPr+zMCJ1cWT6xw/uPgyN67nKD8Ds9tpzUpF
 so4wk2r8AiAQBjVYbWLaHrouAw+VOauFmCspxcSiA8y0iTb2VBVv
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following build errors:
irq_32.c:258:7: error: array subscript [16, 79] is outside array bounds of 'struct tt_entry[1]
irq_32.c:271:14: error: assignment to 'struct tt_entry *' from incompatible pointer type 'struct tt_entry (*)[]

trapbase is a pointer to an array of tt_entry, but the code declared it
as a pointer so the compiler see a single entry and not an array.
Fix this by modifyinf the declaration to be an array, and modify all
users to take the address of the first member.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Acked-by: Randy Dunlap <rdunlap@infradead.org>
Tested-by: Randy Dunlap <rdunlap@infradead.org> # build-tested
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/irq_32.c   | 6 +++---
 arch/sparc/kernel/kernel.h   | 8 ++++----
 arch/sparc/kernel/kgdb_32.c  | 4 ++--
 arch/sparc/kernel/leon_smp.c | 6 +++---
 arch/sparc/kernel/setup_32.c | 4 ++--
 5 files changed, 14 insertions(+), 14 deletions(-)

diff --git a/arch/sparc/kernel/irq_32.c b/arch/sparc/kernel/irq_32.c
index e8452be5123b..8605dd710f3c 100644
--- a/arch/sparc/kernel/irq_32.c
+++ b/arch/sparc/kernel/irq_32.c
@@ -268,11 +268,11 @@ int sparc_floppy_request_irq(unsigned int irq, irq_handler_t irq_handler)
 	if (sparc_cpu_model != sparc_leon) {
 		struct tt_entry *trap_table;
 
-		trap_table = &trapbase_cpu1;
+		trap_table = &trapbase_cpu1[0];
 		INSTANTIATE(trap_table)
-		trap_table = &trapbase_cpu2;
+		trap_table = &trapbase_cpu2[0];
 		INSTANTIATE(trap_table)
-		trap_table = &trapbase_cpu3;
+		trap_table = &trapbase_cpu3[0];
 		INSTANTIATE(trap_table)
 	}
 #endif
diff --git a/arch/sparc/kernel/kernel.h b/arch/sparc/kernel/kernel.h
index 15da3c0597a5..a8fb7c0bf053 100644
--- a/arch/sparc/kernel/kernel.h
+++ b/arch/sparc/kernel/kernel.h
@@ -138,10 +138,10 @@ extern unsigned int t_nmi[];
 extern unsigned int linux_trap_ipi15_sun4d[];
 extern unsigned int linux_trap_ipi15_sun4m[];
 
-extern struct tt_entry trapbase;
-extern struct tt_entry trapbase_cpu1;
-extern struct tt_entry trapbase_cpu2;
-extern struct tt_entry trapbase_cpu3;
+extern struct tt_entry trapbase[];
+extern struct tt_entry trapbase_cpu1[];
+extern struct tt_entry trapbase_cpu2[];
+extern struct tt_entry trapbase_cpu3[];
 
 extern char cputypval[];
 
diff --git a/arch/sparc/kernel/kgdb_32.c b/arch/sparc/kernel/kgdb_32.c
index 58ad3f7de1fb..3b2c673ec627 100644
--- a/arch/sparc/kernel/kgdb_32.c
+++ b/arch/sparc/kernel/kgdb_32.c
@@ -37,7 +37,7 @@ void pt_regs_to_gdb_regs(unsigned long *gdb_regs, struct pt_regs *regs)
 	gdb_regs[GDB_Y] = regs->y;
 	gdb_regs[GDB_PSR] = regs->psr;
 	gdb_regs[GDB_WIM] = 0;
-	gdb_regs[GDB_TBR] = (unsigned long) &trapbase;
+	gdb_regs[GDB_TBR] = (unsigned long) &trapbase[0];
 	gdb_regs[GDB_PC] = regs->pc;
 	gdb_regs[GDB_NPC] = regs->npc;
 	gdb_regs[GDB_FSR] = 0;
@@ -72,7 +72,7 @@ void sleeping_thread_to_gdb_regs(unsigned long *gdb_regs, struct task_struct *p)
 
 	gdb_regs[GDB_PSR] = t->kpsr;
 	gdb_regs[GDB_WIM] = t->kwim;
-	gdb_regs[GDB_TBR] = (unsigned long) &trapbase;
+	gdb_regs[GDB_TBR] = (unsigned long) &trapbase[0];
 	gdb_regs[GDB_PC] = t->kpc;
 	gdb_regs[GDB_NPC] = t->kpc + 4;
 	gdb_regs[GDB_FSR] = 0;
diff --git a/arch/sparc/kernel/leon_smp.c b/arch/sparc/kernel/leon_smp.c
index 991e9ad3d3e8..1ee393abc463 100644
--- a/arch/sparc/kernel/leon_smp.c
+++ b/arch/sparc/kernel/leon_smp.c
@@ -245,13 +245,13 @@ void __init leon_smp_done(void)
 
 	/* Free unneeded trap tables */
 	if (!cpu_present(1)) {
-		free_reserved_page(virt_to_page(&trapbase_cpu1));
+		free_reserved_page(virt_to_page(&trapbase_cpu1[0]));
 	}
 	if (!cpu_present(2)) {
-		free_reserved_page(virt_to_page(&trapbase_cpu2));
+		free_reserved_page(virt_to_page(&trapbase_cpu2[0]));
 	}
 	if (!cpu_present(3)) {
-		free_reserved_page(virt_to_page(&trapbase_cpu3));
+		free_reserved_page(virt_to_page(&trapbase_cpu3[0]));
 	}
 	/* Ok, they are spinning and ready to go. */
 	smp_processors_ready = 1;
diff --git a/arch/sparc/kernel/setup_32.c b/arch/sparc/kernel/setup_32.c
index e3b72a7b46d3..704375c061e7 100644
--- a/arch/sparc/kernel/setup_32.c
+++ b/arch/sparc/kernel/setup_32.c
@@ -67,7 +67,7 @@ static void prom_sync_me(void)
 	__asm__ __volatile__("wr %0, 0x0, %%tbr\n\t"
 			     "nop\n\t"
 			     "nop\n\t"
-			     "nop\n\t" : : "r" (&trapbase));
+			     "nop\n\t" : : "r" (&trapbase[0]));
 
 	prom_printf("PROM SYNC COMMAND...\n");
 	show_mem();
@@ -285,7 +285,7 @@ void __init setup_arch(char **cmdline_p)
 	int i;
 	unsigned long highest_paddr;
 
-	sparc_ttable = &trapbase;
+	sparc_ttable = &trapbase[0];
 
 	/* Initialize PROM console and command line. */
 	*cmdline_p = prom_getbootargs();

-- 
2.34.1

