From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 03 Nov 2026 14:04:10 -0500
Subject: [PATCH] blk-mq: take quiesce_lock when removing a queue from the
 tag set
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-blk-mq-del-quiesce-lock-v1-1-04aa29a481f6@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSw6CMBRG4a2QO+YmLRp5bIU4sOVHLpRXK8aEs
 HeLDr/BOTsFeEGgKtnJ4y1B5ilCpwnZ7jE9wdJEU6aym9bqwsYNPK7cwPG6xdKC3WwHNiVUW+j
 ympuCYr14tPL5nev732EzPezr3NFxfAEh1NGHewAAAA==
X-Change-ID: 20261103-blk-mq-del-quiesce-lock-b9e0f81947b8
To: Jens Axboe <axboe@kernel.dk>
Cc: Mohamed Khalfella <mkhalfella@purestorage.com>, 
 Keith Busch <kbusch@kernel.org>, Ming Lei <tom.leiming@gmail.com>, 
 Bart Van Assche <bvanassche@acm.org>, Christoph Hellwig <hch@lst.de>, 
 Nilay Shroff <nilay@linux.ibm.com>, Josef Bacik <josef@toxicpanda.com>, 
 linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793732649; l=4068;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=N19XFK6Pp+jL6yjmYqq3sqsEIVvyVqas9SpWxi3HCEA=;
 b=KLSAIAInJMbfO/21dGqhMqi18T4b90sFGUsLqNtLBOtEtudKJecw/Bt+m+iV7SNh2BtKReW2Z
 alM2Gh4DK7TBrSEQ2KSyc1pzeTIemYgMvXVPO71MFIFGn6ZxglREXk3
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unquiescing a tag set can run the hw queues of a queue whose hctxs were
already freed.  blk_mq_unquiesce_tagset() walks the tag set's queues
under quiesce_lock and rcu_read_lock().  Commit 71ec3c7d6db8 ("blk-mq:
quiesce a queue that joins a quiesced tag set") added quiesce_lock to
the walks and to adding a queue, but blk_mq_del_queue_tag_set() still
removes a queue without it.  The hctxs are then freed right away since
RCU only keeps the request_queue itself alive:

  Task A (controller reset)            Task B (namespace removal)
  blk_mq_unquiesce_tagset()
    /* finds q */
                                       blk_mq_del_queue_tag_set(q)
                                       blk_mq_release(q)
                                         /* frees the hctxs */
    blk_mq_run_hw_queues(q)
      /* reads freed hctxs */

The window is short.  On PREEMPT_RT quiesce_lock is a sleeping lock and
the walk can be preempted inside it, which is how it's hit here:

  [  399.851277] BUG: KASAN: slab-use-after-free in blk_mq_run_hw_queues+0x4bd/0x550
  [  399.851328] Read of size 8 at addr ff11000003014148 by task kworker/u9:2/116
  [  399.851352] CPU: 1 UID: 0 PID: 116 Comm: kworker/u9:2 Not tainted 7.3.0-16299-g81cb9aa43246 #1 PREEMPT_RT
  [  399.851425] Workqueue: nvme-reset-wq nvme_loop_reset_ctrl_work
  [  399.851441] Call Trace:
  [  399.851457]  <TASK>
  [  399.851551]  blk_mq_run_hw_queues+0x4bd/0x550
  [  399.851564]  blk_mq_unquiesce_tagset+0x128/0x210
  [  399.851576]  nvme_loop_reset_ctrl_work+0x78/0x4c0
  [  399.851600]  process_one_work+0x92b/0x16d0
  [  399.851660]  worker_thread+0x4e6/0xd60
  [  399.851707]  kthread+0x300/0x3e0
  [  399.851727]  ret_from_fork+0x4f0/0x6f0
  [  399.851776]  ret_from_fork_asm+0x1a/0x30
  [  399.851793]  </TASK>
  ...
  [  399.851988] Freed by task 111:
  [  399.852040]  kfree+0x1b3/0x4b0
  [  399.852050]  blk_mq_release+0x400/0x550
  [  399.852060]  blk_put_queue+0x94/0x120
  [  399.852068]  disk_release+0x1bd/0x3f0
  [  399.852102]  nvme_free_ns+0x39/0x270
  [  399.852113]  nvme_remove_nsid_range+0x2d1/0x4a0
  [  399.852123]  nvme_scan_ns_list+0x2cc/0x390
  [  399.852134]  nvme_scan_work+0x421/0x9f0
  ...

With BLK_CGROUP the disk's root blkg holds the queue until a grace
period later, which hides this for NVMe namespaces.  It's still open
without BLK_CGROUP, and from reading the code also for queues freed
without a disk (e.g., SCSI device queues on a UFS host).

Take quiesce_lock around the list_del_rcu() as well so that the walk
either finishes with a queue before it leaves the list or never sees
it.  With the fix, KASAN doesn't report the use-after-free anymore.

This bug was identified and confirmed with the help of a deterministic
hypervisor currently under development.  The C reproducer below however
hits it about once every 20 minutes on a PREEMPT_RT kernel.

Fixes: 59e25ef2b413 ("block: Use RCU in blk_mq_[un]quiesce_tagset() instead of set->tag_list_lock")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Stable trees need 71ec3c7d6db8 first since it adds quiesce_lock.

Reproducer: https://github.com/manitofigh/files/blob/main/linux-repros/blkquiesce.c
---
 block/blk-mq.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/block/blk-mq.c b/block/blk-mq.c
index 5ae22d556540..54ccfc43c27c 100644
--- a/block/blk-mq.c
+++ b/block/blk-mq.c
@@ -4354,7 +4354,10 @@ static void blk_mq_del_queue_tag_set(struct request_queue *q)
 
 	lockdep_assert_held(&set->tag_list_lock);
 
+	/* blk_mq_unquiesce_tagset() runs the hctxs, which are not RCU freed */
+	spin_lock(&set->quiesce_lock);
 	list_del_rcu(&q->tag_set_list);
+	spin_unlock(&set->quiesce_lock);
 	if (list_is_singular(&set->tag_list)) {
 		/* just transitioned to unshared */
 		set->flags &= ~BLK_MQ_F_TAG_QUEUE_SHARED;

---
base-commit: 801bddbf1e4147a69b811c548c35a06a157941b4
change-id: 20261103-blk-mq-del-quiesce-lock-b9e0f81947b8

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

