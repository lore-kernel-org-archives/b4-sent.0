From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 23 Oct 2026 11:10:24 +0900
Subject: [PATCH v2 3/4] nfsd: send a referring call with CB_LAYOUTRECALL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-nfsd-layout-refcall-v2-3-2160bddced0c@samsung.com>
References: <20261023-nfsd-layout-refcall-v2-0-2160bddced0c@samsung.com>
In-Reply-To: <20261023-nfsd-layout-refcall-v2-0-2160bddced0c@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792721421; l=22342;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=voIaMoPPEJ6mUDG8syI4kVqrUYwpTIi1NAj00iJlEfY=;
 b=hUUEe4y6gHyFCSpYVQadakJy+SWkP9L4szPxlYZKdjPbHsqy1kqoBzTf2pFQRj4tnNrxJIv9P
 865m+Qkhz3vCnRpwn3JdjR4ksicb83MxvkMdLV9ssmARq6Cmavy4XXQ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The previous patch resends a layout recall once when the client answers
NFS4ERR_NOMATCHING_LAYOUT before it can have processed the reply to a
LAYOUTGET, which covers a client that takes the reply in within two
seconds. RFC 8881 section 2.10.6.3 has the server name the requests that
created the state in the referring call list of the callback instead,
so that the client can hold the callback back until it has processed
the reply, and section 12.5.5.2.1, which is about this race, lets the
server name the LAYOUTGET in a CB_LAYOUTRECALL. Commit 4f3c8d8c9e10
("NFSD: Implement CB_SEQUENCE referring call lists") added the lists,
noting that layout recalls need them, and "NFSD: Send referring calls
with CB_RECALL" [1] uses them for delegations.

Do the same for layouts: nfsd4_cb_layout_prepare() names each LAYOUTGET
that the previous patch has on record as a referring call, which are
those whose slots the client had not retired when the recall was sent.
The resend keeps the list without testing the slots again: a client
that has not processed a reply yet holds the recall back, and one that
has finds the call complete. The Linux client holds a callback back
with "NFSv4.1: Return NFS4ERR_DELAY when a referring call wait times
out" [2]. Without that, it waits half a second for the LAYOUTGET, then
answers as before, and the resend still covers it when it takes the
reply in within about three seconds: half a second of waiting, the two
second delay, and half a second again.

NFS4_enc_cb_layout_sz, from which the RPC client sizes the request
buffer, has room for one referring call. Each record can come from a
session of its own, so make room for NFSD4_LAYOUT_MAX_GRANTS referring
calls, each in a list of its own.

nfsd41_cb_referring_call() leaves a referring call out when it cannot
allocate memory for it. Have it and nfsd41_cb_referring_grant() say so.
A client cannot hold back a recall that does not name the LAYOUTGET, so
for such a recall ->done does not trust NFS4ERR_NOMATCHING_LAYOUT while
a record was left at the send. It sends the recall again every two
seconds until the client answers otherwise, the last layout is
returned, the fence worker of the lease break has run, or two lease
periods have passed since the first answer as for the polls, and then
fences the client if layouts are left. The test for the end of the
polls and the fencing move into helpers for that.

A client that holds the recall back answers CB_SEQUENCE with
NFS4ERR_DELAY, which nfsd4_cb_sequence_done() retries every two seconds
without calling ->done, so the limit of two lease periods in
nfsd4_cb_layout_done() does not apply: the recall lasts until the client
has processed the reply, and every LAYOUTGET for the file fails
meanwhile. A lease break still has the client fenced after
fs.lease-break-time.

This needs the referring call lists, which are in v6.16, and [1], which
is queued for v7.4. It should not go to kernels without
commit f52792f484ba ("NFSD: Enforce timeout on layout recall and
integrate lease manager fencing"), which is in v7.1: a client that holds
the recall back with NFS4ERR_DELAY while it takes the layout in can need
a GETDEVICEINFO for that, and before v7.1 a lease break that holds every
nfsd thread does not give up, so that GETDEVICEINFO would never be
served. From v7.1 on, that case stalls the server for the client until
fs.lease-break-time and then has the client fenced, where the client
would have lost the data before; with "nfsd: answer NFS4ERR_DELAY
instead of waiting for a layout recall", which is on nfsd-testing, a
WRITE or SETATTR no longer waits for a layout recall, which leaves that
case to a LAYOUTGET that completes between that patch's check and the
recall in XFS, and to the kthread of an asynchronous COPY.

A pynfs test (not posted) has one client take two layouts of one layout
stateid with LAYOUTGETs on two slots and send nothing more on either,
and another client cause a recall: the CB_SEQUENCE names both
LAYOUTGETs in each of five runs.

With the test of the previous patch and its one second delay, this patch
lost no block (20 and 28 blocks, the recall overtaking the reply 8 and 4
times). With [2] on the client and the next patch as well, which does
not act in this test as the lease breaks come from the other client, no
recall was processed before the client had taken the LAYOUTGET reply in
(22 and 24 blocks). With a delay of four seconds, longer than the resend
covers, a client without [2] loses every block whose reply the recall
overtakes, with this patch as with the previous one: 15 of 15 in each of
two runs here, 8 of 15 in each with the previous patch alone, where each
such recall is about a second shorter and the NFSv4.0 client was done
after 31.5 and 31.2 seconds, so later blocks met no recall. With [2] and
the whole series, none (11 and 7 blocks). For a client without [2], this
patch saves the two second resend when the client processes the reply
within half a second, and the data when it does so in two to about three
seconds; it adds half a second to each such recall when the client takes
half a second to two seconds, as in the test above, and a second when it
takes longer than about three seconds.

The cost is on the writer that breaks the lease. A recall that names a
LAYOUTGET the client has not processed within half a second now lasts at
least two and a half seconds: half a second of waiting on the client,
then the two second delay before nfsd sends the callback again, after
NFS4ERR_DELAY in CB_SEQUENCE with [2] or as the resend without it.
WRITEs through the metadata server get NFS4ERR_DELAY meanwhile. With the
one second delay, the NFSv4.0 client wrote all its 600 blocks in 35.8
and 25.2 seconds with this patch, against 14.6 and 15.0 seconds without
the series and 21.2 and 20.9 seconds with the previous patch alone. It
needs about 15 seconds plus two and a half seconds for each recall that
meets an unprocessed reply, two with the previous patch alone; there
were 8 and 4 such recalls here and 3 and 3 with the previous patch. How
many there are varies between runs of the same code: with the whole
series, which behaves the same in this test, there were 23 and 24, and
the NFSv4.0 client wrote 62 and 9 blocks in a minute.

With a test-only switch that makes every referring call fail and the
four second delay in a client without [2], the client lost none of its
15 blocks in each of two runs, although every recall overtook the reply;
the previous patch alone, which trusts the answer to the resend, lost 8
of 15 in each. A failed allocation costs the writer instead: the NFSv4.0
client wrote 18 and 14 blocks in a minute. In the test of the previous
patch, where the reading client reads the file again 20 seconds after
its first read, the switch kept the recall going for two lease periods
although that client answered NFS4ERR_NOMATCHING_LAYOUT 89 times: the
write ended 203.9 seconds after the first read and the second read 200.1
seconds after it, as every LAYOUTGET for the file failed meanwhile, and
the recall ended in the fence path although the client held no layout.

Link: https://lore.kernel.org/r/20260802-nfsd-deleg-destroy-badhandle-v1-9-323aa7196055@kernel.org # [1]
Link: https://lore.kernel.org/r/20261020-nfs-referring-call-delay-v1-1-0be8f0608f7c@samsung.com # [2]
Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4callback.c |  13 ++--
 fs/nfsd/nfs4layouts.c  | 163 ++++++++++++++++++++++++++++++++-----------------
 fs/nfsd/nfs4state.c    |  11 ++--
 fs/nfsd/state.h        |  16 +++--
 fs/nfsd/xdr4cb.h       |   6 +-
 5 files changed, 140 insertions(+), 69 deletions(-)

diff --git a/fs/nfsd/nfs4callback.c b/fs/nfsd/nfs4callback.c
index 70ab4fd321..6edf53be25 100644
--- a/fs/nfsd/nfs4callback.c
+++ b/fs/nfsd/nfs4callback.c
@@ -1471,14 +1471,16 @@ static void nfsd41_destroy_cb(struct nfsd4_callback *cb)
  *
  * Caller serializes access to @cb.
  *
- * NB: If memory allocation fails, the referring call is not added.
+ * Return: true if @cb names the referring call, false if memory
+ * allocation failed and the referring call was not added.
  */
-void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
+bool nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 			      struct nfs4_sessionid *sessionid,
 			      u32 slotid, u32 seqno)
 {
 	struct nfsd4_referring_call_list *rcl;
 	struct nfsd4_referring_call *rc;
+	bool added = true;
 	bool found;
 
 	might_sleep();
@@ -1494,7 +1496,7 @@ void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 	if (!found) {
 		rcl = kmalloc_obj(*rcl);
 		if (!rcl)
-			return;
+			return false;
 		memcpy(rcl->rcl_sessionid.data, sessionid->data,
 		       NFS4_MAX_SESSIONID_LEN);
 		rcl->__nr_referring_calls = 0;
@@ -1512,8 +1514,10 @@ void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 	}
 	if (!found) {
 		rc = kmalloc_obj(*rc);
-		if (!rc)
+		if (!rc) {
+			added = false;
 			goto out;
+		}
 		rc->rc_sequenceid = seqno;
 		rc->rc_slotid = slotid;
 		rcl->__nr_referring_calls++;
@@ -1526,6 +1530,7 @@ void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 		list_del(&rcl->__list);
 		kfree(rcl);
 	}
+	return added;
 }
 
 /**
diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index fdce9ddeba..7a0353149e 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -257,6 +257,8 @@ nfsd4_free_layout_stateid(struct nfs4_stid *stid)
 
 	list_for_each_entry_safe(lg, next, &ls->ls_grants, lg_list)
 		kfree(lg);
+	/* The list outlives one send of the recall. */
+	nfsd41_cb_destroy_referring_call_list(&ls->ls_recall);
 	kmem_cache_free(nfs4_layout_stateid_cache, ls);
 }
 
@@ -944,6 +946,8 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 {
 	struct nfs4_layout_stateid *ls =
 		container_of(cb, struct nfs4_layout_stateid, ls_recall);
+	struct nfs4_client *clp = ls->ls_stid.sc_client;
+	struct nfsd4_layout_grant *lg;
 
 	mutex_lock(&ls->ls_mutex);
 	nfs4_inc_and_copy_stateid(&ls->ls_recall_sid, &ls->ls_stid);
@@ -954,6 +958,22 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 	 */
 	nfsd4_prune_layout_grants(ls);
 	ls->ls_recall_retired_at_send = list_empty(&ls->ls_grants);
+
+	/*
+	 * The recall can reach the client before the reply to a LAYOUTGET
+	 * that handed out a layout. Name each LAYOUTGET whose slot has not
+	 * retired as a referring call (RFC 8881 section 2.10.6.3), so that
+	 * a client that honors them holds the recall back instead of
+	 * answering NFS4ERR_NOMATCHING_LAYOUT. ->prepare runs once per
+	 * recall; the list stays for the polls and the resend that follow
+	 * and is freed with @ls.
+	 */
+	ls->ls_recall_unnamed = false;
+	list_for_each_entry(lg, &ls->ls_grants, lg_list) {
+		if (!nfsd41_cb_referring_grant(&ls->ls_recall, clp,
+					       &lg->lg_slot))
+			ls->ls_recall_unnamed = true;
+	}
 	mutex_unlock(&ls->ls_mutex);
 	ls->ls_recall_accepted = false;
 	ls->ls_recall_resent = false;
@@ -970,15 +990,63 @@ static bool nfsd4_layout_fenced(struct nfs4_layout_stateid *ls)
 	return fenced;
 }
 
+/*
+ * Client gets 2 lease periods to return its layouts, counted from its
+ * first answer: the first call starts the clock. task->tk_start is reset
+ * each time the RPC task is restarted, so it cannot anchor the limit.
+ */
+static bool
+nfsd4_layout_recall_expired(struct nfs4_layout_stateid *ls)
+{
+	struct nfsd_net *nn = net_generic(ls->ls_stid.sc_client->net,
+					  nfsd_net_id);
+	ktime_t now = ktime_get_boottime();
+
+	if (!ls->ls_recall_start)
+		ls->ls_recall_start = now;
+	return !ktime_before(now, ktime_add_ns(ls->ls_recall_start,
+				(u64)nn->nfsd4_lease * NSEC_PER_SEC * 2));
+}
+
+static void
+nfsd4_cb_layout_give_up(struct nfs4_layout_stateid *ls)
+{
+	const struct nfsd4_layout_ops *ops;
+	struct nfsd_file *fl;
+
+	/*
+	 * Nothing to fence for once the layouts are gone: a
+	 * LAYOUTRETURN can return the last one while the recall is
+	 * still out.
+	 */
+	if (list_empty(&ls->ls_layouts)) {
+		trace_nfsd_layout_recall_done(&ls->ls_stid.sc_stateid);
+		return;
+	}
+	/*
+	 * Unknown error or non-responding client, we'll need to fence.
+	 */
+	trace_nfsd_layout_recall_fail(&ls->ls_stid.sc_stateid);
+	if (nfsd4_layout_fenced(ls))
+		return;
+	rcu_read_lock();
+	fl = nfsd_file_get(ls->ls_file);
+	rcu_read_unlock();
+	if (fl) {
+		ops = nfsd4_layout_ops[ls->ls_layout_type];
+		if (ops->fence_client)
+			ops->fence_client(ls, fl);
+		else
+			nfsd4_cb_layout_fail(ls, fl);
+		nfsd_file_put(fl);
+	}
+}
+
 static int
 nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 {
 	struct nfs4_layout_stateid *ls =
 		container_of(cb, struct nfs4_layout_stateid, ls_recall);
-	struct nfsd_net *nn;
-	ktime_t now, cutoff;
-	const struct nfsd4_layout_ops *ops;
-	struct nfsd_file *fl;
 
 	trace_nfsd_cb_layout_done(&ls->ls_stid.sc_stateid, task);
 	switch (task->tk_status) {
@@ -1021,77 +1089,60 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		}
 
 		/* Poll the client until it's done with the layout */
-		now = ktime_get_boottime();
-		nn = net_generic(ls->ls_stid.sc_client->net, nfsd_net_id);
-
-		/*
-		 * Client gets 2 lease periods to return it, counted from its
-		 * first answer. task->tk_start is reset each time the RPC task
-		 * is restarted, so it cannot anchor the limit.
-		 */
-		if (!ls->ls_recall_start)
-			ls->ls_recall_start = now;
-		cutoff = ktime_add_ns(ls->ls_recall_start,
-				      (u64)nn->nfsd4_lease * NSEC_PER_SEC * 2);
-
-		if (ktime_before(now, cutoff)) {
+		if (!nfsd4_layout_recall_expired(ls)) {
 			rpc_delay(task, HZ/100); /* 10 mili-seconds */
 			return 0;
 		}
 		fallthrough;
 	default:
-		/*
-		 * Nothing to fence for once the layouts are gone: a
-		 * LAYOUTRETURN can return the last one while the recall is
-		 * still out.
-		 */
-		if (list_empty(&ls->ls_layouts)) {
-			trace_nfsd_layout_recall_done(&ls->ls_stid.sc_stateid);
-			return 1;
-		}
-		/*
-		 * Unknown error or non-responding client, we'll need to fence.
-		 */
-		trace_nfsd_layout_recall_fail(&ls->ls_stid.sc_stateid);
-		if (nfsd4_layout_fenced(ls))
-			return 1;
-		rcu_read_lock();
-		fl = nfsd_file_get(ls->ls_file);
-		rcu_read_unlock();
-		if (fl) {
-			ops = nfsd4_layout_ops[ls->ls_layout_type];
-			if (ops->fence_client)
-				ops->fence_client(ls, fl);
-			else
-				nfsd4_cb_layout_fail(ls, fl);
-			nfsd_file_put(fl);
-		}
+		nfsd4_cb_layout_give_up(ls);
 		return 1;
 	case -NFS4ERR_NOMATCHING_LAYOUT:
 		/*
-		 * The recall can reach the client before the reply to a
-		 * LAYOUTGET that added a layout, and a client that has not
-		 * processed that reply answers this way too. As the
-		 * delegation code does for NFS4ERR_BAD_STATEID, trust the
-		 * answer if the slots of the LAYOUTGETs had retired when the
-		 * recall was sent, and send the recall once more after a
-		 * delay otherwise. Unlike the delegation code, trust the
-		 * answer to that resend: not trusting it would end in fencing
-		 * the client, and an idle client leaves its slot unretired
-		 * also when it has no layout. A client that has not
-		 * processed the reply by the resend still has its layout
+		 * A client that has not processed the reply to a LAYOUTGET
+		 * named as referring call answers this way too: one that
+		 * ignores referring calls, and one that gives up waiting for
+		 * the LAYOUTGET. As the delegation code does for
+		 * NFS4ERR_BAD_STATEID, trust the answer if the slots of the
+		 * LAYOUTGETs had retired when the recall was sent, and send
+		 * the recall once more after a delay otherwise. Unlike the
+		 * delegation code, trust the answer to that resend: not
+		 * trusting it would end in fencing the client, and an idle
+		 * client leaves its slot unretired also when it has no
+		 * layout. A client that neither holds the recall back nor
+		 * processes the reply before the resend still has its layout
 		 * dropped. A client that has answered NFS4_OK to this recall
 		 * knew the layout stateid, so its answer to a poll is trusted
 		 * at once.
 		 *
+		 * When memory ran out in ->prepare and a LAYOUTGET is not
+		 * named, the client has no way to hold the recall back, and
+		 * its answers are not trusted: the recall is sent again every
+		 * two seconds until the client answers otherwise, the last
+		 * layout is returned, the fence worker of the lease break has
+		 * run or the recall times out.
+		 *
 		 * The resend repeats the request with its seqid, as the polls
 		 * do, although RFC 8881 section 12.5.3 has a new one for each
 		 * request: a client that did not take the request in expects
 		 * that seqid next, and a client that did answers
 		 * NFS4ERR_OLD_STATEID, which the polls handle.
+		 *
+		 * Unlike the delegation code, ->done does not test the slots
+		 * again, as ls_grants needs ls_mutex: a referring call that
+		 * has completed by the resend is harmless, as the client finds
+		 * it complete, but a recall that could not name a LAYOUTGET is
+		 * not trusted even after its slots retire.
 		 */
 		if (!list_empty(&ls->ls_layouts) && !ls->ls_recall_accepted &&
-		    !ls->ls_recall_retired_at_send && !ls->ls_recall_resent) {
+		    !ls->ls_recall_retired_at_send &&
+		    (!ls->ls_recall_resent || ls->ls_recall_unnamed)) {
+			if (ls->ls_recall_unnamed &&
+			    (nfsd4_layout_fenced(ls) ||
+			     nfsd4_layout_recall_expired(ls))) {
+				nfsd4_cb_layout_give_up(ls);
+				return 1;
+			}
 			ls->ls_recall_resent = true;
 			trace_nfsd_layout_recall_resend(&ls->ls_recall_sid);
 			rpc_delay(task, 2 * HZ);
diff --git a/fs/nfsd/nfs4state.c b/fs/nfsd/nfs4state.c
index 735eaa4b7f..36fa7259b1 100644
--- a/fs/nfsd/nfs4state.c
+++ b/fs/nfsd/nfs4state.c
@@ -6329,18 +6329,21 @@ bool nfsd41_grant_slot_retired(struct nfs4_client *clp,
  *
  * Context: May sleep. Caller serializes access to @cb, as for
  * nfsd41_cb_referring_call().
+ *
+ * Return: false if memory allocation failed and @cb does not name the
+ * request, true otherwise.
  */
-void nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
+bool nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
 			       struct nfs4_client *clp,
 			       const struct nfsd4_grant_slot *grant)
 {
 	struct nfsd4_sessionid sid;
 
 	if (!grant->valid)
-		return;
+		return true;
 	nfsd41_grant_slot_sessionid(clp, grant, &sid);
-	nfsd41_cb_referring_call(cb, (struct nfs4_sessionid *)&sid,
-				 grant->slotid, grant->seqid);
+	return nfsd41_cb_referring_call(cb, (struct nfs4_sessionid *)&sid,
+					grant->slotid, grant->seqid);
 }
 
 static bool nfsd4_recall_grant_slot_retired(struct nfs4_delegation *dp)
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index b3338cf171..5cf3a5ac46 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -854,7 +854,12 @@ struct nfsd4_layout_grant {
 	struct nfsd4_grant_slot		lg_slot;
 };
 
-/* The most LAYOUTGETs that a layout stateid keeps records of */
+/*
+ * The most LAYOUTGETs that a layout stateid keeps records of. A layout
+ * recall names each as a referring call, and the CB_LAYOUTRECALL request
+ * (NFS4_enc_cb_layout_sz) has room for this many, each in a referring
+ * call list of its own.
+ */
 #define NFSD4_LAYOUT_MAX_GRANTS		8
 
 struct nfs4_layout_stateid {
@@ -877,12 +882,15 @@ struct nfs4_layout_stateid {
 	 * layout to this layout stateid or merged into one, and whose
 	 * slots had not retired when last looked at. Under ls_mutex.
 	 * Until a slot retires, the client may not have processed the reply
-	 * to the LAYOUTGET it carried.
+	 * to the LAYOUTGET it carried, and a recall names the LAYOUTGET as a
+	 * referring call (RFC 8881 section 2.10.6.3).
 	 */
 	struct list_head		ls_grants;
 	/* Recall state for ->done, reset in ->prepare */
 	bool				ls_recall_retired_at_send;
 	bool				ls_recall_resent;
+	/* The recall could not name a LAYOUTGET in ls_grants */
+	bool				ls_recall_unnamed;
 
 	struct delayed_work		ls_fence_work;
 	struct mutex			ls_fence_mutex; /* serializes fence shutdown */
@@ -968,7 +976,7 @@ extern __be32 nfs4_check_open_reclaim(struct nfs4_client *);
 extern void nfsd4_probe_callback(struct nfs4_client *clp);
 extern void nfsd4_probe_callback_sync(struct nfs4_client *clp);
 extern void nfsd4_change_callback(struct nfs4_client *clp, struct nfs4_cb_conn *);
-extern void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
+extern bool nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 				     struct nfs4_sessionid *sessionid,
 				     u32 slotid, u32 seqno);
 extern void nfsd41_cb_destroy_referring_call_list(struct nfsd4_callback *cb);
@@ -976,7 +984,7 @@ extern void nfsd41_record_grant_slot(struct nfsd4_grant_slot *grant,
 				     const struct nfsd4_compound_state *cstate);
 extern bool nfsd41_grant_slot_retired(struct nfs4_client *clp,
 				      const struct nfsd4_grant_slot *grant);
-extern void nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
+extern bool nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
 				      struct nfs4_client *clp,
 				      const struct nfsd4_grant_slot *grant);
 extern void nfsd4_init_cb(struct nfsd4_callback *cb, struct nfs4_client *clp,
diff --git a/fs/nfsd/xdr4cb.h b/fs/nfsd/xdr4cb.h
index 838f862982..514404d2e1 100644
--- a/fs/nfsd/xdr4cb.h
+++ b/fs/nfsd/xdr4cb.h
@@ -25,8 +25,12 @@
 #define NFS4_dec_cb_recall_sz		(cb_compound_dec_hdr_sz  +      \
 					cb_sequence_dec_sz +            \
 					op_dec_sz)
+/* NFSD4_LAYOUT_MAX_GRANTS referring calls, each in a list of its own */
+#define cb_layout_sequence_enc_sz	(cb_sequence_enc_sz +		\
+					(NFSD4_LAYOUT_MAX_GRANTS - 1) *	\
+					enc_referring_call_list4_sz)
 #define NFS4_enc_cb_layout_sz		(cb_compound_enc_hdr_sz +       \
-					cb_sequence_enc_sz +            \
+					cb_layout_sequence_enc_sz +     \
 					op_enc_sz + 3 + 1 +             \
 					enc_nfs4_fh_sz + 4 +            \
 					enc_stateid_sz)

-- 
2.43.0

