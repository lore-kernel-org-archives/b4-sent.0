From: Daniel Gomez <da.gomez@samsung.com>
Date: Thu, 12 Sep 2024 22:48:25 +0200
Subject: [PATCH RFC] block: trace: add block alignment information
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240912-add-blkalgn-block-trace-v1-1-335dd6eea557@samsung.com>
X-B4-Tracking: v=1; b=H4sIAJhT42YC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0Mj3cSUFN2knOzEnPQ8IJ2fnK1bUpSYnKprbphqkZhkZm5gkWaoBNR
 dUJSallkBNjlaKcjNWSm2thYARBs1Xm4AAAA=
To: Jens Axboe <axboe@kernel.dk>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, gost.dev@samsung.com, 
 Luis Chamberlain <mcgrof@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Dave Chinner <dchinner@redhat.com>, Daniel Gomez <d@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726174120; l=5497;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=Xp2veQI3BVlkm/PCtIw15ECNVnq9Y9+55YojkuAz500=;
 b=WLQrGUNLHbUJXHbRFP46QEFOMS2Z4ImTorAHY25WhiZ/YcxWGReFb0rF/wFcdAaf669bjnBPg
 +alJp4JfHq8C+XOudogz3NEl7jLrIqQbTM6Pz9czYmlP/FNnAUiBo59
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Report block alignment in terms of LBA and size during block tracing for
block_rq. Calculate alignment only for read/writes where the length is
greater than 0. Otherwise, report 0 to indicate no alignment calculated.

Suggested-by: Dave Chinner <dchinner@redhat.com>
Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
This patch introduces LBA and size alignment information for
the block_rq tracepoints (block_rq{insert, issue, merge} and
block_{io_start, io_done}).

The idea of reporting alignment in a tracepoint was first suggested in
this thread [1] by Dave Chinner. Additionally, an eBPF-based equivalent
tracing tool [2] was developed and used during LBS development, as
mentioned in the patch series [3] and in [1].

With this addition, users can check block alignment directly through the
block layer tracepoints without needing any additional tools.

In case we have a use case, this can be extended to other tracepoints,
such as complete and error.

Another potential enhancement could be the integration of this
information into blktrace. Would that be a feasible option to consider?

[1] https://lore.kernel.org/all/ZdvXAn1Q%2F+QX5sPQ@dread.disaster.area/
[2] blkalgn tool written in eBPF/bcc:
https://github.com/dkruces/bcc/tree/lbs
[3] https://lore.kernel.org/all/20240822135018.1931258-1-kernel@pankajraghav.com/
---
 block/blk-mq.c               | 29 +++++++++++++++++++++++++++++
 include/linux/blk-mq.h       | 11 +++++++++++
 include/linux/blkdev.h       |  6 ++++++
 include/trace/events/block.h |  7 +++++--
 4 files changed, 51 insertions(+), 2 deletions(-)

diff --git a/block/blk-mq.c b/block/blk-mq.c
index 831c5cf5d874..714452bc236b 100644
--- a/block/blk-mq.c
+++ b/block/blk-mq.c
@@ -4920,6 +4920,35 @@ int blk_rq_poll(struct request *rq, struct io_comp_batch *iob,
 }
 EXPORT_SYMBOL_GPL(blk_rq_poll);
 
+u32 __blk_rq_lba_algn(struct request *req)
+{
+	u32 lbs = queue_logical_block_size(req->q);
+	u32 lba_shift = ilog2(lbs);
+	u32 lba = req->__sector >> (lba_shift - SECTOR_SHIFT);
+	u32 len = req->__data_len;
+	u32 algn_len = len;
+	u32 algn_lba = len / lbs;
+	u32 alignment = lbs;
+
+	if (is_power_of_2(len) &&
+	    blk_rq_lba_aligned(len, algn_len, lba, algn_lba))
+		return len;
+
+	algn_len = lbs << 1U;
+	algn_lba = algn_len / lbs;
+
+	while (algn_len < len) {
+		if (!blk_rq_lba_aligned(len, algn_len, lba, algn_lba))
+			break;
+
+		alignment = algn_len;
+		algn_len = algn_len << 1U;
+		algn_lba = algn_len / lbs;
+	}
+
+	return alignment;
+}
+
 unsigned int blk_mq_rq_cpu(struct request *rq)
 {
 	return rq->mq_ctx->cpu;
diff --git a/include/linux/blk-mq.h b/include/linux/blk-mq.h
index 8d304b1d16b1..02959fbd5e28 100644
--- a/include/linux/blk-mq.h
+++ b/include/linux/blk-mq.h
@@ -740,6 +740,17 @@ void blk_mq_free_request(struct request *rq);
 int blk_rq_poll(struct request *rq, struct io_comp_batch *iob,
 		unsigned int poll_flags);
 
+/* The alignment of the block in terms of LBA and size */
+u32 __blk_rq_lba_algn(struct request *req);
+static inline u32 blk_rq_lba_algn(struct request *req)
+{
+	if ((req_op(req) != REQ_OP_WRITE) && (req_op(req) != REQ_OP_READ) &&
+	    !(req->__data_len))
+		return 0;
+
+	return __blk_rq_lba_algn(req);
+}
+
 bool blk_mq_queue_inflight(struct request_queue *q);
 
 enum {
diff --git a/include/linux/blkdev.h b/include/linux/blkdev.h
index bf1aa951fda2..28557987daa8 100644
--- a/include/linux/blkdev.h
+++ b/include/linux/blkdev.h
@@ -1433,6 +1433,12 @@ static inline int blk_rq_aligned(struct request_queue *q, unsigned long addr,
 	return !(addr & alignment) && !(len & alignment);
 }
 
+static inline bool blk_rq_lba_aligned(u32 len, u32 algn_len, u32 lba,
+				      u32 algn_lba)
+{
+	return !(len % algn_len) && !(lba % algn_lba);
+}
+
 /* assumes size > 256 */
 static inline unsigned int blksize_bits(unsigned int size)
 {
diff --git a/include/trace/events/block.h b/include/trace/events/block.h
index 1527d5d45e01..ba3764214dc7 100644
--- a/include/trace/events/block.h
+++ b/include/trace/events/block.h
@@ -202,6 +202,7 @@ DECLARE_EVENT_CLASS(block_rq,
 		__array(  char,		rwbs,	RWBS_LEN	)
 		__array(  char,         comm,   TASK_COMM_LEN   )
 		__dynamic_array( char,	cmd,	1		)
+		__field(  unsigned int,	algn			)
 	),
 
 	TP_fast_assign(
@@ -210,20 +211,22 @@ DECLARE_EVENT_CLASS(block_rq,
 		__entry->nr_sector = blk_rq_trace_nr_sectors(rq);
 		__entry->bytes     = blk_rq_bytes(rq);
 		__entry->ioprio	   = rq->ioprio;
+		__entry->algn      = blk_rq_lba_algn(rq);
 
 		blk_fill_rwbs(__entry->rwbs, rq->cmd_flags);
 		__get_str(cmd)[0] = '\0';
 		memcpy(__entry->comm, current->comm, TASK_COMM_LEN);
 	),
 
-	TP_printk("%d,%d %s %u (%s) %llu + %u %s,%u,%u [%s]",
+	TP_printk("%d,%d %s %u (%s) %llu + %u %s,%u,%u |%u| [%s]",
 		  MAJOR(__entry->dev), MINOR(__entry->dev),
 		  __entry->rwbs, __entry->bytes, __get_str(cmd),
 		  (unsigned long long)__entry->sector, __entry->nr_sector,
 		  __print_symbolic(IOPRIO_PRIO_CLASS(__entry->ioprio),
 				   IOPRIO_CLASS_STRINGS),
 		  IOPRIO_PRIO_HINT(__entry->ioprio),
-		  IOPRIO_PRIO_LEVEL(__entry->ioprio), __entry->comm)
+		  IOPRIO_PRIO_LEVEL(__entry->ioprio), __entry->algn,
+		  __entry->comm)
 );
 
 /**

---
base-commit: 57f962b956f1d116cd64d5c406776c4975de549d
change-id: 20240912-add-blkalgn-block-trace-71e8ab6708f1

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

