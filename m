From: FAN YE <fy15309206903@gmail.com>
Date: Sun, 23 Aug 2026 12:31:31 +0000
Subject: [PATCH v2] pnfs/blocklayout: fix lost wakeup in
 bl_resolve_deviceid()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-rpc-pipefs-blwake-v2-1-68d73e3393ef@gmail.com>
X-B4-Tracking: v=1; b=H4sIACLoimoC/yXMQQqDQAxA0atI1gY0gopXERdxjG1a0WFiqyDe3
 bFdvsX/B5gEFYMmOSDIV02XOYLSBNyT54egDtFAGZVZTQUG79Crl9GwnzZ+CxbMQ17VTFWZQ+x
 8kFH337Pt/rZP/xK33iM4zwsVA457dQAAAA==
X-Change-ID: 20260823-rpc-pipefs-blwake-3aad178a2761
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787488290; l=6355;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=GUCmlSPgW25vtRiaxMysdyMflci1Pdrzl9xUo82bWug=;
 b=qNm6Aa1P38d1DYXo8quAiYEk7cED6mc8W8kMwbKXBipuJ18afmSUF0OVdnDhdAYuKYLmAIpS7
 30g6Zo69jfaD9OYs1MpYICPl4TzwQcdVUp2kTQtvfJAhZBZNgI732qu
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bl_resolve_deviceid() queues itself on nn->bl_wq and calls
rpc_queue_upcall(), but sets TASK_UNINTERRUPTIBLE only after that call
returns.  If blkmapd answers on another CPU in between, the wake_up()
from bl_pipe_downcall() finds the task runnable and the assignment that
follows overwrites it, so schedule() never returns.  The caller holds
nn->bl_mutex, so every later blocklayout device resolution blocks behind
it.

Replace the open-coded wait with a completion, the way __cld_pipe_upcall()
waits.  The reply status is reset before the upcall so that the abort
path in bl_pipe_destroy_msg() cannot leave the caller looking at the
reply from an earlier resolution.

Fixes: fe0a9b740881 ("pnfsblock: add device operations")
Assisted-by: Claude:claude-opus-5
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Apologies for v1 [1]: I sent it without checking that rpc_queue_upcall()
can sleep, so the fix it proposed could not have worked.

Not seen on a real pNFS mount.  Everything below is from a VM, where a
debugfs hook calls bl_resolve_deviceid() with a fake nfs_server and a
fake blkmapd answers every upcall in the same loop iteration.  The lines
around the window are untouched.  Three kernels, same initramfs, all
built with CONFIG_DEBUG_ATOMIC_SLEEP:

                                  upstream   v1       this patch
  5000 upcalls, no added delay    2 hangs a  ok       ok
  rpc_queue_upcall() made to
    block for 50ms                hangs      wrong b  ok
  upcall aborted by the daemon
    closing the pipe unread       stale c    stale c  0 + warning
  DEBUG_ATOMIC_SLEEP              quiet      warns d  quiet

  a  over 4 x 5000 rounds, nothing widened.  The stuck task stops at the
     schedule() that follows set_current_state(), still holding
     nn->bl_mutex, and the next caller then blocks on that mutex.
  b  an msleep() where rpc_queue_upcall() does its dput() clears the
     task state, so v1 falls through and returns the device number of
     the previous resolution.  On upstream the same injection is
     harmless, since it sets the state afterwards.
  c  bl_mount_reply is never reinitialised, so the wakeup from
     bl_pipe_destroy_msg() leaves the caller reading the reply from the
     previous resolution and returning that device.  This is what the
     reply->status reset addresses; it is a bug of its own, independent
     of the lost wakeup.
  d  on the first upcall, before any race: "do not call blocking ops
     when !TASK_RUNNING; state=2 set at bl_resolve_deviceid".

[1] https://lore.kernel.org/r/20260821-rpc-pipefs-blwake-v1-1-3e70ec9b0537@gmail.com
---
 fs/nfs/blocklayout/blocklayout.h |  2 +-
 fs/nfs/blocklayout/rpc_pipefs.c  | 20 ++++++++------------
 fs/nfs/netns.h                   |  3 ++-
 3 files changed, 11 insertions(+), 14 deletions(-)

diff --git a/fs/nfs/blocklayout/blocklayout.h b/fs/nfs/blocklayout/blocklayout.h
index 6da40ca19570..12283e0d2556 100644
--- a/fs/nfs/blocklayout/blocklayout.h
+++ b/fs/nfs/blocklayout/blocklayout.h
@@ -163,7 +163,7 @@ BLK_LSEG2EXT(struct pnfs_layout_segment *lseg)
 
 struct bl_pipe_msg {
 	struct rpc_pipe_msg msg;
-	wait_queue_head_t *bl_wq;
+	struct completion *bl_recv;
 };
 
 struct bl_msg_hdr {
diff --git a/fs/nfs/blocklayout/rpc_pipefs.c b/fs/nfs/blocklayout/rpc_pipefs.c
index d526f5ba7887..91f9c5b6fa10 100644
--- a/fs/nfs/blocklayout/rpc_pipefs.c
+++ b/fs/nfs/blocklayout/rpc_pipefs.c
@@ -58,14 +58,15 @@ bl_resolve_deviceid(struct nfs_server *server, struct pnfs_block_volume *b,
 	struct bl_pipe_msg bl_pipe_msg;
 	struct rpc_pipe_msg *msg = &bl_pipe_msg.msg;
 	struct bl_msg_hdr *bl_msg;
-	DECLARE_WAITQUEUE(wq, current);
 	dev_t dev = 0;
 	int rc;
 
 	dprintk("%s CREATING PIPEFS MESSAGE\n", __func__);
 
 	mutex_lock(&nn->bl_mutex);
-	bl_pipe_msg.bl_wq = &nn->bl_wq;
+	bl_pipe_msg.bl_recv = &nn->bl_recv;
+	reinit_completion(&nn->bl_recv);
+	reply->status = BL_DEVICE_REQUEST_INIT;
 
 	b->simple.len += 4;	/* single volume */
 	if (b->simple.len > PAGE_SIZE)
@@ -83,16 +84,11 @@ bl_resolve_deviceid(struct nfs_server *server, struct pnfs_block_volume *b,
 	nfs4_encode_simple(msg->data + sizeof(*bl_msg), b);
 
 	dprintk("%s CALLING USERSPACE DAEMON\n", __func__);
-	add_wait_queue(&nn->bl_wq, &wq);
 	rc = rpc_queue_upcall(nn->bl_device_pipe, msg);
-	if (rc < 0) {
-		remove_wait_queue(&nn->bl_wq, &wq);
+	if (rc < 0)
 		goto out_free_data;
-	}
 
-	set_current_state(TASK_UNINTERRUPTIBLE);
-	schedule();
-	remove_wait_queue(&nn->bl_wq, &wq);
+	wait_for_completion(&nn->bl_recv);
 
 	if (reply->status != BL_DEVICE_REQUEST_PROC) {
 		printk(KERN_WARNING "%s failed to decode device: %d\n",
@@ -120,7 +116,7 @@ static ssize_t bl_pipe_downcall(struct file *filp, const char __user *src,
 	if (copy_from_user(&nn->bl_mount_reply, src, mlen) != 0)
 		return -EFAULT;
 
-	wake_up(&nn->bl_wq);
+	complete(&nn->bl_recv);
 
 	return mlen;
 }
@@ -132,7 +128,7 @@ static void bl_pipe_destroy_msg(struct rpc_pipe_msg *msg)
 
 	if (msg->errno >= 0)
 		return;
-	wake_up(bl_pipe_msg->bl_wq);
+	complete(bl_pipe_msg->bl_recv);
 }
 
 static const struct rpc_pipe_ops bl_upcall_ops = {
@@ -221,7 +217,7 @@ static int nfs4blocklayout_net_init(struct net *net)
 	int err;
 
 	mutex_init(&nn->bl_mutex);
-	init_waitqueue_head(&nn->bl_wq);
+	init_completion(&nn->bl_recv);
 	nn->bl_device_pipe = rpc_mkpipe_data(&bl_upcall_ops, 0);
 	if (IS_ERR(nn->bl_device_pipe))
 		return PTR_ERR(nn->bl_device_pipe);
diff --git a/fs/nfs/netns.h b/fs/nfs/netns.h
index 36658579100d..ad8e246e1c18 100644
--- a/fs/nfs/netns.h
+++ b/fs/nfs/netns.h
@@ -6,6 +6,7 @@
 #ifndef __NFS_NETNS_H__
 #define __NFS_NETNS_H__
 
+#include <linux/completion.h>
 #include <linux/nfs4.h>
 #include <net/net_namespace.h>
 #include <net/netns/generic.h>
@@ -22,7 +23,7 @@ struct nfs_net {
 	struct cache_detail *nfs_dns_resolve;
 	struct rpc_pipe *bl_device_pipe;
 	struct bl_dev_msg bl_mount_reply;
-	wait_queue_head_t bl_wq;
+	struct completion bl_recv;
 	struct mutex bl_mutex;
 	struct list_head nfs_client_list;
 	struct list_head nfs_volume_list;

---
base-commit: 2709dd5ae32f0828f386327c76bba9f39f63a1c6
change-id: 20260823-rpc-pipefs-blwake-3aad178a2761

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

