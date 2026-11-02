From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Mon, 02 Nov 2026 13:03:56 +0000
Subject: [PATCH v4] hugetlbfs: move hugetlbfs_free_inode tracepoint to
 ->destroy_inode()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-b4-hugetlbfs-trace-v4-1-72371825bb5e@gmail.com>
X-B4-Tracking: v=1; b=H4sIADuK6GoC/33Nyw7CIBCF4VdpWIuZKfSiK9/DuAA6tCS9GKhE0
 /Tdpd3owrj8TzLfLCyQdxTYOVuYp+iCm8YU8pAx06mxJe6a1CyHvEQQyLXk3aOludc28NkrQ1x
 I1ELUSheVZunw7sm6545eb6k7F+bJv/YfEbf1LxeRI5dk6gZyJcCYSzso1x/NNLCNi+JDIPwmR
 CKgQF1haeUJ7Dexrusbr4LkXfcAAAA=
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>
Cc: linux-mm@kvack.org, Andrew Morton <akpm@linux-foundation.org>, 
 Hongbo Li <lihongbo22@huawei.com>, linux-fsdevel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 syzbot+91e1fc35f51774c479b2@syzkaller.appspotmail.com, 
 stable@vger.kernel.org, Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793624635; l=4611;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=KamqvAmHDg6o0N+fTVEMDXuwIqsclHfnbjLf5BnFAeI=;
 b=6KI19Vg+bAxiED0JqPw6cBQwYlbwj43osrwBDrFjsM/YfY07REwyxhqBR4n5b2oqe015nw9Cy
 T6PsmCPy7HUCpwFtBSgbCWDiiT3HPmtT6UUve/QpoSglPtcB7gNcinv
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

Since the event no longer fires from ->free_inode(), rename it to
hugetlbfs_destroy_inode so that its name matches where it is emitted,
as suggested by David and Muchun.

Found by syzbot; analysed and tested with the syzbot C reproducer on an
arm64 KASAN kernel.

Fixes: 014ad7c42a69 ("hugetlbfs: use tracepoints in hugetlbfs functions.")
Reported-by: syzbot+91e1fc35f51774c479b2@syzkaller.appspotmail.com
Closes: https://lore.kernel.org/all/6ae27525.5451848c.f7707.0001.GAE@google.com/
Suggested-by: David Hildenbrand <david@kernel.org>
Suggested-by: Muchun Song <muchun.song@linux.dev>
Cc: stable@vger.kernel.org
Reviewed-by: Muchun Song <muchun.song@linux.dev>
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Changes in v4:
- Drop the comment in hugetlbfs_destroy_inode(), the new event name
  makes it clear where it fires (Muchun).
- Add Muchun's Reviewed-by.

Andrew, this replaces
hugetlbfs-move-hugetlbfs_free_inode-tracepoint-to-destroy_inode.patch in
mm-hotfixes-unstable; the only code change from v3 is the removed
comment.

Changes in v3:
- Rename the tracepoint to hugetlbfs_destroy_inode in the same patch, so
  its name matches where it now fires (David, Muchun).

Tested with the syzbot C reproducer on an arm64 KASAN kernel with the
renamed event enabled: no splat in 3 of 3 boots, and
hugetlbfs_destroy_inode events are recorded.

Tool-use note: the analysis and testing were done with help from an
LLM-based assistant; I reviewed the change and ran the tests myself.

v3: https://lore.kernel.org/all/20261101-b4-hugetlbfs-trace-v3-1-051b716f490f@gmail.com/
---
 fs/hugetlbfs/inode.c             | 2 +-
 include/trace/events/hugetlbfs.h | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/fs/hugetlbfs/inode.c b/fs/hugetlbfs/inode.c
index 01c4d6f44ebe..f0be8edb3517 100644
--- a/fs/hugetlbfs/inode.c
+++ b/fs/hugetlbfs/inode.c
@@ -1179,12 +1179,12 @@ static struct inode *hugetlbfs_alloc_inode(struct super_block *sb)
 
 static void hugetlbfs_free_inode(struct inode *inode)
 {
-	trace_hugetlbfs_free_inode(inode);
 	kmem_cache_free(hugetlbfs_inode_cachep, HUGETLBFS_I(inode));
 }
 
 static void hugetlbfs_destroy_inode(struct inode *inode)
 {
+	trace_hugetlbfs_destroy_inode(inode);
 	hugetlbfs_inc_free_inodes(HUGETLBFS_SB(inode->i_sb));
 }
 
diff --git a/include/trace/events/hugetlbfs.h b/include/trace/events/hugetlbfs.h
index 8ba72c1d4f4d..a7932e0db0f8 100644
--- a/include/trace/events/hugetlbfs.h
+++ b/include/trace/events/hugetlbfs.h
@@ -72,7 +72,7 @@ DEFINE_EVENT(hugetlbfs__inode, hugetlbfs_evict_inode,
 	TP_ARGS(inode)
 );
 
-DEFINE_EVENT(hugetlbfs__inode, hugetlbfs_free_inode,
+DEFINE_EVENT(hugetlbfs__inode, hugetlbfs_destroy_inode,
 
 	TP_PROTO(struct inode *inode),
 

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261031-b4-hugetlbfs-trace-341b338ab57b

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

