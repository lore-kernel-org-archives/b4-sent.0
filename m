From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 12 Aug 2026 13:48:10 +0800
Subject: [PATCH 4/5] powerpc/spufs: fix context state race in
 spu_acquire_saved()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-spufs-fixes-v1-4-449e201d9f64@outlook.com>
References: <20260812-spufs-fixes-v1-0-449e201d9f64@outlook.com>
In-Reply-To: <20260812-spufs-fixes-v1-0-449e201d9f64@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 David Howells <dhowells@redhat.com>, Al Viro <viro@zeniv.linux.org.uk>, 
 Jeremy Kerr <jk@ozlabs.org>, Arnd Bergmann <arnd@arndb.de>, 
 Paul Mackerras <paulus@ozlabs.org>, 
 Luke Browning <lukebr@linux.vnet.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2492;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=LOgiV6k5pQqtCquvEoYhVH8oPI1aXbE98cx2n5Jk4Uw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBpOOYGw9Usyiu18nAvvC4tk+pYuNA/y3Kxw4tCR0
 3fYQsOdZ3eUsjCIcTHIiimyHC+49M3Cd4vuFp8tyTBzWJlAhjBwcQrARD7NYPhnL7HT8n2xe+RW
 wdSNS6tr+3c/U0qeJrJOymRpoub7Kq7ZjAz/hNmsXp2Jddq/pHbOl3+Prn3cN5+17URqQvtmlsr
 kuGomAPzFSKY=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spu_acquire_saved() returns with ctx->state_mutex held and the context
in SPU_STATE_SAVED.  It tests ctx->state once and, if the context is
still running, sets SPU_SCHED_WAS_ACTIVE and calls spu_deactivate().
That path reaches __spu_deactivate(ctx, 1, MAX_PRIO), which drops
state_mutex around spu_schedule() once spu_unschedule() has unbound the
context, so the test result is stale by the time the function returns.

A second thread reading any saved-state file of the same context can
take state_mutex in that window, observe SPU_STATE_SAVED and skip its
own deactivate.  SPU_SCHED_WAS_ACTIVE is a single bit in
ctx->sched_flags rather than a per-acquirer token, so that thread's
spu_release_saved() consumes the bit and calls spu_activate(), binding
the context back onto an SPU.  The first thread then returns from
spu_acquire_saved() with the context RUNNABLE, reads a save image the
SPU is concurrently writing, and trips the
BUG_ON(ctx->state != SPU_STATE_SAVED) in its own spu_release_saved(),
leaving state_mutex held.

Fix by retesting the state after spu_deactivate() returns, which also
re-sets SPU_SCHED_WAS_ACTIVE so the acquirer keeps its own reactivation
token.

Fixes: e65c2f6fcebb ("[POWERPC] spufs: decouple spu scheduler from spufs_spu_run (asynchronous scheduling)")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Found by inspection; I have no Cell/PS3 hardware, so this is
compile-tested only.
---
 arch/powerpc/platforms/cell/spufs/context.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/platforms/cell/spufs/context.c b/arch/powerpc/platforms/cell/spufs/context.c
index 44377dfff1f8..2414ad9be0ae 100644
--- a/arch/powerpc/platforms/cell/spufs/context.c
+++ b/arch/powerpc/platforms/cell/spufs/context.c
@@ -107,7 +107,7 @@ void spu_forget(struct spu_context *ctx)
 	 * want this context to be rescheduled on release.
 	 */
 	mutex_lock(&ctx->state_mutex);
-	if (ctx->state != SPU_STATE_SAVED)
+	while (ctx->state != SPU_STATE_SAVED)
 		spu_deactivate(ctx);
 
 	mm = ctx->owner;
@@ -150,7 +150,7 @@ int spu_acquire_saved(struct spu_context *ctx)
 	if (ret)
 		return ret;
 
-	if (ctx->state != SPU_STATE_SAVED) {
+	while (ctx->state != SPU_STATE_SAVED) {
 		set_bit(SPU_SCHED_WAS_ACTIVE, &ctx->sched_flags);
 		spu_deactivate(ctx);
 	}

-- 
2.51.2

