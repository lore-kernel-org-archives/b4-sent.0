From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 02 Sep 2026 06:38:49 -0700
Subject: [PATCH] ceph: offload readdir reply fill from the mds connection
 worker
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260902-b4-offload-readdir-reply-fill-v1-1-4b74fe27c841@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCQAyF4auUrA2kQynoVcTFtEk0MnTKjBal9
 O5NdfX43uJfoUoxqXBpViiyWLU8OdpTA+MjTndBYzcECj2dKeDQYVZNOTIWicxWfOf0RbWUUEk
 6P6mP3II35iJqn1//evu7voenjK8jCtu2AxuhdTiBAAAA
X-Change-ID: 20260902-b4-offload-readdir-reply-fill-f0e4add06ad1
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788356335; l=37242;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=AetFMSJX1omlbzD5IdM8Jz+2hWyT42Ych2/DLb9OciI=;
 b=P45NcLOd+U28ZZWLR+zo+r4g9NLuPRAaieBh31E3R0tFp4gqx4gkXTXGNINzMDqitTDu6Yuw4
 sTAwa7+JOHrBKQ5AFBABy5LNlO16RkDXAmTPsUf22SFSWo12fofFZSG
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A readdir reply can carry up to readdir_max_entries (1024) worth of
dentries and inodes.  Decoding it with parse_reply_info() and
prepopulating the dcache with ceph_readdir_prepopulate() can take
several milliseconds and, done on the mds connection worker, stalls
every other message on the same session: lookups, creates and cap
messages all queue up behind the fill, which shows up as latency
spikes and caps the client-side metadata throughput.

Offload the fill of readdir replies to a per-mdsc unbound workqueue.
The bookkeeping that must stay in message order (request lookup, dup
checks, unsafe/safe registration) remains on the worker; everything
from parse_reply_info() through complete_request() moves to the work
item, without holding session->s_mutex.  As a heuristic, only
replies of at least 64 KiB are queued; smaller replies (mostly empty
dirs and tail frags) fill in microseconds, where queueing them would
be pure overhead.  The MDS always marks readdir replies safe, so the
request is already unregistered when the fill is offloaded, and the
work item holds lookup_get_request()'s reference, keeping the
request and its r_dentry alive until the fill finishes.  The entries
live in the message front, which the size test measures.

The ordering the worker used to provide implicitly is re-established
explicitly:

  what                    how
  ------------------------------------------------------------------
  request lifetime        r_fill_mutex keeps serializing the fill
                          against abort/timeout; an aborted request
                          keeps its chain slot and runs its fill
                          when reached; a safe reply waits on
                          r_fill_waitq until
                          CEPH_MDS_R_FILL_OFFLOADED clears before
                          unregistering the request
  per-directory order     fills of one directory are chained on
                          i_fill_chain (i_ceph_lock), one at a time,
                          so per-dir reply order is kept while fills
                          of unrelated dirs run in parallel; the
                          inline path waits per directory on
                          i_fill_count/i_fill_wq; each chained
                          request holds r_dentry, pinning the inode
  session teardown order  ceph_handle_caps(), handle_lease(),
                          cleanup_session_requests() and
                          remove_session_caps() wait for
                          s_fill_inflight to drop to zero.  Dentry-
                          less replies wait on the target inode's
                          own chain, entry races being absorbed by
                          ceph_add_cap()'s stale-sequence check.
                          Offloading is gated on
                          s_fill_offload_enabled, set while the
                          session is OPEN and cleared on every
                          transition away (disable, drain, cleanup),
                          so reconnect/reset never races an old
                          fill; close_sessions runs only after the
                          fill barrier is released

The waiting is deadlock-free: waiters hold no lock the fill work
items take (the items never take session->s_mutex), and the items
never depend on the worker.  The work item owns the request and
ceph_msg references and drops them when the fill finishes;
ceph_mdsc_pre_umount() flushes the workqueue after ceph_msgr_flush()
so no fill can run during shutdown.

Testing: single-MDS vstart cluster, MDS and client on the same box;
the offload sits behind a runtime toggle, so both sides of each A/B
pair run the identical workload back to back.  Fill durations were
measured with temporary debugfs counters, not part of this patch.

Mechanism, readdir-heavy phases (medians over three runs):

  metric                  baseline        offload
  ----------------------------------------------------------
  worker reply time         11.2 s          8.8 s
  fills >= 64 KiB          inline        1,952/1,953
  decode moved to fill_wq      -           10.8 s
  utime p50                211.0 us       210.6 us
  utime p99               2391.7 us      2555.7 us

End-to-end latency did not change, as expected when the MDS runs on
the same host and the fill is cheap; umount-mid-flood and evict
stress rounds passed with both settings.

Amplified fills (200k-entry fragmented dir, readdir_max_entries=16384,
replies up to 1.44 MiB, one fill taking tens of ms, max 77.5 ms;
continuous readdir flood with drop_caches, stat(2) on dcache-missing
files, medians over three rounds):

  metric                baseline    offload    change
  ----------------------------------------------------------
  stat p99             49.6 ms     16.7 ms     -66%
  stat p90              763 us      422 us     -45%
  stat mean             1.46 ms     0.57 ms    -61%
  stat ops/s             684        1753       +156%
  utime p99            62.5 ms     67.2 ms    neutral
  utime ops/s            271         276      neutral
  readdir replies        2402        2490     same traffic
  worker reply time    64.2 s      30.4 s     -53%

utime(2) is a pure MDS-side write op, so the offload cannot speed it
up; the stat(2) numbers isolate the worker queue this patch removes.
Per-round variance is dominated by cache/flood phase alignment (one
baseline round ran before the flood had ramped).

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c       |  10 +
 fs/ceph/inode.c      |   3 +
 fs/ceph/mds_client.c | 532 ++++++++++++++++++++++++++++++++++++++++++---------
 fs/ceph/mds_client.h |  16 ++
 fs/ceph/super.h      |   7 +
 5 files changed, 475 insertions(+), 93 deletions(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index 1847badddd87..fe757ed396f0 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -4446,6 +4446,16 @@ void ceph_handle_caps(struct ceph_mds_session *session,
 	struct ceph_mds_client *mdsc = session->s_mdsc;
 	struct ceph_client *cl = mdsc->fsc->client;
 	struct inode *inode;
+
+	/*
+	 * Readdir replies are filled by workqueue threads, which may still
+	 * be adding the caps granted in the reply's trace.  Wait for any
+	 * earlier offloaded reply fills to finish before applying the cap
+	 * message, preserving the ordering that the old inline reply
+	 * handling provided.
+	 */
+	wait_event(session->s_fill_wq, !atomic_read(&session->s_fill_inflight));
+
 	struct ceph_inode_info *ci;
 	struct ceph_cap *cap;
 	struct ceph_mds_caps *h;
diff --git a/fs/ceph/inode.c b/fs/ceph/inode.c
index 9ea0588a18f9..30e81782fb4c 100644
--- a/fs/ceph/inode.c
+++ b/fs/ceph/inode.c
@@ -634,6 +634,9 @@ struct inode *ceph_alloc_inode(struct super_block *sb)
 	netfs_inode_init(&ci->netfs, &ceph_netfs_ops, false);
 
 	spin_lock_init(&ci->i_ceph_lock);
+	INIT_LIST_HEAD(&ci->i_fill_chain);
+	atomic_set(&ci->i_fill_count, 0);
+	init_waitqueue_head(&ci->i_fill_wq);
 
 	ci->i_version = 0;
 	ceph_set_inline_version(ci, 0);
diff --git a/fs/ceph/mds_client.c b/fs/ceph/mds_client.c
index 85f8ceb10377..59805d436558 100644
--- a/fs/ceph/mds_client.c
+++ b/fs/ceph/mds_client.c
@@ -1130,6 +1130,9 @@ static struct ceph_mds_session *register_session(struct ceph_mds_client *mdsc,
 	refcount_set(&s->s_ref, 1);
 	INIT_LIST_HEAD(&s->s_waiting);
 	INIT_LIST_HEAD(&s->s_unsafe);
+	atomic_set(&s->s_fill_inflight, 0);
+	init_waitqueue_head(&s->s_fill_wq);
+	s->s_fill_offload_enabled = false;
 	xa_init(&s->s_delegated_inos);
 	atomic_set(&s->s_num_deleg_inos, 0);
 	INIT_LIST_HEAD(&s->s_cap_releases);
@@ -1900,6 +1903,23 @@ static void dispose_cap_releases(struct ceph_mds_client *mdsc,
 	}
 }
 
+/*
+ * Allow or forbid offloading of readdir reply fills.  The flag is
+ * protected by mdsc->mutex, which also serializes it against the
+ * appends in handle_reply() and the disable/drain in
+ * cleanup_session_requests().  Must not be called with mdsc->mutex
+ * held.
+ */
+static void ceph_mdsc_set_fill_offload(struct ceph_mds_session *session,
+				       bool enable)
+{
+	struct ceph_mds_client *mdsc = session->s_mdsc;
+
+	mutex_lock(&mdsc->mutex);
+	session->s_fill_offload_enabled = enable;
+	mutex_unlock(&mdsc->mutex);
+}
+
 static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 				     struct ceph_mds_session *session)
 {
@@ -1908,6 +1928,31 @@ static void cleanup_session_requests(struct ceph_mds_client *mdsc,
 	struct rb_node *p;
 
 	doutc(cl, "mds%d\n", session->s_mds);
+
+	/*
+	 * All callers hold session->s_mutex; that also serializes the
+	 * whole disable/drain/drop section below against the
+	 * re-enabling of s_fill_offload_enabled in handle_session()
+	 * (which runs under the same mutex), so no fill can be
+	 * appended between the drain and the dropping of the unsafe
+	 * requests.
+	 */
+	lockdep_assert_held(&session->s_mutex);
+
+	/*
+	 * The session is going away: first stop new fills from being
+	 * appended, then wait for the in-flight ones, so that dropping
+	 * the unsafe requests below cannot race a fill that has not
+	 * yet finished adding the request to the target inode's unsafe
+	 * list.  The fill items never take mdsc->mutex nor wait on the
+	 * connection worker, so this drains and cannot deadlock.
+	 */
+	mutex_lock(&mdsc->mutex);
+	session->s_fill_offload_enabled = false;
+	mutex_unlock(&mdsc->mutex);
+
+	wait_event(session->s_fill_wq, !atomic_read(&session->s_fill_inflight));
+
 	mutex_lock(&mdsc->mutex);
 	while (!list_empty(&session->s_unsafe)) {
 		req = list_first_entry(&session->s_unsafe,
@@ -2038,6 +2083,13 @@ static int remove_session_caps_cb(struct inode *inode, int mds, void *arg)
  */
 static void remove_session_caps(struct ceph_mds_session *session)
 {
+	/*
+	 * Wait for offloaded reply fills, which may still be adding caps
+	 * to this session.  The fill work items never take s_mutex, so
+	 * this cannot deadlock.
+	 */
+	wait_event(session->s_fill_wq, !atomic_read(&session->s_fill_inflight));
+
 	struct ceph_fs_client *fsc = session->s_mdsc->fsc;
 	struct super_block *sb = fsc->sb;
 	LIST_HEAD(dispose);
@@ -2246,6 +2298,7 @@ static int __close_session(struct ceph_mds_client *mdsc,
 {
 	if (session->s_state >= CEPH_MDS_SESSION_CLOSING)
 		return 0;
+	ceph_mdsc_set_fill_offload(session, false);
 	session->s_state = CEPH_MDS_SESSION_CLOSING;
 	return request_close_session(session);
 }
@@ -2810,6 +2863,7 @@ ceph_mdsc_create_request(struct ceph_mds_client *mdsc, int op, int mode)
 	INIT_LIST_HEAD(&req->r_wait);
 	init_completion(&req->r_completion);
 	init_completion(&req->r_safe_completion);
+	init_waitqueue_head(&req->r_fill_waitq);
 	INIT_LIST_HEAD(&req->r_unsafe_item);
 
 	ktime_get_coarse_real_ts64(&req->r_stamp);
@@ -4076,108 +4130,51 @@ void ceph_invalidate_dir_request(struct ceph_mds_request *req)
 }
 
 /*
- * Handle mds reply.
+ * Fill the trace of a reply into the inode and dentry caches, then
+ * complete the request and wake its waiters.
  *
- * We take the session mutex and parse and process the reply immediately.
- * This preserves the logical ordering of replies, capabilities, etc., sent
- * by the MDS as they are applied to our local cache.
+ * Runs either inline on the mds connection worker (offloaded ==
+ * false) with session->s_mutex held, or on mdsc->fill_wq (offloaded
+ * == true) without session->s_mutex.  In the latter case
+ * handle_reply() has already bumped session->s_fill_inflight;
+ * everything that must serialize with an in-flight fill waits on
+ * session->s_fill_wq for the counter to drop back to zero (see
+ * ceph_handle_caps(), handle_lease(), cleanup_session_requests()
+ * and remove_session_caps()).
+ *
+ * Returns true if the sessions should be closed (a snap trace update
+ * failed).  The caller must close them only after the fill is
+ * finished: on the offloaded path that means once this work item no
+ * longer counts against s_fill_inflight, since ceph_mdsc_close_sessions()
+ * tears the session down and remove_session_caps() waits for the
+ * counter to reach zero, which would otherwise wait on this very
+ * work item.
  */
-static void handle_reply(struct ceph_mds_session *session, struct ceph_msg *msg)
+static bool handle_reply_fill(struct ceph_mds_session *session,
+			      struct ceph_msg *msg,
+			      struct ceph_mds_request *req, bool offloaded)
 {
 	struct ceph_mds_client *mdsc = session->s_mdsc;
 	struct ceph_client *cl = mdsc->fsc->client;
-	struct ceph_mds_request *req;
 	struct ceph_mds_reply_head *head = msg->front.iov_base;
 	struct ceph_mds_reply_info_parsed *rinfo;  /* parsed reply info */
 	struct ceph_snap_realm *realm;
 	unsigned int nofs_flags;
-	u64 tid;
+	u64 peer_features;
 	int err, result;
 	int mds = session->s_mds;
 	bool close_sessions = false;
 
-	if (msg->front.iov_len < sizeof(*head)) {
-		pr_err_client(cl, "got corrupt (short) reply\n");
-		ceph_msg_dump(msg);
-		return;
-	}
-
-	/* get request, session */
-	tid = le64_to_cpu(msg->hdr.tid);
-	mutex_lock(&mdsc->mutex);
-	req = lookup_get_request(mdsc, tid);
-	if (!req) {
-		doutc(cl, "on unknown tid %llu\n", tid);
-		mutex_unlock(&mdsc->mutex);
-		return;
-	}
-	doutc(cl, "handle_reply %p\n", req);
-
-	/* correct session? */
-	if (req->r_session != session) {
-		pr_err_client(cl, "got %llu on session mds%d not mds%d\n",
-			      tid, session->s_mds,
-			      req->r_session ? req->r_session->s_mds : -1);
-		mutex_unlock(&mdsc->mutex);
-		goto out;
-	}
-
-	/* dup? */
-	if ((test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags) && !head->safe) ||
-	    (test_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags) && head->safe)) {
-		pr_warn_client(cl, "got a dup %s reply on %llu from mds%d\n",
-			       head->safe ? "safe" : "unsafe", tid, mds);
-		mutex_unlock(&mdsc->mutex);
-		goto out;
-	}
-	if (test_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags)) {
-		pr_warn_client(cl, "got unsafe after safe on %llu from mds%d\n",
-			       tid, mds);
-		mutex_unlock(&mdsc->mutex);
-		goto out;
-	}
-
 	result = le32_to_cpu(head->result);
+	doutc(cl, "tid %lld result %d\n", req->r_tid, result);
 
-	if (head->safe) {
-		set_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags);
-		__unregister_request(mdsc, req);
-
-		/* last request during umount? */
-		if (mdsc->stopping && !__get_oldest_req(mdsc))
-			complete_all(&mdsc->safe_umount_waiters);
-
-		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
-			/*
-			 * We already handled the unsafe response, now do the
-			 * cleanup.  No need to examine the response; the MDS
-			 * doesn't include any result info in the safe
-			 * response.  And even if it did, there is nothing
-			 * useful we could do with a revised return value.
-			 */
-			doutc(cl, "got safe reply %llu, mds%d\n", tid, mds);
-
-			mutex_unlock(&mdsc->mutex);
-			goto out;
-		}
-	} else {
-		set_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags);
-		list_add_tail(&req->r_unsafe_item, &req->r_session->s_unsafe);
-	}
-
-	/*
-	 * Now that all mutex-protected state has been updated above
-	 * (the request has been unregistered or added to the
-	 * session's unsafe list), we can unlock it.
-	 */
-	mutex_unlock(&mdsc->mutex);
-
-	doutc(cl, "tid %lld result %d\n", tid, result);
-	if (test_bit(CEPHFS_FEATURE_REPLY_ENCODING, &session->s_features))
-		err = parse_reply_info(session, msg, req, (u64)-1);
+	if (offloaded)
+		peer_features = req->r_fill_peer_features;
+	else if (test_bit(CEPHFS_FEATURE_REPLY_ENCODING, &session->s_features))
+		peer_features = (u64)-1;
 	else
-		err = parse_reply_info(session, msg, req,
-				       session->s_con.peer_features);
+		peer_features = session->s_con.peer_features;
+	err = parse_reply_info(session, msg, req, peer_features);
 
 	/* Must find target inode outside of mutexes to avoid deadlocks */
 	rinfo = &req->r_reply_info;
@@ -4203,17 +4200,19 @@ static void handle_reply(struct ceph_mds_session *session, struct ceph_msg *msg)
 		in = ceph_get_inode(mdsc->fsc->sb, tvino, in);
 		if (IS_ERR(in)) {
 			err = PTR_ERR(in);
-			mutex_lock(&session->s_mutex);
+			if (!offloaded)
+				mutex_lock(&session->s_mutex);
 			goto out_err;
 		}
 		req->r_target_inode = in;
 		ceph_inode_set_subvolume(in, rinfo->targeti.subvolume_id);
 	}
 
-	mutex_lock(&session->s_mutex);
+	if (!offloaded)
+		mutex_lock(&session->s_mutex);
 	if (err < 0) {
 		pr_err_client(cl, "got corrupt reply mds%d(tid:%lld)\n",
-			      mds, tid);
+			      mds, req->r_tid);
 		ceph_msg_dump(msg);
 		goto out_err;
 	}
@@ -4286,24 +4285,338 @@ static void handle_reply(struct ceph_mds_session *session, struct ceph_msg *msg)
 			set_bit(CEPH_MDS_R_GOT_RESULT, &req->r_req_flags);
 		}
 	} else {
-		doutc(cl, "reply arrived after request %lld was aborted\n", tid);
+		doutc(cl, "reply arrived after request %lld was aborted\n",
+		      req->r_tid);
 	}
 	mutex_unlock(&mdsc->mutex);
 
-	mutex_unlock(&session->s_mutex);
+	if (!offloaded)
+		mutex_unlock(&session->s_mutex);
 
 	/* kick calling process */
 	complete_request(mdsc, req);
 
 	ceph_update_metadata_metrics(&mdsc->metric, req->r_start_latency,
 				     req->r_end_latency, err);
+
+	/*
+	 * Defer closing the sessions to the caller; see the comment
+	 * above the function for why this must not happen here.
+	 */
+	return close_sessions;
+}
+
+static void handle_reply_fill_work(struct work_struct *work)
+{
+	struct ceph_mds_request *req =
+		container_of(work, struct ceph_mds_request, r_fill_work);
+	struct ceph_mds_session *session = req->r_session;
+	struct ceph_mds_client *mdsc = session->s_mdsc;
+	struct ceph_inode_info *ci = ceph_inode(d_inode(req->r_dentry));
+	struct ceph_mds_request *next;
+	struct ceph_msg *msg = req->r_fill_msg;
+	bool close_sessions;
+
+	close_sessions = handle_reply_fill(session, msg, req, true);
+
+	ceph_msg_put(msg);
+	req->r_fill_msg = NULL;
+
+	/*
+	 * The fill has finished all request-local bookkeeping that must
+	 * precede __unregister_request() (r_target_inode and the
+	 * inode's unsafe list); CEPH_MDS_R_FILL_OFFLOADED covers only
+	 * that, not the whole work item lifetime -- the directory-chain
+	 * handoff and the s_fill_inflight accounting below still lie
+	 * ahead.  A safe reply may have arrived in the meantime and be
+	 * waiting in handle_reply(); release it under mdsc->mutex so
+	 * that either it sees the flag and waits, or observes all the
+	 * fill's updates once the flag clears.
+	 */
+	mutex_lock(&mdsc->mutex);
+	clear_bit(CEPH_MDS_R_FILL_OFFLOADED, &req->r_req_flags);
+	mutex_unlock(&mdsc->mutex);
+	wake_up_all(&req->r_fill_waitq);
+
+	/*
+	 * The fill is done; hand the directory's chain over to the next
+	 * pending fill, preserving MDS reply order per directory.
+	 */
+	spin_lock(&ci->i_ceph_lock);
+	list_del(&req->r_fill_chain_item);
+	if (!list_empty(&ci->i_fill_chain)) {
+		next = list_first_entry(&ci->i_fill_chain,
+					struct ceph_mds_request,
+					r_fill_chain_item);
+		queue_work(mdsc->fill_wq, &next->r_fill_work);
+	}
+	if (atomic_dec_and_test(&ci->i_fill_count))
+		wake_up_all(&ci->i_fill_wq);
+	spin_unlock(&ci->i_ceph_lock);
+
+	if (atomic_dec_and_test(&session->s_fill_inflight))
+		wake_up_all(&session->s_fill_wq);
+
+	/* drop the ref taken in lookup_get_request() */
+	ceph_mdsc_put_request(req);
+
+	/*
+	 * Only now that this work item no longer counts against
+	 * s_fill_inflight can the sessions be closed (see the comment
+	 * above handle_reply_fill()).
+	 */
+	if (close_sessions)
+		ceph_mdsc_close_sessions(mdsc);
+}
+
+/*
+ * Handle mds reply.
+ *
+ * The bookkeeping that must stay in message order is done here on the
+ * mds connection worker; the fill of the trace is either done
+ * immediately (holding the session mutex, preserving the logical
+ * ordering of replies, capabilities, etc., sent by the MDS as they
+ * are applied to our local cache) or, for readdir replies, offloaded
+ * to mdsc->fill_wq (see the comment below).
+ */
+static void handle_reply(struct ceph_mds_session *session, struct ceph_msg *msg)
+{
+	struct ceph_mds_client *mdsc = session->s_mdsc;
+	struct ceph_client *cl = mdsc->fsc->client;
+	struct ceph_mds_request *req;
+	struct ceph_mds_reply_head *head = msg->front.iov_base;
+	u64 tid;
+	int mds = session->s_mds;
+	bool close_sessions = false;
+
+	if (msg->front.iov_len < sizeof(*head)) {
+		pr_err_client(cl, "got corrupt (short) reply\n");
+		ceph_msg_dump(msg);
+		return;
+	}
+
+	/* get request, session */
+	tid = le64_to_cpu(msg->hdr.tid);
+	mutex_lock(&mdsc->mutex);
+	req = lookup_get_request(mdsc, tid);
+	if (!req) {
+		doutc(cl, "on unknown tid %llu\n", tid);
+		mutex_unlock(&mdsc->mutex);
+		return;
+	}
+	doutc(cl, "%s %p\n", __func__, req);
+
+	/* correct session? */
+	if (req->r_session != session) {
+		pr_err_client(cl, "got %llu on session mds%d not mds%d\n",
+			      tid, session->s_mds,
+			      req->r_session ? req->r_session->s_mds : -1);
+		mutex_unlock(&mdsc->mutex);
+		goto out;
+	}
+
+	/* dup? */
+	if ((test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags) && !head->safe) ||
+	    (test_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags) && head->safe)) {
+		pr_warn_client(cl, "got a dup %s reply on %llu from mds%d\n",
+			       head->safe ? "safe" : "unsafe", tid, mds);
+		mutex_unlock(&mdsc->mutex);
+		goto out;
+	}
+	if (test_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags)) {
+		pr_warn_client(cl, "got unsafe after safe on %llu from mds%d\n",
+			       tid, mds);
+		mutex_unlock(&mdsc->mutex);
+		goto out;
+	}
+
+	if (head->safe) {
+		set_bit(CEPH_MDS_R_GOT_SAFE, &req->r_req_flags);
+		if (test_bit(CEPH_MDS_R_FILL_OFFLOADED, &req->r_req_flags)) {
+			/*
+			 * The unsafe reply's fill was offloaded and may
+			 * still be running; it owns the request's unsafe
+			 * bookkeeping until it finishes, so wait for it
+			 * before unregistering.  The fill never waits on
+			 * this worker, so this cannot deadlock.
+			 */
+			mutex_unlock(&mdsc->mutex);
+			wait_event(req->r_fill_waitq,
+				   !test_bit(CEPH_MDS_R_FILL_OFFLOADED,
+					     &req->r_req_flags));
+			mutex_lock(&mdsc->mutex);
+			/*
+			 * Session teardown may have dropped the request
+			 * while we waited; nothing left to unregister.
+			 */
+			if (RB_EMPTY_NODE(&req->r_node))
+				goto out;
+		}
+		__unregister_request(mdsc, req);
+
+		/* last request during umount? */
+		if (mdsc->stopping && !__get_oldest_req(mdsc))
+			complete_all(&mdsc->safe_umount_waiters);
+
+		if (test_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags)) {
+			/*
+			 * We already handled the unsafe response, now do the
+			 * cleanup.  No need to examine the response; the MDS
+			 * doesn't include any result info in the safe
+			 * response.  And even if it did, there is nothing
+			 * useful we could do with a revised return value.
+			 */
+			doutc(cl, "got safe reply %llu, mds%d\n", tid, mds);
+
+			mutex_unlock(&mdsc->mutex);
+			goto out;
+		}
+	} else {
+		set_bit(CEPH_MDS_R_GOT_UNSAFE, &req->r_req_flags);
+		list_add_tail(&req->r_unsafe_item, &req->r_session->s_unsafe);
+	}
+
+	/*
+	 * A readdir reply can carry up to readdir_max_entries worth of
+	 * dentries and inodes; decoding and prepopulating them can take
+	 * several milliseconds and, done on the connection worker, would
+	 * stall the processing of every other message on this session.
+	 * Offload the fill of these replies to the mdsc workqueue
+	 * instead.  As a heuristic, only replies of at least 64 KiB are
+	 * queued; small replies (mostly empty dirs and tail frags) fill
+	 * in microseconds, where the queueing and the completion on the
+	 * workqueue thread would be pure overhead.
+	 *
+	 * The MDS always marks readdir replies safe (read-only
+	 * operations are never journaled), so the safe-reply bookkeeping
+	 * above has already unregistered the request by the time the
+	 * gate below runs; the fill work item holds the request
+	 * reference taken by lookup_get_request(), keeping the request
+	 * and its r_dentry alive until the fill finishes.  The dentry
+	 * entries live in the message front, which is what the size
+	 * test below measures.
+	 *
+	 * Fills touching the same directory must be applied in the
+	 * order their replies are processed, so they are chained on
+	 * the directory inode (i_fill_chain): at most one fill per
+	 * directory runs at a time, and the next chained fill is
+	 * queued only when the current one finishes.  Appends happen
+	 * here on the mds worker, which processes replies one at a
+	 * time, and are serialized with the chain handoff in
+	 * handle_reply_fill_work() by the directory's i_ceph_lock.
+	 * Replies for a directory are applied one at a time in any
+	 * case, so serializing their fills loses nothing, while fills
+	 * for different directories still run in parallel.  i_fill_count
+	 * mirrors the chain and i_fill_wq is woken when the chain
+	 * drains, letting the inline fill path wait for one directory
+	 * only.  Each chained request holds r_dentry, the directory
+	 * dentry, so the inode and its chain cannot go away while fills
+	 * are pending.
+	 *
+	 * s_fill_inflight is bumped while still holding mdsc->mutex,
+	 * pairing with the waits in ceph_handle_caps(), handle_lease(),
+	 * cleanup_session_requests() and remove_session_caps(); the
+	 * inline fill path below waits per directory instead, so fills
+	 * of unrelated directories do not serialize one reply.  A safe
+	 * reply waits for the request's fill on r_fill_waitq
+	 * (CEPH_MDS_R_FILL_OFFLOADED) before unregistering the request.
+	 * Offloading is gated on s_fill_offload_enabled, which is set
+	 * while the session is OPEN and cleared on every transition
+	 * away from OPEN, so reconnect/reset never races an old fill.
+	 */
+	if (req->r_op == CEPH_MDS_OP_READDIR &&
+	    msg->front.iov_len >= 64 * 1024 &&
+	    session->s_fill_offload_enabled && mdsc->fill_wq &&
+	    req->r_dentry) {
+		struct ceph_inode_info *ci = ceph_inode(d_inode(req->r_dentry));
+		bool head;
+
+		atomic_inc(&session->s_fill_inflight);
+		set_bit(CEPH_MDS_R_FILL_OFFLOADED, &req->r_req_flags);
+		req->r_fill_msg = ceph_msg_get(msg);
+		if (test_bit(CEPHFS_FEATURE_REPLY_ENCODING, &session->s_features))
+			req->r_fill_peer_features = (u64)-1;
+		else
+			req->r_fill_peer_features = session->s_con.peer_features;
+		INIT_WORK(&req->r_fill_work, handle_reply_fill_work);
+		spin_lock(&ci->i_ceph_lock);
+		head = list_empty(&ci->i_fill_chain);
+		list_add_tail(&req->r_fill_chain_item, &ci->i_fill_chain);
+		atomic_inc(&ci->i_fill_count);
+		if (head)
+			queue_work(mdsc->fill_wq, &req->r_fill_work);
+		spin_unlock(&ci->i_ceph_lock);
+		mutex_unlock(&mdsc->mutex);
+		return;  /* handle_reply_fill_work() drops our request ref */
+	}
+
+	/*
+	 * Now that all mutex-protected state has been updated above
+	 * (the request has been unregistered or added to the
+	 * session's unsafe list), we can unlock it.
+	 */
+	mutex_unlock(&mdsc->mutex);
+
+	/*
+	 * An offloaded readdir fill may still be mutating the dcache of
+	 * the directory this reply's trace is about to touch; wait only
+	 * for fills of that directory, so that fills of unrelated
+	 * directories do not serialize this reply.  The waiter holds no
+	 * lock the fill work items take, and appends to a directory's
+	 * chain come only from the worker processing that directory's
+	 * session, which is this worker, so no new fill can be appended
+	 * to the chain while we wait here; the queue drains and this
+	 * cannot deadlock.
+	 */
+	if (req->r_dentry || req->r_old_dentry) {
+		struct ceph_inode_info *ci;
+		struct dentry *d;
+
+		if (req->r_dentry) {
+			d = (req->r_op == CEPH_MDS_OP_READDIR) ?
+				req->r_dentry : req->r_dentry->d_parent;
+			ci = ceph_inode(d_inode(d));
+			wait_event(ci->i_fill_wq,
+				   !atomic_read(&ci->i_fill_count));
+		}
+		if (req->r_old_dentry) {
+			struct inode *dir = req->r_old_dentry_dir ?
+				req->r_old_dentry_dir :
+				d_inode(req->r_old_dentry->d_parent);
+			ci = ceph_inode(dir);
+			wait_event(ci->i_fill_wq,
+				   !atomic_read(&ci->i_fill_count));
+		}
+	} else if (req->r_inode) {
+		/*
+		 * Dentry-less replies (getattr, setattr, ...) only update
+		 * the target inode's caps, which a pending fill can touch
+		 * only if the target is itself a directory being filled
+		 * (its own chain, waited below) or an entry of one; in
+		 * the latter case ceph_add_cap()'s stale-sequence check
+		 * keeps the newer state, so an entry-level race is
+		 * harmless.
+		 */
+		struct ceph_inode_info *ci = ceph_inode(req->r_inode);
+
+		wait_event(ci->i_fill_wq, !atomic_read(&ci->i_fill_count));
+	} else {
+		wait_event(session->s_fill_wq,
+			   !atomic_read(&session->s_fill_inflight));
+	}
+
+	close_sessions = handle_reply_fill(session, msg, req, false);
 out:
+	/* drop the ref taken in lookup_get_request() */
 	ceph_mdsc_put_request(req);
 
-	/* Defer closing the sessions after s_mutex lock being released */
+	/*
+	 * Defer closing the sessions until after the request ref is
+	 * dropped and, on the offloaded path, after the fill barrier is
+	 * released (see the comment above handle_reply_fill()).
+	 */
 	if (close_sessions)
 		ceph_mdsc_close_sessions(mdsc);
-	return;
 }
 
 
@@ -4591,6 +4904,7 @@ static void handle_session(struct ceph_mds_session *session,
 
 	if (session->s_state == CEPH_MDS_SESSION_HUNG) {
 		session->s_state = CEPH_MDS_SESSION_OPEN;
+		ceph_mdsc_set_fill_offload(session, true);
 		pr_info_client(cl, "mds%d came back\n", session->s_mds);
 	}
 
@@ -4610,6 +4924,7 @@ static void handle_session(struct ceph_mds_session *session,
 					 session->s_mds);
 		} else {
 			session->s_state = CEPH_MDS_SESSION_OPEN;
+			ceph_mdsc_set_fill_offload(session, true);
 			renewed_caps(mdsc, session, 0);
 			if (test_bit(CEPHFS_FEATURE_METRIC_COLLECT,
 				     &session->s_features))
@@ -4639,6 +4954,7 @@ static void handle_session(struct ceph_mds_session *session,
 			pr_info_client(cl, "mds%d reconnect denied\n",
 				       session->s_mds);
 		session->s_state = CEPH_MDS_SESSION_CLOSED;
+		ceph_mdsc_set_fill_offload(session, false);
 		cleanup_session_requests(mdsc, session);
 		remove_session_caps(session);
 		wake = 2; /* for good measure */
@@ -4685,6 +5001,7 @@ static void handle_session(struct ceph_mds_session *session,
 			pr_info_client(cl, "mds%d rejected session\n",
 				       session->s_mds);
 		session->s_state = CEPH_MDS_SESSION_REJECTED;
+		ceph_mdsc_set_fill_offload(session, false);
 		cleanup_session_requests(mdsc, session);
 		remove_session_caps(session);
 		if (blocklisted)
@@ -5219,6 +5536,7 @@ static int send_mds_reconnect(struct ceph_mds_client *mdsc,
 	pr_info_client(cl, "mds%d reconnect start\n", mds);
 	old_state = session->s_state;
 	session->s_state = CEPH_MDS_SESSION_RECONNECTING;
+	ceph_mdsc_set_fill_offload(session, false);
 	session->s_seq = 0;
 
 	doutc(cl, "session %p state %s\n", session,
@@ -5769,6 +6087,7 @@ static void ceph_mdsc_reset_workfn(struct work_struct *work)
 			continue;
 		}
 		sessions[i]->s_state = CEPH_MDS_SESSION_CLOSED;
+		sessions[i]->s_fill_offload_enabled = false;
 		__unregister_session(mdsc, sessions[i]);
 		__wake_requests(mdsc, &sessions[i]->s_waiting);
 		mutex_unlock(&mdsc->mutex);
@@ -5927,6 +6246,7 @@ static void check_new_map(struct ceph_mds_client *mdsc,
 			ceph_con_close(&s->s_con);
 			mutex_unlock(&s->s_mutex);
 			s->s_state = CEPH_MDS_SESSION_RESTARTING;
+			s->s_fill_offload_enabled = false;
 		} else if (oldstate == newstate) {
 			continue;  /* nothing new with this mds */
 		}
@@ -6074,6 +6394,16 @@ static void handle_lease(struct ceph_mds_client *mdsc,
 	if (!ceph_inc_mds_stopping_blocker(mdsc, session))
 		return;
 
+	/*
+	 * Offloaded readdir fills may still be updating dentry leases
+	 * (ceph_readdir_prepopulate() runs without session->s_mutex);
+	 * wait for any earlier offloaded reply fills to finish before
+	 * applying the lease message, preserving the ordering that the
+	 * old inline reply handling provided.  Same deadlock argument
+	 * as ceph_handle_caps().
+	 */
+	wait_event(session->s_fill_wq, !atomic_read(&session->s_fill_inflight));
+
 	/* decode */
 	if (msg->front.iov_len < sizeof(*h) + sizeof(u32))
 		goto bad;
@@ -6231,6 +6561,8 @@ bool check_session_state(struct ceph_mds_session *s)
 	case CEPH_MDS_SESSION_OPEN:
 		if (s->s_ttl && time_after(jiffies, s->s_ttl)) {
 			s->s_state = CEPH_MDS_SESSION_HUNG;
+			/* caller holds mdsc->mutex */
+			s->s_fill_offload_enabled = false;
 			pr_info_client(cl, "mds%d hung\n", s->s_mds);
 		}
 		break;
@@ -6425,6 +6757,12 @@ int ceph_mdsc_init(struct ceph_fs_client *fsc)
 	strscpy(mdsc->nodename, utsname()->nodename,
 		sizeof(mdsc->nodename));
 
+	mdsc->fill_wq = alloc_workqueue("ceph-fill", WQ_UNBOUND, 0);
+	if (!mdsc->fill_wq) {
+		err = -ENOMEM;
+		goto err_mdsmap;
+	}
+
 	fsc->mdsc = mdsc;
 	return 0;
 
@@ -6690,6 +7028,10 @@ void ceph_mdsc_pre_umount(struct ceph_mds_client *mdsc)
 	 */
 	ceph_msgr_flush();
 
+	/* wait for offloaded reply fills to finish */
+	if (mdsc->fill_wq)
+		flush_workqueue(mdsc->fill_wq);
+
 	ceph_cleanup_quotarealms_inodes(mdsc);
 	doutc(mdsc->fsc->client, "done\n");
 }
@@ -6911,6 +7253,9 @@ static void ceph_mdsc_stop(struct ceph_mds_client *mdsc)
 	 */
 	flush_delayed_work(&mdsc->delayed_work);
 
+	if (mdsc->fill_wq)
+		destroy_workqueue(mdsc->fill_wq);
+
 	if (mdsc->mdsmap)
 		ceph_mdsmap_destroy(mdsc->mdsmap);
 	kfree(mdsc->sessions);
@@ -7189,6 +7534,7 @@ static void mds_peer_reset(struct ceph_connection *con)
 
 		ceph_get_mds_session(s);
 		s->s_state = CEPH_MDS_SESSION_CLOSED;
+		s->s_fill_offload_enabled = false;
 		__unregister_session(mdsc, s);
 		__wake_requests(mdsc, &s->s_waiting);
 		mutex_unlock(&mdsc->mutex);
diff --git a/fs/ceph/mds_client.h b/fs/ceph/mds_client.h
index e7a262c9c2ab..1973616b889c 100644
--- a/fs/ceph/mds_client.h
+++ b/fs/ceph/mds_client.h
@@ -299,6 +299,11 @@ struct ceph_mds_session {
 
 	struct list_head  s_waiting;  /* waiting requests */
 	struct list_head  s_unsafe;   /* unsafe requests */
+	atomic_t          s_fill_inflight; /* reply fills offloaded from the mds worker */
+	wait_queue_head_t s_fill_wq;
+	bool s_fill_offload_enabled; /* readdir reply fills may be offloaded;
+				      * protected by mdsc->mutex
+				      */
 	struct xarray	  s_delegated_inos;
 	atomic_t	  s_num_deleg_inos;
 };
@@ -360,6 +365,9 @@ struct ceph_mds_request {
 #define CEPH_MDS_R_PARENT_LOCKED	(7) /* is r_parent->i_rwsem wlocked? */
 #define CEPH_MDS_R_ASYNC		(8) /* async request */
 #define CEPH_MDS_R_FSCRYPT_FILE		(9) /* must marshal fscrypt_file field */
+#define CEPH_MDS_R_FILL_OFFLOADED	(10) /* reply fill runs on fill_wq;
+					      * the safe reply waits for it
+					      */
 	unsigned long	r_req_flags;
 
 	struct mutex r_fill_mutex;
@@ -398,6 +406,13 @@ struct ceph_mds_request {
 	int r_err;
 	u32               r_readdir_offset;
 
+	/* readdir reply fill offloaded from the mds connection worker */
+	struct work_struct r_fill_work;
+	struct ceph_msg  *r_fill_msg;         /* owned by the fill work */
+	u64               r_fill_peer_features;
+	struct list_head  r_fill_chain_item;  /* link in i_fill_chain */
+	wait_queue_head_t r_fill_waitq;	  /* safe reply waits for the fill */
+
 	struct page *r_locked_page;
 	int r_dir_caps;
 	int r_num_caps;
@@ -502,6 +517,7 @@ struct ceph_mds_client {
 	struct ceph_mds_session **sessions;    /* NULL for mds if no session */
 	atomic_t		num_sessions;
 	int                     max_sessions;  /* len of sessions array */
+	struct workqueue_struct *fill_wq;      /* offloaded reply fills */
 
 	spinlock_t              stopping_lock;  /* protect snap_empty */
 	int                     stopping;      /* the stage of shutting down */
diff --git a/fs/ceph/super.h b/fs/ceph/super.h
index a8dff65701e2..b9c3ec3828c5 100644
--- a/fs/ceph/super.h
+++ b/fs/ceph/super.h
@@ -402,6 +402,13 @@ struct ceph_inode_info {
 #endif
 
 	spinlock_t i_ceph_lock;
+	/* offloaded readdir reply fills pending on this directory, in MDS
+	 * reply order; at most one runs at a time.  Protected by
+	 * i_ceph_lock.
+	 */
+	struct list_head i_fill_chain;
+	atomic_t i_fill_count;	/* number of fills on i_fill_chain */
+	wait_queue_head_t i_fill_wq;  /* woken when i_fill_count hits zero */
 
 	u32 i_time_warp_seq;
 	u64 i_version;

---
base-commit: dee30ce1286a0d18b14545ecac345e4cf4a80511
change-id: 20260902-b4-offload-readdir-reply-fill-f0e4add06ad1

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

