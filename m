From: Sam Ravnborg <sam@ravnborg.org>
Date: Sat, 30 Mar 2024 10:57:38 +0100
Subject: [PATCH 02/10] sparc64: Fix prototype warnings in traps_64.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240330-sparc64-warnings-v1-2-37201023ee2f@ravnborg.org>
References: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
In-Reply-To: <20240330-sparc64-warnings-v1-0-37201023ee2f@ravnborg.org>
To: Andreas Larsson <andreas@gaisler.com>, 
 "David S. Miller" <davem@davemloft.net>, sparclinux@vger.kernel.org
Cc: Nick Bowler <nbowler@draconx.ca>, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, Sam Ravnborg <sam@ravnborg.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711792675; l=2153;
 i=sam@ravnborg.org; s=20230107; h=from:subject:message-id;
 bh=x35RxU+Vu3bnerMBWt77mDb+LYsbUbJuDZXBkLmdqBE=;
 b=sJOxVCwvgkeOscu8VipEE3bBj95LtQd0tKjvKMM3RSrFFjm6lQa4M09UYF9bg4ZRp+h4+v/1sLSl
 XuOHO41RB5PDevDu/UuWE4KoSaaO+G/8s6ha2E+Sj/4ogWGYVRbQ
X-Developer-Key: i=sam@ravnborg.org; a=ed25519;
 pk=R0+pqV7BRYOAeOIGkyOrSNke7arx5y3LkEuNi37YEyU=
X-Endpoint-Received: by B4 Relay for sam@ravnborg.org/20230107 with auth_id=22
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the following warnings:
arch/sparc/kernel/traps_64.c:253:6: warning: no previous prototype for ‘is_no_fault_exception’
arch/sparc/kernel/traps_64.c:2035:6: warning: no previous prototype for ‘do_mcd_err’
rch/sparc/kernel/traps_64.c:2153:6: warning: no previous prototype for ‘sun4v_nonresum_error_user_handled’

In all cases make the function static as there were no users outside
traps_64.c

Signed-off-by: Sam Ravnborg <sam@ravnborg.org>
Cc: Andreas Larsson <andreas@gaisler.com>
Cc: "David S. Miller" <davem@davemloft.net>
---
 arch/sparc/kernel/traps_64.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/arch/sparc/kernel/traps_64.c b/arch/sparc/kernel/traps_64.c
index dd048023bff5..28cb0d66ab40 100644
--- a/arch/sparc/kernel/traps_64.c
+++ b/arch/sparc/kernel/traps_64.c
@@ -250,7 +250,7 @@ void sun4v_insn_access_exception_tl1(struct pt_regs *regs, unsigned long addr, u
 	sun4v_insn_access_exception(regs, addr, type_ctx);
 }
 
-bool is_no_fault_exception(struct pt_regs *regs)
+static bool is_no_fault_exception(struct pt_regs *regs)
 {
 	unsigned char asi;
 	u32 insn;
@@ -2032,7 +2032,7 @@ static void sun4v_log_error(struct pt_regs *regs, struct sun4v_error_entry *ent,
 /* Handle memory corruption detected error which is vectored in
  * through resumable error trap.
  */
-void do_mcd_err(struct pt_regs *regs, struct sun4v_error_entry ent)
+static void do_mcd_err(struct pt_regs *regs, struct sun4v_error_entry ent)
 {
 	if (notify_die(DIE_TRAP, "MCD error", regs, 0, 0x34,
 		       SIGSEGV) == NOTIFY_STOP)
@@ -2150,9 +2150,9 @@ static unsigned long sun4v_get_vaddr(struct pt_regs *regs)
 /* Attempt to handle non-resumable errors generated from userspace.
  * Returns true if the signal was handled, false otherwise.
  */
-bool sun4v_nonresum_error_user_handled(struct pt_regs *regs,
-				  struct sun4v_error_entry *ent) {
-
+static bool sun4v_nonresum_error_user_handled(struct pt_regs *regs,
+					      struct sun4v_error_entry *ent)
+{
 	unsigned int attrs = ent->err_attrs;
 
 	if (attrs & SUN4V_ERR_ATTRS_MEMORY) {

-- 
2.34.1

