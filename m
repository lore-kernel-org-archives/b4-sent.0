From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 26 Nov 2026 07:50:31 +0100
Subject: [PATCH v2 1/2] ceph: send the cap messages of an inode in the
 order they were prepared
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-ceph-append-excl-v2-1-e8707d123d77@clyso.com>
References: <20261126-ceph-append-excl-v2-0-e8707d123d77@clyso.com>
In-Reply-To: <20261126-ceph-append-excl-v2-0-e8707d123d77@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anthony D'Atri <anthony.datri@gmail.com>, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795675836; l=5427;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=y3woOdrYDlCWZyslXlQYRQjjWOiA5KFxuYSJ/ghk1wc=;
 b=Q601uewoxsAbRx4eXPEUDSQKfbz/JPWruB1QFnCxElbBREOvI4PLtHq0qWsuJO2RYkEGxtIke
 bAXBpJNRwSyAbnbOf5bar0bgpgTuDM0V8fAGHZnYiI7BY3vQT+FL4nL
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__prep_cap() runs under i_ceph_lock: it drops the released caps from
cap->implemented and moves the dirty caps to flushing.  __send_cap()
then allocates and sends the message after the lock was dropped, so
two threads that check the caps of an inode at the same time, e.g. one
putting its last cap refs and one handling a revoke, can send their
messages in the opposite order.

The later message no longer has the dirty caps, nor the caps that the
earlier one gives up.  If it reaches the MDS first, the MDS sees those
caps released with nothing dirty, finishes its gather and may hand the
caps to another client before the flush with our new size and mtime
arrives.  Seen with two clients appending to a file with O_DIRECT: the
MDS completed the gather of Fw on an update with dirty=-, sent Fx with
the old size to the other client, and the flush with the new size
arrived 1 ms later; the other client wrote over our last record.

Number the messages of an inode in __prep_cap() and let __send_cap()
send them in that order.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c  | 29 +++++++++++++++++++++++++++++
 fs/ceph/inode.c |  3 +++
 fs/ceph/super.h |  3 +++
 3 files changed, 35 insertions(+)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 3f4ac4d94d5b..fd6f3a372271 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1398,6 +1398,7 @@ struct cap_msg_args {
 	umode_t			mode;
 	bool			inline_data;
 	bool			wake;
+	u32			ticket;		/* send order, see __send_cap() */
 	bool			encrypted;
 	u32			fscrypt_auth_len;
 	u8			fscrypt_auth[sizeof(struct ceph_fscrypt_auth)]; // for context
@@ -1575,6 +1576,7 @@ static void __prep_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci,
 	clear_bit(CEPH_I_FLUSH_BIT, &ci->i_ceph_flags);
 
 	cap->issued &= retain;  /* drop bits we don't want */
+	arg->ticket = ci->i_cap_msg_next++;
 	/*
 	 * Wake up any waiters on wanted -> needed transition. This is due to
 	 * the weird transition from buffered to sync IO... we need to flush
@@ -1698,6 +1700,30 @@ static inline int cap_msg_size(struct cap_msg_args *arg)
  *
  * Caller should hold snap_rwsem (read), s_mutex.
  */
+/*
+ * __prep_cap() updates cap->implemented and moves the dirty caps to
+ * flushing under i_ceph_lock, but the message goes out after the lock
+ * was dropped.  Another thread may prepare a later message for the same
+ * inode meanwhile, which then no longer has the dirty caps nor the caps
+ * we are giving up: if it went out first, the MDS would see those caps
+ * released with nothing dirty, finish its gather and hand them (with an
+ * out of date size, say) to another client before our flush arrived.
+ * Send the messages of an inode in the order they were prepared.
+ */
+static void __cap_msg_wait_turn(struct ceph_inode_info *ci, u32 ticket)
+{
+	wait_event(ci->i_cap_msg_wq,
+		   READ_ONCE(ci->i_cap_msg_sent) == ticket);
+}
+
+static void __cap_msg_done(struct ceph_inode_info *ci)
+{
+	spin_lock(&ci->i_ceph_lock);
+	ci->i_cap_msg_sent++;
+	spin_unlock(&ci->i_ceph_lock);
+	wake_up_all(&ci->i_cap_msg_wq);
+}
+
 static void __send_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci)
 {
 	struct ceph_msg *msg;
@@ -1706,6 +1732,7 @@ static void __send_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci)
 
 	msg = ceph_msg_new(CEPH_MSG_CLIENT_CAPS, cap_msg_size(arg), GFP_NOFS,
 			   false);
+	__cap_msg_wait_turn(ci, arg->ticket);
 	if (!msg) {
 		pr_err_client(cl,
 			      "error allocating cap msg: ino (%llx.%llx)"
@@ -1715,6 +1742,7 @@ static void __send_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci)
 		spin_lock(&ci->i_ceph_lock);
 		__cap_delay_requeue(arg->session->s_mdsc, ci);
 		spin_unlock(&ci->i_ceph_lock);
+		__cap_msg_done(ci);
 		ceph_buffer_put(arg->old_xattr_buf);
 		ceph_buffer_put(arg->xattr_buf);
 		return;
@@ -1722,6 +1750,7 @@ static void __send_cap(struct cap_msg_args *arg, struct ceph_inode_info *ci)
 
 	encode_cap_msg(msg, arg);
 	ceph_con_send(&arg->session->s_con, msg);
+	__cap_msg_done(ci);
 	ceph_buffer_put(arg->old_xattr_buf);
 	ceph_buffer_put(arg->xattr_buf);
 	if (arg->wake)
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index b615326f83bf..2e5d1256a3a5 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -675,6 +675,9 @@ struct inode *ceph_alloc_inode(struct super_block *sb)
 	ci->i_prealloc_cap_flush = NULL;
 	INIT_LIST_HEAD(&ci->i_cap_flush_list);
 	init_waitqueue_head(&ci->i_cap_wq);
+	ci->i_cap_msg_next = 0;
+	ci->i_cap_msg_sent = 0;
+	init_waitqueue_head(&ci->i_cap_msg_wq);
 	ci->i_hold_caps_max = 0;
 	INIT_LIST_HEAD(&ci->i_cap_delay_list);
 	INIT_LIST_HEAD(&ci->i_cap_snaps);
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index 0e6c8968b80d..b11083ad1da7 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -483,6 +483,9 @@ struct ceph_inode_info {
 	struct ceph_cap_flush *i_prealloc_cap_flush;
 	struct list_head i_cap_flush_list;
 	wait_queue_head_t i_cap_wq;      /* threads waiting on a capability */
+	/* cap messages prepared and sent, see __send_cap() */
+	u32 i_cap_msg_next, i_cap_msg_sent;
+	wait_queue_head_t i_cap_msg_wq;
 	unsigned long i_hold_caps_max; /* jiffies */
 	struct list_head i_cap_delay_list;  /* for delayed cap release to mds */
 	struct list_head i_cap_snaps;   /* snapped state pending flush to mds */

-- 
2.53.0

