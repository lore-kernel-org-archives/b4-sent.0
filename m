From: Leno Hou <lenohou@gmail.com>
Date: Wed, 28 Oct 2026 00:33:55 +0800
Subject: [PATCH Resend 6.12] mm: vmscan: fix dirty folios throttling on
 cgroup v1 for MGLRU
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-fix-mglru-v6-12-v1-1-e44f4f97ca67@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBBFr9LM2jHtEBr0GG6NC2gHGAPVdISYE
 O5u1eXL/+9toJyFFc5mg8yrqDxSAXcwEMY2DYwSCwNZ8s5Sg728cR6mvODq0RHWpz7UsQttVVk
 o1jNzufyKV7iwcorGHx3B7T/q0t05vL5N2PcPW/IE+4AAAAA=
X-Change-ID: 20261028-fix-mglru-v6-12-59fc5dbca330
To: stable@vger.kernel.org
Cc: Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Barry Song <baohua@kernel.org>, Kairui Song <kasong@tencent.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, 
 David Hildenbrand <david@kernel.org>, 
 "Lorenzo Stoakes (Oracle)" <ljs@kernel.org>, 
 Michal Hocko <mhocko@kernel.org>, Qi Zheng <zhengqi.arch@bytedance.com>, 
 Wei Xu <weixugc@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Leno Hou <lenohou@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793118841; l=3366;
 i=lenohou@gmail.com; s=20260311; h=from:subject:message-id;
 bh=w5XO7uxDe6BmXywiUuWRH0ePynDG5fOBKE7mkiiXvK0=;
 b=J9F6rHPhSJslAtxXDC/CJCbqmroGQWPBOdIBdHQAaS4dtdfRWIOt4gh0xoTGECyvBQpLQ9zTn
 Tzx1cS9YnbwDLrj2hFWqYrR8325U6AFLVPg2Mk+X1S8WDM2bi77KCV3
X-Developer-Key: i=lenohou@gmail.com; a=ed25519;
 pk=8AVHXYurzu1kOGjk9rwvxovwSCynBkv2QAcOvSIe1rw=
X-Endpoint-Received: by B4 Relay for lenohou@gmail.com/20260311 with auth_id=674
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Baolin Wang <baolin.wang@linux.alibaba.com>

The balance_dirty_pages() won't do the dirty folios throttling on
cgroupv1.  See commit 9badce000e2c ("cgroup, writeback: don't enable
cgroup writeback on traditional hierarchies").

Moreover, after commit 6b0dfabb3555 ("fs: Remove aops->writepage"), we no
longer attempt to write back filesystem folios through reclaim.

On large memory systems, the flusher may not be able to write back quickly
enough.  Consequently, MGLRU will encounter many folios that are already
under writeback.  Since we cannot reclaim these dirty folios, the system
may run out of memory and trigger the OOM killer.

Hence, for cgroup v1, let's throttle reclaim after waking up the flusher,
which is similar to commit 81a70c21d917 ("mm/cgroup/reclaim: fix dirty
pages throttling on cgroup v1"), to avoid unnecessary OOM.

The following test program can easily reproduce the OOM issue.  With this
patch applied, the test passes successfully.

$mkdir /sys/fs/cgroup/memory/test
$echo 256M > /sys/fs/cgroup/memory/test/memory.limit_in_bytes
$echo $$ > /sys/fs/cgroup/memory/test/cgroup.procs
$dd if=/dev/zero of=/mnt/data.bin bs=1M count=800

Link: https://lore.kernel.org/3445af0f09e8ca945492e052e82594f8c4f2e2f6.1774606060.git.baolin.wang@linux.alibaba.com
Fixes: ac35a4902374 ("mm: multi-gen LRU: minimal implementation")
Signed-off-by: Baolin Wang <baolin.wang@linux.alibaba.com>
Reviewed-by: Barry Song <baohua@kernel.org>
Reviewed-by: Kairui Song <kasong@tencent.com>
Acked-by: Johannes Weiner <hannes@cmpxchg.org>
Acked-by: Shakeel Butt <shakeel.butt@linux.dev>
Cc: Axel Rasmussen <axelrasmussen@google.com>
Cc: David Hildenbrand <david@kernel.org>
Cc: Lorenzo Stoakes (Oracle) <ljs@kernel.org>
Cc: Michal Hocko <mhocko@kernel.org>
Cc: Qi Zheng <zhengqi.arch@bytedance.com>
Cc: Wei Xu <weixugc@google.com>
Cc: Yuanchu Xie <yuanchu@google.com>
Signed-off-by: Andrew Morton <akpm@linux-foundation.org>
Signed-off-by: Leno Hou <lenohou@gmail.com>
---
 mm/vmscan.c | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/mm/vmscan.c b/mm/vmscan.c
index f9b5fbd072db..074e403ffd14 100644
--- a/mm/vmscan.c
+++ b/mm/vmscan.c
@@ -4809,9 +4809,24 @@ static bool try_to_shrink_lruvec(struct lruvec *lruvec, struct scan_control *sc)
 	 * If too many file cache in the coldest generation can't be evicted
 	 * due to being dirty, wake up the flusher.
 	 */
-	if (sc->nr.unqueued_dirty && sc->nr.unqueued_dirty == sc->nr.file_taken)
+	if (sc->nr.unqueued_dirty && sc->nr.unqueued_dirty == sc->nr.file_taken) {
+		struct pglist_data *pgdat = lruvec_pgdat(lruvec);
+
 		wakeup_flusher_threads(WB_REASON_VMSCAN);
 
+		/*
+		 * For cgroupv1 dirty throttling is achieved by waking up
+		 * the kernel flusher here and later waiting on folios
+		 * which are in writeback to finish (see shrink_folio_list()).
+		 *
+		 * Flusher may not be able to issue writeback quickly
+		 * enough for cgroupv1 writeback throttling to work
+		 * on a large system.
+		 */
+		if (!writeback_throttling_sane(sc))
+			reclaim_throttle(pgdat, VMSCAN_THROTTLE_WRITEBACK);
+	}
+
 	/* whether this lruvec should be rotated */
 	return nr_to_scan < 0;
 }

---
base-commit: 85d82e0d7c2dfd3e75d34f35b7ebbf41f45c9c4e
change-id: 20261028-fix-mglru-v6-12-59fc5dbca330

Best regards,
--  
Leno Hou <lenohou@gmail.com>

