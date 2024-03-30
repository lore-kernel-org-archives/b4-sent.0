From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:41 +0100
Subject: [PATCH 05/10] sparc64: Fix prototype warning for uprobe_trap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-5-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=1615;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=sf6irUkOpJPOHLMvdHazAyqgENdDMFjW8tXTw6Ir0YU=;
 b=Gfn8FAdb7ELFmL9Xcub36vvtnz7E7OCSYIXAo8fV5xyY4x0+njqdmCR+uM9iEVVY8///Z73EpFA4
 RPXfaePaAJcWQc+Vj5Y6mTgZtSJLBCRZRV1jUnnsJYbTcN+SmQ1Y
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warning:
arch/sparc/kernel/uprobes.c:237:17: warning: no previous prototype for ‘uprobe_trap’

Add a prototype to kernel/kernel.h to silence the warning.
This is a fix already used for other trap handlers.

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/kernel.h  | 4 ++++
 arch/sparc/kernel/uprobes.c | 2 ++
 2 files changed, 6 insertions(+)

diff --git a/arch/sparc/kernel/kernel.h b/arch/sparc/kernel/kernel.h
index a8fb7c0bf053..8328a3b78a44 100644
--- a/arch/sparc/kernel/kernel.h
+++ b/arch/sparc/kernel/kernel.h
@@ -40,6 +40,10 @@ int handle_popc(u32 insn, struct pt_regs *regs);
 void handle_lddfmna(struct pt_regs *regs, unsigned long sfar, unsigned long sfsr);
 void handle_stdfmna(struct pt_regs *regs, unsigned long sfar, unsigned long sfsr);
 
+/* uprobes.c */
+asmlinkage void uprobe_trap(struct pt_regs *regs,
+			    unsigned long trap_level);
+
 /* smp_64.c */
 void __irq_entry smp_call_function_client(int irq, struct pt_regs *regs);
 void __irq_entry smp_call_function_single_client(int irq, struct pt_regs *regs);
diff --git a/arch/sparc/kernel/uprobes.c b/arch/sparc/kernel/uprobes.c
index 1a0600206bf5..305017bec164 100644
--- a/arch/sparc/kernel/uprobes.c
+++ b/arch/sparc/kernel/uprobes.c
@@ -18,6 +18,8 @@
 
 #include <asm/cacheflush.h>
 
+#include "kernel.h"
+
 /* Compute the address of the breakpoint instruction and return it.
  *
  * Note that uprobe_get_swbp_addr is defined as a weak symbol in

-- 
2.34.1

