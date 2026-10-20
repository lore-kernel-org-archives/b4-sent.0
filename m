From: Nicholas Velten <nicholasfvelten@gmail.com>
Date: Tue, 20 Oct 2026 10:35:34 -0300
Subject: [PATCH] jfs: reject slot 0 in dtroot stbl entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-jfs-dtroot-stbl-slot0-v1-1-3a62946f24b7@gmail.com>
X-B4-Tracking: v=1; b=H4sIACVu12oC/yXMTQ6CQAxA4auQrm1SxsiPVzEuBuhACWHMtBoSw
 t0Zdfkt3ttBOQkr3IsdEn9EJa4Z5aWAfvLryChDNjhyVUmOcA6Kg6UYDdW6BXWJRngjbhtfB19
 fG8jtK3GQ7fd9PP/Wdzdzb98ZHMcJ91Ib73kAAAA=
X-Change-ID: 20261020-jfs-dtroot-stbl-slot0-50e98a7fa738
To: Dave Kleikamp <shaggy@kernel.org>
Cc: Yun Zhou <yun.zhou@windriver.com>, jfs-discussion@lists.sourceforge.net, 
 linux-kernel@vger.kernel.org, 
 syzbot+b547ffac63b636628299@syzkaller.appspotmail.com, 
 Nicholas Velten <nicholasfvelten@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792503333; l=4028;
 i=nicholasfvelten@gmail.com; s=20261014; h=from:subject:message-id;
 bh=bzSwpEFa7DNnn/drp2rNoMNn8KIb/+T/IrxFdCNdEvY=;
 b=dzwy0d52wRVj3KPDLcijhVgqbA9dvAd30EtSWzaOULuU1nhvKk3oqJfUkMsYcgLz3wA7ecEQ0
 GTXfAkOIWxGCz+VSydRvs+FTCLPL0WDRv6E2uEKAnX2LJlGYAHMSq2j
X-Developer-Key: i=nicholasfvelten@gmail.com; a=ed25519;
 pk=WVTZgm6yXQ+XrhULAObg4lwcHPhhxAXrAY+YY6svXzg=
X-Endpoint-Received: by B4 Relay for nicholasfvelten@gmail.com/20261014 with auth_id=1173
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

syzbot reports a general protection fault in bpf_inode_storage_free()
when unmounting a corrupted JFS image:

  Oops: general protection fault, probably for non-canonical address 0xdffffc018ef8da81
  KASAN: probably user-memory-access in range [0x0000000c77c6d408-0x0000000c77c6d40f]
  RIP: 0010:bpf_inode_storage_free+0x1f4/0x5c0 kernel/bpf/bpf_inode_storage.c:67
  Call Trace:
   security_inode_free+0xdc/0x180 security/security.c:1289
   __destroy_inode+0x2a1/0x630 fs/inode.c:363
   destroy_inode fs/inode.c:386 [inline]
   evict+0x8d4/0xb50 fs/inode.c:847
   ...

The inode's i_security pointer has been overwritten by JFS itself.
The root directory of the image has a dtroot whose stbl contains slot
index 0. In dtroot_t, slot[0] overlays the header, so entries live in
slot[1] to slot[8]. check_dtroot() accepts 0 as a valid index and also
skips the duplicate check for it.

jfs_readdir() then calls add_missing_indices(), which treats slot[0]
as an ldtentry and writes the new directory index into its index
field. That field overlays header.stbl[4..7], so the write corrupts
the stbl itself. On the next readdir, stbl[4] holds the new index
(11 here), add_missing_indices() computes &p->slot[11] in a 9-slot
array, and the index write lands past the inline dtroot, in the
embedded vfs_inode. A hardware watchpoint on i_security confirms the
write comes from add_missing_indices(). KASAN cannot catch it because
it stays inside the jfs_inode_info object.

Reject stbl entries below 1 in check_dtroot(), as check_dtpage()
already does for regular pages, and apply the duplicate check to every
entry.

Tested in a KASAN guest: the syzbot reproducer crashes the unpatched
kernel within seconds. With this patch the image is rejected at inode
read ("Bad index:0 of stbl[3] in dtroot") and the reproducer runs to
completion. Mounting a clean mkfs.jfs image, creating 80 entries in the
root (forcing a root split), remounting, deleting them and remounting
again still works.

Fixes: c83abc766aeb ("jfs: add dtroot integrity check to prevent index out-of-bounds")
Reported-by: syzbot+b547ffac63b636628299@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=b547ffac63b636628299
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Nicholas Velten <nicholasfvelten@gmail.com>
---
Root cause and the hardware-watchpoint trace are in the commit message.

The reproducer is syzbot's C repro, run in a virtme-ng KASAN guest built
from next-20261009 with JFS, BPF LSM and gadgetfs enabled.

Not tested: architectures other than x86_64, and jfs_fsck on the
rejected image.
---
 fs/jfs/jfs_dtree.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/fs/jfs/jfs_dtree.c b/fs/jfs/jfs_dtree.c
index 8ce6e4458..b30eb0889 100644
--- a/fs/jfs/jfs_dtree.c
+++ b/fs/jfs/jfs_dtree.c
@@ -4360,19 +4360,19 @@ bool check_dtroot(dtroot_t *p)
 	}
 
 	/* Validate index validity of stbl array (8 elements)
-	 * Each entry in stbl is a slot index, with valid range: -1 (invalid)
-	 * or 0~8 (slot[0]~slot[8])
+	 * Each entry in stbl is a slot index, with valid range 1~8
+	 * (slot[1]~slot[8], since slot[0] is occupied by the header)
 	 */
 	for (i = 0; i < p->header.nextindex; i++) {
 		int idx = p->header.stbl[i];
 
-		if (unlikely(idx < 0 || idx >= 9)) {
+		if (unlikely(idx < 1 || idx >= 9)) {
 			jfs_err("Bad index:%d of stbl[%d] in dtroot\n", idx, i);
 			return false; /* stbl entry points out of slot array range */
 		}
 
-		/* Check for duplicate valid indices (skip check for idx=0) */
-		if (unlikely(idx && __test_and_set_bit(idx, bitmap))) {
+		/* Check for duplicate indices */
+		if (unlikely(__test_and_set_bit(idx, bitmap))) {
 			jfs_err("Duplicate index:%d in stbl in dtroot\n", idx);
 			return false;
 		}

---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20261020-jfs-dtroot-stbl-slot0-50e98a7fa738

Best regards,
--  
Nicholas Velten <nicholasfvelten@gmail.com>

