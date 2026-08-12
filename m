From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 12 Aug 2026 13:48:09 +0800
Subject: [PATCH 3/5] powerpc/spufs: take a reference on contexts pulled off
 the runqueue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260812-spufs-fixes-v1-3-449e201d9f64@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3301;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=T5RasOG3hMtgArux2E1H2cOe81CngMYYogn8j0wG5LU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBpOudSN4knvbG/uPLTXREmq+kr6q+N99XrLvJ5fF
 ElPP/1E+XNHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATCS4jeGvhEJDwv1fagpM
 j5g9w8TqbpzYmOFhyvu1OCayOmfNlagyhr+SF+6f/3pL81LH6ghF1oVpYl+Sar6e3Pxj1yPjH+e
 TFWtZAZhuTLk=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

grab_runnable_context() unlinks the chosen context with
__spu_del_from_rq() and returns it after dropping spu_prio->runq_lock.
The runqueue holds no reference of its own — __spu_add_to_rq() only does
a list_add_tail() and __spu_del_from_rq() only a list_del_init() — so the
caller is left with a bare pointer. Both callers dereference it after the
lock is gone: __spu_deactivate() and spusched_tick() call spu_schedule(),
which starts with mutex_lock(&ctx->state_mutex).

The only thing synchronizing the two sides is spu_run_fini() ->
spu_del_from_rq(), which takes runq_lock. Once grab_runnable_context()
has unlinked the context, that call finds ctx->rq already empty and
becomes a no-op, so the owner is free to leave spu_run() and close the
context directory; the resulting put_spu_context() can reach
destroy_spu_context() and kfree() while the scheduler still holds the
pointer. The window spans a full spu_unschedule() -> spu_unbind_context()
SPU context save, and the BUG_ON(!list_empty(&ctx->rq)) in
destroy_spu_context() cannot catch it because list_del_init() has already
emptied ctx->rq.

Fix by taking a reference in grab_runnable_context() while runq_lock is
still held, where a queued context is guaranteed to be alive, and
dropping it in both callers once they are done with it. This matches what
find_victim() already does around its state_mutex trylock.

Fixes: e65c2f6fcebb ("[POWERPC] spufs: decouple spu scheduler from spufs_spu_run (asynchronous scheduling)")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Found by inspection; I have no Cell/PS3 hardware, so this is
compile-tested only.
---
 arch/powerpc/platforms/cell/spufs/sched.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/platforms/cell/spufs/sched.c b/arch/powerpc/platforms/cell/spufs/sched.c
index c52af883e01c..1b50b28cab11 100644
--- a/arch/powerpc/platforms/cell/spufs/sched.c
+++ b/arch/powerpc/platforms/cell/spufs/sched.c
@@ -815,6 +815,9 @@ int spu_activate(struct spu_context *ctx, unsigned long flags)
  *
  * Remove the highest priority context on the runqueue and return it
  * to the caller.  Returns %NULL if no runnable context was found.
+ *
+ * The context is returned with a reference held on behalf of the caller,
+ * which has to drop it using put_spu_context() once it is done with it.
  */
 static struct spu_context *grab_runnable_context(int prio, int node)
 {
@@ -830,6 +833,7 @@ static struct spu_context *grab_runnable_context(int prio, int node)
 			/* XXX(hch): check for affinity here as well */
 			if (__node_allowed(ctx, node)) {
 				__spu_del_from_rq(ctx);
+				get_spu_context(ctx);
 				goto found;
 			}
 		}
@@ -860,6 +864,7 @@ static int __spu_deactivate(struct spu_context *ctx, int force, int max_prio)
 					   interruptible */
 					mutex_lock(&ctx->state_mutex);
 				}
+				put_spu_context(new);
 			}
 		}
 	}
@@ -933,8 +938,10 @@ static noinline void spusched_tick(struct spu_context *ctx)
 out:
 	spu_release(ctx);
 
-	if (new)
+	if (new) {
 		spu_schedule(spu, new);
+		put_spu_context(new);
+	}
 }
 
 /**

-- 
2.51.2

