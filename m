From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:46 -0600
Subject: [PATCH 7/8] powerpc/rtas: warn on unsafe argument to
 rtas_call_unlocked()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-7-010e4416f13f@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=999;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=pRZxRj5QyWZZ4hjbHO7mJTWLLN6i/dgDWwjlJ8ybXFE=;
 b=Rkqr5NU/NmQkjMAiyWXvNzoRrabkCKdVa2SubSeba/PWegiwywXG43gH5h/cni5BSahtv5QWC
 aHznaQvex61BBHtWlutyjRX5cjjKBrQY6+07y21mTmGWUFfWVljZ46l
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Any caller of rtas_call_unlocked() must provide an rtas_args parameter
block distinct from the core rtas_args buffer used by the rtas_call()
path. It's an unlikely error to make, but the potential consequences
are grim, and it's trivial to check.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 633c925164e7..47a2aa43d7d4 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1042,6 +1042,13 @@ void rtas_call_unlocked(struct rtas_args *args, int token, int nargs, int nret,
 {
 	va_list list;
 
+	/*
+	 * Callers must not use rtas_args; otherwise they risk
+	 * corrupting the state of the rtas_call() path, which is
+	 * serialized by rtas_lock.
+	 */
+	WARN_ON(args == &rtas_args);
+
 	va_start(list, nret);
 	va_rtas_call(args, token, nargs, nret, list);
 	va_end(list);

-- 
2.39.1

