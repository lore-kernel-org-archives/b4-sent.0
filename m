From: Nicholas Velten <nicholasfvelten@gmail.com>
Date: Tue, 20 Oct 2026 13:32:21 -0300
Subject: [PATCH] jfs: reject xtree pages whose BT_ROOT flag does not match
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-jfs-xtroot-check-v1-1-4877a93be93e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJSX12oC/yXMwQqDMAyA4VeRnBdog465Vxk7rDHOOLCjqUMQ3
 91Oj9/h/1cwSSoG92qFJD81jVOBv1TAw2t6C2pXDOTo6h05HHvDJacYM/Ig/EEhJt+0dXsLDkr
 2TdLrciwfz9M2h1E4/z+wbTsnAcg4dAAAAA==
X-Change-ID: 20261020-jfs-xtroot-check-e2c2159498b0
To: Dave Kleikamp <shaggy@kernel.org>
Cc: jfs-discussion@lists.sourceforge.net, linux-kernel@vger.kernel.org, 
 syzbot+43706fd1eb4c8dccdfe6@syzkaller.appspotmail.com, 
 Nicholas Velten <nicholasfvelten@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792513940; l=3454;
 i=nicholasfvelten@gmail.com; s=20261014; h=from:subject:message-id;
 bh=A7u2AT1HyEAjeanbXyIXcu220bBEFFEl+WoLfKmLCZM=;
 b=TBYSxYzsdnCNRnV/Pwis8URFHiMRnNNEJIrFwZtSqbRWs5r3TcREn4ijHcOX0y/n7mMDHVDNZ
 CsaxPskNY8lC2b2NybXVAQhWwSxyRY3R3fqLhf3Nyym4jdANwLs49Tp
X-Developer-Key: i=nicholasfvelten@gmail.com; a=ed25519;
 pk=WVTZgm6yXQ+XrhULAObg4lwcHPhhxAXrAY+YY6svXzg=
X-Endpoint-Received: by B4 Relay for nicholasfvelten@gmail.com/20261014 with auth_id=1173
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot reports a crash in release_metapage() when an inode from a
corrupted JFS image is evicted:

  Oops: stack segment: 0000 [#1] SMP KASAN PTI
  RIP: 0010:release_metapage+0x9e/0xab0 fs/jfs/jfs_metapage.c:870
  Call Trace:
   xtTruncate+0xecd/0x2f20 fs/jfs/jfs_xtree.c
   jfs_free_zero_link+0x35b/0x4c0 fs/jfs/namei.c:759
   jfs_evict_inode+0x363/0x440 fs/jfs/inode.c:159
   evict+0x61e/0xb10 fs/inode.c:837
   ...

The xtree root of a regular file is embedded in the inode, and
xt_getpage() returns it for bn == 0 with a pseudo metapage. Callers
such as xtTruncate() and xtTruncate_pmap() then decide whether they
hold the root by testing the on-disk p->header.flag & BT_ROOT. In the
reproducer's image a regular file has an xtroot flag of 0 instead of
DXD_INDEX | BT_ROOT | BT_LEAF, so xtTruncate() takes the non-root path
for the embedded root and releases the pseudo metapage as if it were
a real page, dereferencing an invalid folio.

xt_getpage() already validates nextindex and maxentry for both the
root and regular pages. Also reject a page whose BT_ROOT flag does not
match where it came from: the root (bn == 0) must have it set and any
other page must not. Healthy trees always satisfy this, since
xtInitRoot() sets BT_ROOT and xtSplitRoot()/xtSplitPage() never copy it
to a child page.

Tested in a KASAN guest: the syzbot reproducer crashes the unpatched
kernel. With this patch the bad page is reported as
"xt_getpage: xtree page corrupt" and the reproducer runs to completion.
On a clean mkfs.jfs image, writing 40 separate extents to one file
(forcing a root split), remounting, truncating, renaming over an
existing file and remounting again still works, with the data
unchanged.

Fixes: 1da177e4c3f4 ("Linux-2.6.12-rc2")
Reported-by: syzbot+43706fd1eb4c8dccdfe6@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=43706fd1eb4c8dccdfe6
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Nicholas Velten <nicholasfvelten@gmail.com>
---
syzbot sent an AI-generated RFC for this bug in May
(https://lore.kernel.org/all/938f325a-46c6-4ade-8a21-b3271963810c@mail.kernel.org/),
which also bundled unrelated txnmgr/logmgr changes and got no replies.
This patch only addresses the xtree root confusion, by validating the
flag in xt_getpage() next to the existing nextindex/maxentry checks.

The reproducer is syzbot's C repro, run in a virtme-ng KASAN guest built
from next-20261009.

Not tested: architectures other than x86_64, and jfs_fsck on the
rejected image.
---
 fs/jfs/jfs_xtree.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/jfs/jfs_xtree.c b/fs/jfs/jfs_xtree.c
index 28c3cf960..3a5f9d035 100644
--- a/fs/jfs/jfs_xtree.c
+++ b/fs/jfs/jfs_xtree.c
@@ -121,7 +121,8 @@ static inline xtpage_t *xt_getpage(struct inode *ip, s64 bn, struct metapage **m
 		(le16_to_cpu(p->header.nextindex) >
 			le16_to_cpu(p->header.maxentry)) ||
 		(le16_to_cpu(p->header.maxentry) >
-			((bn == 0) ? XTROOTMAXSLOT : PSIZE >> L2XTSLOTSIZE))) {
+			((bn == 0) ? XTROOTMAXSLOT : PSIZE >> L2XTSLOTSIZE)) ||
+		((bn == 0) != !!(p->header.flag & BT_ROOT))) {
 		jfs_error(ip->i_sb, "xt_getpage: xtree page corrupt\n");
 		BT_PUTPAGE(*mp);
 		*mp = NULL;

---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261020-jfs-xtroot-check-e2c2159498b0

Best regards,
--  
Nicholas Velten <nicholasfvelten@gmail.com>

