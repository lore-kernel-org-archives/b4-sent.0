From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:43 -0600
Subject: [PATCH 4/8] powerpc/rtas: fix miswording in rtas_function
 kerneldoc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-4-010e4416f13f@linux.ibm.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=821;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=KDcIY5p36gGZFwMr2XpuMaaBgQzZ4G0iZKmqta+ah0E=;
 b=5snt22o7WgRBLK+n582FSb9KLCYKnW8sx10uIsfjoCWRb3TScmAKu/gG4OWITLRLpNwmUmgTO
 4Yw+8aQBObXAJp0oilRHxS8fJC5aYqVdVLXEkWGjP9rOjGxScG/cw/k
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 'filter' member is a pointer, not a bool; fix the wording
accordingly.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index c73b01d722f6..c29c38b1a55a 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -68,7 +68,7 @@ struct rtas_filter {
  *                            functions are believed to have no users on
  *                            ppc64le, and we want to keep it that way. It does
  *                            not make sense for this to be set when @filter
- *                            is false.
+ *                            is NULL.
  */
 struct rtas_function {
 	s32 token;

-- 
2.39.1

