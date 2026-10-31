From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sat, 31 Oct 2026 16:06:02 +0000
Subject: [PATCH] hugetlbfs: emit hugetlbfs_free_inode from
 ->destroy_inode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b4-hugetlbfs-trace-v1-1-4ec8d02a30cc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOkR5moC/x3MSwqAMAwA0atI1gasrR+8irhoNGpAVNoqQvHuF
 pdvMRPBsxP20GURHN/i5dgTVJ7BuNp9YZQpGcqirFWhFZLB9Vo4bDR7DM6OjNoo0rq1VDUEKTw
 dz/L803543w8rE6aMZAAAAA==
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>
Cc: linux-mm@kvack.org, Andrew Morton <akpm@linux-foundation.org>, 
 Hongbo Li <lihongbo22@huawei.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+91e1fc35f51774c479b2@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793462761; l=3980;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=CimqNwtPRA6nxILdhyc+0Xn4gqEkC2G7lMQ2JLmnouo=;
 b=yjuS2uTzQ9DedPHbuDm6WP0AuJe1WwYvU3AL0T/UCB287QqTTK/wXTcArMWRSVnwIEyUeH8rb
 qV6kSiKFMPyCX4BeVFMi8oIBqxxY16vKLP3MQWAKCoduXNPhXggr+3X
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

hugetlbfs_free_inode() calls trace_hugetlbfs_free_inode(), and the
hugetlbfs__inode event class records inode->i_sb->s_dev.  ->free_inode()
runs from an RCU callback (destroy_inode() queues i_callback() with
call_rcu()), and Documentation/filesystems/porting.rst says that this
callback "is *NOT* ordered wrt superblock destruction; as the matter of
fact, the superblock and all associated structures might be already
gone".  put_super() frees the superblock with call_rcu() followed by a
workqueue item (destroy_super_rcu() -> destroy_super_work()).  syzbot
hit this with the event enabled:

  BUG: KASAN: slab-use-after-free in trace_event_raw_event_hugetlbfs__inode+0x45b/0x4c0 include/trace/events/hugetlbfs.h:36
  Read of size 4 at addr ffff888038850010 by task syz-executor952/6134
   hugetlbfs_free_inode+0x15e/0x1f0 fs/hugetlbfs/inode.c:1182
   i_callback+0x46/0x80 fs/inode.c:317
   rcu_do_batch kernel/rcu/tree.c:2650 [inline]
   rcu_core+0x5f0/0x1220 kernel/rcu/tree.c:2919
  Allocated by task 6134:
   alloc_super fs/super.c:326 [inline]
   sget_fc+0x1ba/0x1f60 fs/super.c:874
   hugetlbfs_get_tree+0x1e7/0x2b0 fs/hugetlbfs/inode.c:1431
  Freed by task 855:
   kfree+0x22b/0x6d0 mm/slub.c:6923
   process_one_work+0xac7/0x1b10 kernel/workqueue.c:3495

Emit the event from hugetlbfs_destroy_inode() instead.  destroy_inode()
calls ->destroy_inode() synchronously, before it queues the RCU
callback, while the superblock is still alive; hugetlbfs_destroy_inode()
already dereferences inode->i_sb there.  ->free_inode() is left with
only the kmem_cache_free().

Fixes: 014ad7c42a69 ("hugetlbfs: use tracepoints in hugetlbfs functions.")
Reported-by: syzbot+91e1fc35f51774c479b2@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/all/6ae27525.5451848c.f7707.0001.GAE@google.com/
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Resend: my mail provider blocked the original submission to the lists
on 2026-10-29, so only the direct recipients got it. No change to the
patch, except dropping a deprecated Assisted-by trailer.

David asked whether the tracepoint should be renamed now that it no
longer fires from ->free_inode(). I'd keep this patch as is, since it
is tagged for stable and the event name is visible in tracefs
(events/hugetlbfs/hugetlbfs_free_inode); renaming it in stable kernels
would break existing tracing setups just to fix the use-after-free. I
can send a follow-up for mm-unstable that renames it to
hugetlbfs_destroy_inode, next to hugetlbfs_evict_inode, or fold the
rename into a v2 if preferred.

Tested with the syzbot C reproducer on a KASAN kernel with the event
enabled: the use-after-free reproduced in 3 of 3 boots without the
patch and in none of 12 runs with it, and the event is still emitted.

Tool-use note: the analysis and testing were done with help from an
LLM-based assistant; I reviewed the change and ran the tests myself.
---
 fs/hugetlbfs/inode.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/fs/hugetlbfs/inode.c b/fs/hugetlbfs/inode.c
index 01c4d6f44..5bd348288 100644
--- a/fs/hugetlbfs/inode.c
+++ b/fs/hugetlbfs/inode.c
@@ -1179,12 +1179,16 @@ static struct inode *hugetlbfs_alloc_inode(struct super_block *sb)
 
 static void hugetlbfs_free_inode(struct inode *inode)
 {
-	trace_hugetlbfs_free_inode(inode);
 	kmem_cache_free(hugetlbfs_inode_cachep, HUGETLBFS_I(inode));
 }
 
 static void hugetlbfs_destroy_inode(struct inode *inode)
 {
+	/*
+	 * Not in ->free_inode(): that runs from an RCU callback, when the
+	 * superblock the event reads may already be freed.
+	 */
+	trace_hugetlbfs_free_inode(inode);
 	hugetlbfs_inc_free_inodes(HUGETLBFS_SB(inode->i_sb));
 }
 

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261031-b4-hugetlbfs-trace-341b338ab57b

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

