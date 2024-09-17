From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 17 Sep 2024 17:22:18 +0200
Subject: [PATCH RFC] blktrace: add i/o alignment information
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240917-blktrace-algn-v1-1-9fb54b7b1dfa@samsung.com>
X-B4-Tracking: v=1; b=H4sIAKme6WYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDS0Mz3aSc7JKixORU3cSc9DzdRENDYyMDY1NjQwsjJaCegqLUtMwKsHn
 RSkFuzkqxtbUAq9kXRGQAAAA=
To: Jens Axboe <axboe@kernel.dk>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, gost.dev@samsung.com, 
 John Garry <john.g.garry@oracle.com>, Dave Chinner <dchinner@redhat.com>, 
 Luis Chamberlain <mcgrof@kernel.org>, Pankaj Raghav <p.raghav@samsung.com>, 
 Dan Helmick <dan.helmick@samsung.com>, Daniel Gomez <d@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726586542; l=6584;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=JygrMCTMhPqX/bAPRMl20ITyAtI+tYOaIShANk2aGlU=;
 b=8mwlKU1v1feiAFYqL5Z0fOTBZ/cJLiS6UtnWxVXzTXO9WPZQ6SrTPGrgd5Ar2yXHEumZtQMHM
 EeF05YyiVFRA2JQc2Iisq0RLzDK7A4smn7CIZ22sYd4U3gRUvnOjZiL
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch introduces max I/O alignment boundaries in terms of LBA and
size in blktrace for issued I/Os.

Tracing alignment information is important for high-capacity and QLC
SSDs with Indirection Units greater than 4 KiB. These devices are still
4 KiB in Logical Block Size (LBS) but because they work at higher IUs,
unaligned writes to the IU boundaries can imply in a read-modify-write
(RMW).

This patch enables blktrace to report alignment details via new
alignment parameter, which will be calculated during I/O tracing.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
This patch introduces support for tracing maximum I/O alignment
boundaries in terms of Logical Block Addressing (LBA) and size within
blktrace for issued I/Os.

Note: the term alignment has been previously discussed here [1], where
it was suggested to use "largest block size granularity". In this RFC,
alignment term is kept, though further suggestions for an appropriate
term are welcomed.

[1] https://lore.kernel.org/all/a7f9079f-6f47-4a47-a327-98497bd33dfe@oracle.com

Tracing alignment information is important for high-capacity and QLC
SSDs with Indirection Units greater than 4 KiB. These devices are still
4 KiB in Logical Block Size (LBS) but because they work at higher IUs,
unaligned writes to the IU boundaries can imply in a read-modify-write
(RMW).

More information about the motivation can be found in the first LBS
patch series [2].

[2] Subject: [RFC 00/23] Enable block size > page size in XFS
https://lore.kernel.org/lkml/20230915183848.1018717-1-kernel@pankajraghav.com/

Additionally, Dan Helmick's talk [3] provides further context on the
importance of I/O granularity and alignment, specifically in the context
of NVMe.

[3] SDC2022 – Optimal Performance Parameters for NVMe SSDs

The graph below is a representation of the device IU vs what is
considered here the I/O block alignment.

    |--- IU Boundaries ----|      |-PS-|
a)  [====][====][====][====][····][····][····]--
    |                      |
b)  [····][====][====][====][====][····][····]--
    |                      |
c)  [····][····][====][====][····][····][····]--
    |                      |
LBA 0                      4

    Key:
    [====] = I/O Block
    [····] = Memory in Page Size (PS) chunks
    PS: System base Page Size (e.g. x86_64 is 4 KiB)

a) I/O matches IU boundaries (LBA and block size). I/O is aligned to
IU boundaries.
b) The size of the I/O matches the IU size but the I/O is not aligned to
the IU boundaries. I/O is unaligned.
c) I/O does not match in either size or LBA. I/O is unaligned.

This patch enables blktrace to report alignment details via new
alignment parameter, which will be calculated during I/O tracing. For
the example above, the following values would be reported:

a) |16384|: I/O aligned to 16 KiB boundaries.
b) |4096|:  I/O aligned to 4 KiB boundaries.
c) |8192|:  I/O aligned to 8 KiB boundaries.

Finally, this patch requires some minor changes [4] in the blktrace
tool. If this moves forward, the changes will be submitted accordingly.

[4] https://github.com/dkruces/blktrace/tree/algn
---
 include/linux/blktrace_api.h      |  2 ++
 include/uapi/linux/blktrace_api.h |  1 +
 kernel/trace/blktrace.c           | 38 ++++++++++++++++++++++++++++++++++++++
 3 files changed, 41 insertions(+)

diff --git a/include/linux/blktrace_api.h b/include/linux/blktrace_api.h
index 122c62e561fc..17f1a21ffb5a 100644
--- a/include/linux/blktrace_api.h
+++ b/include/linux/blktrace_api.h
@@ -26,6 +26,8 @@ struct blk_trace {
 	struct dentry *dir;
 	struct list_head running_list;
 	atomic_t dropped;
+	u32 lbs;
+	u8 lba_shift;
 };
 
 extern int blk_trace_ioctl(struct block_device *, unsigned, char __user *);
diff --git a/include/uapi/linux/blktrace_api.h b/include/uapi/linux/blktrace_api.h
index 690621b610e5..d6df0c10ece1 100644
--- a/include/uapi/linux/blktrace_api.h
+++ b/include/uapi/linux/blktrace_api.h
@@ -110,6 +110,7 @@ struct blk_io_trace {
 	__u32 cpu;		/* on what cpu did it happen */
 	__u16 error;		/* completion error */
 	__u16 pdu_len;		/* length of data after this trace */
+	__u32 alignment;	/* i/o alignment boundaries */
 	/* cgroup id will be stored here if exists */
 };
 
diff --git a/kernel/trace/blktrace.c b/kernel/trace/blktrace.c
index 8fd292d34d89..8330455458b8 100644
--- a/kernel/trace/blktrace.c
+++ b/kernel/trace/blktrace.c
@@ -208,6 +208,39 @@ static const u32 ddir_act[2] = { BLK_TC_ACT(BLK_TC_READ),
 #define MASK_TC_BIT(rw, __name) ((__force u32)(rw & REQ_ ## __name) <<	\
 	  (ilog2(BLK_TC_ ## __name) + BLK_TC_SHIFT - __REQ_ ## __name))
 
+static inline bool blk_trace_lba_aligned(u32 len, u32 algn_len, u64 lba,
+				      u32 algn_lba)
+{
+	return !(len % algn_len) && !(lba % algn_lba);
+}
+
+static inline u32 blk_trace_align(struct blk_trace *bt, u64 sector,
+					u32 len)
+{
+	u64 lba = sector >> (bt->lba_shift - SECTOR_SHIFT);
+	u32 align_len = len;
+	u32 align_lba = align_len / bt->lbs;
+	u32 alignment = bt->lbs;
+
+	if (is_power_of_2(len) &&
+	    blk_trace_lba_aligned(len, align_len, lba, align_lba))
+		return len;
+
+	align_len = bt->lbs << 1UL;
+	align_lba = align_len / bt->lbs;
+
+	while (align_len < len) {
+		if (!blk_trace_lba_aligned(len, align_len, lba, align_lba))
+			break;
+
+		alignment = align_len;
+		align_len = align_len << 1UL;
+		align_lba = align_len / bt->lbs;
+	}
+
+	return alignment;
+}
+
 /*
  * The worker for the various blk_add_trace*() types. Fills out a
  * blk_io_trace structure and places it in a per-cpu subbuffer.
@@ -296,6 +329,9 @@ static void __blk_add_trace(struct blk_trace *bt, sector_t sector, int bytes,
 		t->device = bt->dev;
 		t->error = error;
 		t->pdu_len = pdu_len + cgid_len;
+		if (((what & 0xffff) & ~__BLK_TA_CGROUP) == __BLK_TA_ISSUE)
+			t->alignment =
+				blk_trace_align(bt, sector, bytes);
 
 		if (cgid_len)
 			memcpy((void *)t + sizeof(*t), &cgid, cgid_len);
@@ -597,6 +633,8 @@ static int do_blk_trace_setup(struct request_queue *q, char *name, dev_t dev,
 		bt->act_mask = (u16) -1;
 
 	blk_trace_setup_lba(bt, bdev);
+	bt->lbs = queue_logical_block_size(q);
+	bt->lba_shift = ilog2(bt->lbs);
 
 	/* overwrite with user settings */
 	if (buts->start_lba)

---
base-commit: 4f3e012d4cfd1d9bf837870c961f462ca9f23ebe
change-id: 20240916-blktrace-algn-a11320353182

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

