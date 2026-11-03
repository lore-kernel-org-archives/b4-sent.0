From: Kairui Song <kasong@tencent.com>
Date: Wed, 04 Nov 2026 00:18:17 +0800
Subject: [PATCH v2 4/4] mm/swap: keep the swap-in pressure window open
 across a batch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-swap-fixes-v2-4-204be064be5b@tencent.com>
References: <20261104-swap-fixes-v2-0-204be064be5b@tencent.com>
In-Reply-To: <20261104-swap-fixes-v2-0-204be064be5b@tencent.com>
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Usama Arif <usamaarif642@gmail.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, Yosry Ahmed <yosry@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, Mani Tofigh <mt4022@columbia.edu>, 
 NeilBrown <neil@brown.name>, Christoph Hellwig <hch@lst.de>, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722701; l=6777;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=fSGjBH1fBeJRrxZU6HCQNXNyuo3pc/ORVbu/vvni/eM=;
 b=55yKBwwkhKAzdV8IGn7HpK0NW4JifLakVnRvHacr3WJUwJ5VtjrDcOdX3w+8TtsXvKyfMF0vF
 dSdBt7oTi7RA8h9pLFRz+favTYHexbzETc1L16Yw6N3Iewoy+iVLBfu
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Johannes Weiner <hannes@cmpxchg.org>

For asynchronous block devices, swap reads are batched and submitted later
since commit dda8fb68b590 ("mm/swap: also use struct swap_iocb for block
I/O"), but the caller submits the batch after the pressure window in
swap_read_folio() has closed.  Batching is cheap, the submission is the
part that can block, and that is no longer counted as pressure since then.

Keep the pressure window open across the batch instead: swap_read_folio()
opens it on the first folio, and swap_read_submit() closes it after the
submission, also when the batch ends up with no folio queued.  Each batch
is then billed for its own read.

A single workingset refault marks its whole batch as stalled, which is
fine here: the batch is submitted as a whole, so its submission holds
up that refault too.  Before the batching, a blocking submission was billed
only to the folio that issued it, even when it also delayed the refaults
queued behind it in the same task, so this might be more accurate rather
than less.  Synchronous reads are already one folio per batch after the
previous patch, which keeps their attribution tight.

The same hole has been there for a swap file on a file system that submits
through swap_fs_prepare_rw(), since commit 5169b844b7dd ("mm: submit
multipage reads for SWP_FS_OPS swap-space"), which started batching its
reads and deferring the submission to the caller, so this covers it there
as well.

Fixes: dda8fb68b590 ("mm/swap: also use struct swap_iocb for block I/O")
Fixes: 5169b844b7dd ("mm: submit multipage reads for SWP_FS_OPS swap-space")
Signed-off-by: Johannes Weiner <hannes@cmpxchg.org>
Link: https://lore.kernel.org/linux-mm/auOz00OGB_8dgniC@cmpxchg.org/
[kasong@tencent.com: added commit message and slight tweaks]
Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/swap_ops.h | 10 ++++++
 mm/page_io.c             | 79 ++++++++++++++++++++++++++++++------------------
 2 files changed, 60 insertions(+), 29 deletions(-)

diff --git a/include/linux/swap_ops.h b/include/linux/swap_ops.h
index 57ac6c703f68..d57b95931cd9 100644
--- a/include/linux/swap_ops.h
+++ b/include/linux/swap_ops.h
@@ -17,6 +17,16 @@ struct swap_iocb {
 struct swap_io_ctx {
 	struct swap_iocb	*sio;
 	struct swap_info_struct	*sis;
+
+	/*
+	 * Pressure window: opened by swap_read_folio() on the first folio
+	 * of a batch, closed by swap_read_submit(). Mirrors per-task
+	 * state, so the task that opened it must be the one to close it.
+	 */
+	bool			workingset;
+	bool			in_delayacct;
+	bool			in_thrashing;
+	unsigned long		in_memstall;
 };
 
 /*
diff --git a/mm/page_io.c b/mm/page_io.c
index 83ed0246ebfc..a57cdcf2892d 100644
--- a/mm/page_io.c
+++ b/mm/page_io.c
@@ -350,13 +350,11 @@ static void swap_add_folio(struct swap_io_ctx *ctx, struct folio *folio, int rw)
 	struct swap_info_struct *sis = __swap_entry_to_info(folio->swap);
 	struct swap_iocb *sio = ctx->sio;
 
-	if (sio && !swap_can_merge(ctx, folio, rw)) {
-		if (rw == WRITE)
-			swap_write_submit(ctx);
-		else
-			swap_read_submit(ctx);
-		sio = ctx->sio;
-	}
+	/*
+	 * Callers flush a batch this folio can't join before adding it,
+	 * see swap_read_folio() and __swap_writeout().
+	 */
+	VM_WARN_ON_ONCE(sio && !swap_can_merge(ctx, folio, rw));
 
 	if (!sio) {
 		ctx->sis = sis;
@@ -399,6 +397,14 @@ void __swap_writeout(struct swap_io_ctx *ctx, struct folio *folio)
 
 	folio_start_writeback(folio);
 	folio_unlock(folio);
+
+	/*
+	 * Flush a batch this folio can't join before adding it, as in
+	 * swap_read_folio(). But the write path opens no pressure window,
+	 * so there is nothing to order this against.
+	 */
+	if (ctx->sio && !swap_can_merge(ctx, folio, WRITE))
+		swap_write_submit(ctx);
 	swap_add_folio(ctx, folio, WRITE);
 }
 
@@ -470,31 +476,44 @@ void swap_read_folio(struct swap_io_ctx *ctx, struct folio *folio)
 	struct swap_info_struct *sis = __swap_entry_to_info(folio->swap);
 	bool synchronous = sis->flags & SWP_SYNCHRONOUS_IO;
 	bool workingset = folio_test_workingset(folio);
-	unsigned long pflags;
-	bool in_thrashing;
 
 	VM_BUG_ON_FOLIO(!folio_test_swapcache(folio) && !synchronous, folio);
 	VM_BUG_ON_FOLIO(!folio_test_locked(folio), folio);
 	VM_BUG_ON_FOLIO(folio_test_uptodate(folio), folio);
 
+	/*
+	 * A batch this folio can't join is submitted before the pressure
+	 * window opens, so that each batch is billed for its own read
+	 * rather than for the next folio's lookup and decompression.
+	 */
+	if (ctx->sio && !swap_can_merge(ctx, folio, READ))
+		swap_read_submit(ctx);
+
 	/*
 	 * Count submission time as memory stall and delay. When the device
 	 * is congested, or the submitting cgroup IO-throttled, submission
-	 * can be a significant part of overall IO time.
+	 * can be a significant part of overall IO time. Reads are batched and
+	 * submitted later, so both windows stay open on @ctx, and are closed
+	 * by swap_read_submit() after the submission, also when the batch
+	 * ends up with no folio queued.
 	 */
-	if (workingset) {
-		delayacct_thrashing_start(&in_thrashing);
-		psi_memstall_enter(&pflags);
+	if (!ctx->in_delayacct) {
+		delayacct_swapin_start();
+		ctx->in_delayacct = true;
+	}
+	if (workingset && !ctx->workingset) {
+		delayacct_thrashing_start(&ctx->in_thrashing);
+		psi_memstall_enter(&ctx->in_memstall);
+		ctx->workingset = true;
 	}
-	delayacct_swapin_start();
 
 	if (swap_read_folio_zeromap(folio)) {
 		folio_unlock(folio);
-		goto finish;
+		return;
 	}
 
 	if (zswap_load(folio) != -ENOENT)
-		goto finish;
+		return;
 
 	/* We have to read from slower devices. Increase zswap protection. */
 	zswap_folio_swapin(folio);
@@ -506,13 +525,6 @@ void swap_read_folio(struct swap_io_ctx *ctx, struct folio *folio)
 	 */
 	if (synchronous)
 		swap_read_submit(ctx);
-
-finish:
-	if (workingset) {
-		delayacct_thrashing_end(&in_thrashing);
-		psi_memstall_leave(&pflags);
-	}
-	delayacct_swapin_end();
 }
 
 static void swap_write_end(struct swap_iocb *sio, bool failed)
@@ -725,10 +737,19 @@ void swap_write_submit(struct swap_io_ctx *ctx)
 
 void swap_read_submit(struct swap_io_ctx *ctx)
 {
-	if (!ctx->sio)
-		return;
-	count_vm_events(NRSWPIN, 1);
-	ctx->sis->ops->submit_read(ctx);
-	ctx->sio = NULL;
-	ctx->sis = NULL;
+	if (ctx->sio) {
+		count_vm_events(NRSWPIN, 1);
+		ctx->sis->ops->submit_read(ctx);
+		ctx->sio = NULL;
+		ctx->sis = NULL;
+	}
+	if (ctx->workingset) {
+		delayacct_thrashing_end(&ctx->in_thrashing);
+		psi_memstall_leave(&ctx->in_memstall);
+		ctx->workingset = false;
+	}
+	if (ctx->in_delayacct) {
+		delayacct_swapin_end();
+		ctx->in_delayacct = false;
+	}
 }

-- 
2.56.0

