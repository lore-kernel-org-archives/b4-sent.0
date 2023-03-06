From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:44 -0600
Subject: [PATCH 5/8] powerpc/rtas: rename va_rtas_call_unlocked() to
 va_rtas_call()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-5-010e4416f13f@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=1417;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=zmpUoFBlYm32z8pVAFlRUtoMohEKmXli9AeFhKjMQFg=;
 b=VGctELNY89LqxoRzb4VrgmHdLwMUcWBqKyta27DSpPKXM1UtERnFPbWJQIZhuaUny4HzEJxrS
 E50XCOo/kufC0X9abjpsWnuTo12q8ffkCOWJGT6mdo4/7vOSr+C2vC6
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The function name va_rtas_call_unlocked() is confusing: it may be
called with or without rtas_lock held. Rename it to va_rtas_call().

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 9 ++++-----
 1 file changed, 4 insertions(+), 5 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index c29c38b1a55a..96a10a0abe3a 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -996,9 +996,8 @@ static void __init init_error_log_max(void) {}
 #endif
 
 
-static void
-va_rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret,
-		      va_list list)
+static void va_rtas_call(struct rtas_args *args, int token, int nargs, int nret,
+			 va_list list)
 {
 	int i;
 
@@ -1038,7 +1037,7 @@ void rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret,
 	va_list list;
 
 	va_start(list, nret);
-	va_rtas_call_unlocked(args, token, nargs, nret, list);
+	va_rtas_call(args, token, nargs, nret, list);
 	va_end(list);
 }
 
@@ -1138,7 +1137,7 @@ int rtas_call(int token, int nargs, int nret, int *outputs, ...)
 	args = &rtas_args;
 
 	va_start(list, outputs);
-	va_rtas_call_unlocked(args, token, nargs, nret, list);
+	va_rtas_call(args, token, nargs, nret, list);
 	va_end(list);
 
 	/* A -1 return code indicates that the last command couldn't

-- 
2.39.1

