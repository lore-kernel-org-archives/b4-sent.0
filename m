From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:40 -0600
Subject: [PATCH 1/8] powerpc/rtas: ensure 8-byte alignment for struct
 rtas_args
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-1-010e4416f13f@linux.ibm.com>
References: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
In-Reply-To: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Tyrel Datwyler <tyreld@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, Andrew Donnellan <ajd@linux.ibm.com>, 
 Nick Child <nnac123@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=1749;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=zKZp717erQqHtOsvnKGf8gvxVdLkX7Wsrykg3a+ZIso=;
 b=8LQBmszSbhhO1K662MFxCVWJBULbaSR1bc6FAbL87L53kqm9VMT24SZFjff7JqszJMrzUUwOL
 lkKnhMWsQHuC5JdsUAT0Z7Sf/mQQ/bPP0enmq/PvhgtELu8RcIa/9EI
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CHRP and PAPR agree: "In order to make an RTAS call, the operating
system must construct an argument call buffer aligned on an eight byte
boundary in physically contiguous real memory [...]." (7.2.7 Calling
Mechanism and Conventions).

struct rtas_args is the type used for this argument call buffer. The
unarchitected 'rets' member happens to produce 8-byte alignment for
the struct on 64-bit targets in practice. But without an alignment
directive the structure will have only 4-byte alignment on 32-bit
targets:

  $ nm b/{before,after}/chrp32/vmlinux | grep rtas_args
  c096881c b rtas_args
  c0968820 b rtas_args

Add an alignment directive to the struct rtas_args declaration so all
instances have the alignment required by the specs. rtas-types.h no
longer refers to any spinlock types, so drop the spinlock_types.h
inclusion while we're here.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/include/asm/rtas-types.h | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/include/asm/rtas-types.h b/arch/powerpc/include/asm/rtas-types.h
index f2ad4a96cbc5..861145c8a021 100644
--- a/arch/powerpc/include/asm/rtas-types.h
+++ b/arch/powerpc/include/asm/rtas-types.h
@@ -2,7 +2,8 @@
 #ifndef _ASM_POWERPC_RTAS_TYPES_H
 #define _ASM_POWERPC_RTAS_TYPES_H
 
-#include <linux/spinlock_types.h>
+#include <linux/compiler_attributes.h>
+#include <linux/sizes.h>
 
 typedef __be32 rtas_arg_t;
 
@@ -12,7 +13,7 @@ struct rtas_args {
 	__be32 nret;
 	rtas_arg_t args[16];
 	rtas_arg_t *rets;     /* Pointer to return values in args[]. */
-};
+} __aligned(SZ_8);
 
 struct rtas_t {
 	unsigned long entry;		/* physical address pointer */

-- 
2.39.1

