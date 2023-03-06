From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:42 -0600
Subject: [PATCH 3/8] powerpc/rtas: rtas_call_unlocked() kerneldoc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-3-010e4416f13f@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=1514;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=aNVQYLIYeghDvruaF+K17N+vFRgqaX8hcKm6FIHWhcU=;
 b=LntxrFKMlrhF9aFjjxyXXyYyP1Piy6ap2oSPQLn+38HuUrpD1XXw4JjbJ2YiakTWd7YRMT4mu
 nwSeXE6mlLYAJIJ5ZjcFF/zs4sbogpjGPyNRFH9VDSYqi8rEuEP8rHl
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for rtas_call_unlocked(), including details on how
it differs from rtas_call().

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 9256cfaa8b6f..c73b01d722f6 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1016,6 +1016,23 @@ va_rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret,
 	do_enter_rtas(args);
 }
 
+/**
+ * rtas_call_unlocked() - Invoke an RTAS firmware function without synchronization.
+ * @args: RTAS parameter block to be used for the call, must obey RTAS addressing
+ *        constraints.
+ * @token: Identifies the function being invoked.
+ * @nargs: Number of input parameters. Does not include token.
+ * @nret: Number of output parameters, including the call status.
+ * @....: List of @nargs input parameters.
+ *
+ * Invokes the RTAS function indicated by @token, which the caller
+ * should obtain via rtas_function_token().
+ *
+ * This function is similar to rtas_call(), but must be used with a
+ * limited set of RTAS calls specifically exempted from the general
+ * requirement that only one RTAS call may be in progress at any
+ * time. Examples include stop-self and ibm,nmi-interlock.
+ */
 void rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret, ...)
 {
 	va_list list;

-- 
2.39.1

