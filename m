From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 21 Oct 2026 10:03:03 +0900
Subject: [PATCH 1/4] nfsd: share the grant slot record between delegations
 and layouts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261021-nfsd-layout-refcall-v1-1-797096b92377@samsung.com>
References: <20261021-nfsd-layout-refcall-v1-0-797096b92377@samsung.com>
In-Reply-To: <20261021-nfsd-layout-refcall-v1-0-797096b92377@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792544582; l=10984;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=QxHRB7614mP6+oETtTBuCFRB1KVGlQKvj8Q12/DfSdI=;
 b=eKim2/0cJbVCijvaBHTQfuyw/RRyVLn9IZvHZ7bpaa1a+B6KPv0UmgFwr7mK7AZ3GcZImktni
 ylRI18fak0CChCTj1q4GrhhmU7Nc7D2dDt4IQ8tgNXCVTtepODp/UgJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The delegation code remembers the forward-channel slot that carried the
request that granted a delegation (dl_recall_grant), tests whether the
client has retired that slot since (nfsd4_recall_grant_slot_retired()),
and names the request as a referring call in the CB_SEQUENCE of a
recall. The next two patches need the same for layouts.

Make the record a type of its own, struct nfsd4_grant_slot, and move the
code that fills it in, the slot test and the code that adds the
referring call into nfsd41_record_grant_slot(),
nfsd41_grant_slot_retired() and nfsd41_cb_referring_grant(), named for
the session machinery they depend on. The flag that was part of the
delegation's record stays with the delegation, as
dl_recall_retired_at_send.

No change in behavior.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4state.c | 115 ++++++++++++++++++++++++++++++++++++----------------
 fs/nfsd/state.h     |  24 +++++++----
 2 files changed, 96 insertions(+), 43 deletions(-)

diff --git a/fs/nfsd/nfs4state.c b/fs/nfsd/nfs4state.c
index f2b52ba901..735eaa4b7f 100644
--- a/fs/nfsd/nfs4state.c
+++ b/fs/nfsd/nfs4state.c
@@ -1291,7 +1291,7 @@ __alloc_init_deleg(struct nfs4_client *clp, struct nfs4_file *fp,
 	dp->dl_recalled = false;
 	dp->dl_recall_rejected = false;
 	dp->dl_recall_grant.valid = false;
-	dp->dl_recall_grant.retired_at_send = false;
+	dp->dl_recall_retired_at_send = false;
 	get_nfs4_file(fp);
 	dp->dl_stid.sc_file = fp;
 	nfsd4_init_cb(&dp->dl_recall, dp->dl_stid.sc_client,
@@ -6251,37 +6251,49 @@ bool nfsd_wait_for_delegreturn(struct svc_rqst *rqstp, struct inode *inode)
  * gen_sessionid() composes a sessionid from the client's clientid and a
  * sequence counter, so the sequence alone identifies the granting session.
  */
-static void nfsd4_recall_grant_sessionid(const struct nfs4_delegation *dp,
-					 struct nfsd4_sessionid *sid)
+static void nfsd41_grant_slot_sessionid(struct nfs4_client *clp,
+					const struct nfsd4_grant_slot *grant,
+					struct nfsd4_sessionid *sid)
 {
-	sid->clientid = dp->dl_stid.sc_client->cl_clientid;
-	sid->sequence = dp->dl_recall_grant.sessionid_seq;
+	sid->clientid = clp->cl_clientid;
+	sid->sequence = grant->sessionid_seq;
 	sid->reserved = 0;
 }
 
-static bool nfsd4_recall_grant_slot_retired(struct nfs4_delegation *dp)
+/**
+ * nfsd41_grant_slot_retired - has the client seen the reply to a grant?
+ * @clp: client that sent the granting request
+ * @grant: forward-channel slot that carried the request
+ *
+ * Context: Takes nn->client_lock.
+ *
+ * Return: true if the client has gone on to use the slot for a later
+ * request, or has given the slot up, so that it must have received the
+ * reply. False if that cannot be shown, and if @grant is not valid.
+ */
+bool nfsd41_grant_slot_retired(struct nfs4_client *clp,
+			       const struct nfsd4_grant_slot *grant)
 {
-	struct nfs4_client *clp = dp->dl_stid.sc_client;
 	struct nfsd_net *nn = net_generic(clp->net, nfsd_net_id);
 	struct nfsd4_session *ses;
 	struct nfsd4_sessionid sid;
 	bool retired = false;
 	void *entry;
 
-	if (!dp->dl_recall_grant.valid)
+	if (!grant->valid)
 		return false;
 
-	nfsd4_recall_grant_sessionid(dp, &sid);
+	nfsd41_grant_slot_sessionid(clp, grant, &sid);
 
 	/*
-	 * A missing session does not prove the client saw the grant: a
+	 * A missing session does not prove the client saw the reply: a
 	 * DESTROY_SESSION unhashes its own session before the reply to
 	 * that compound is encoded.
 	 */
 	spin_lock(&nn->client_lock);
 	ses = __find_in_sessionid_hashtbl((struct nfs4_sessionid *)&sid,
 					  clp->net);
-	entry = ses ? xa_load(&ses->se_slots, dp->dl_recall_grant.slotid) : NULL;
+	entry = ses ? xa_load(&ses->se_slots, grant->slotid) : NULL;
 	if (xa_is_value(entry)) {
 		/*
 		 * A slot is freed only once the client has acknowledged
@@ -6294,18 +6306,49 @@ static bool nfsd4_recall_grant_slot_retired(struct nfs4_delegation *dp)
 
 		/*
 		 * A reactivated slot was freed and rebuilt, so the same
-		 * acknowledgment applies. The seqid test errs toward
-		 * revoking: a rebuilt slot restarting at seqid 1 matches
-		 * an old grant.
+		 * acknowledgment applies. The seqid test errs toward "not
+		 * retired", the side on which the callers do not take the
+		 * client's answer at once: a rebuilt slot restarting at
+		 * seqid 1 matches an old grant.
 		 */
 		retired = (slot->sl_flags & NFSD4_SLOT_REUSED) ||
 			  ((slot->sl_flags & NFSD4_SLOT_INITIALIZED) &&
-			   slot->sl_seqid != dp->dl_recall_grant.seqid);
+			   slot->sl_seqid != grant->seqid);
 	}
 	spin_unlock(&nn->client_lock);
 	return retired;
 }
 
+/**
+ * nfsd41_cb_referring_grant - name a granting request as referring call
+ * @cb: callback that refers to state the request created
+ * @clp: client that sent the request
+ * @grant: forward-channel slot that carried the request
+ *
+ * Does nothing if @grant is not valid.
+ *
+ * Context: May sleep. Caller serializes access to @cb, as for
+ * nfsd41_cb_referring_call().
+ */
+void nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
+			       struct nfs4_client *clp,
+			       const struct nfsd4_grant_slot *grant)
+{
+	struct nfsd4_sessionid sid;
+
+	if (!grant->valid)
+		return;
+	nfsd41_grant_slot_sessionid(clp, grant, &sid);
+	nfsd41_cb_referring_call(cb, (struct nfs4_sessionid *)&sid,
+				 grant->slotid, grant->seqid);
+}
+
+static bool nfsd4_recall_grant_slot_retired(struct nfs4_delegation *dp)
+{
+	return nfsd41_grant_slot_retired(dp->dl_stid.sc_client,
+					 &dp->dl_recall_grant);
+}
+
 /*
  * ->prepare does not run on every send: nfsd4_run_cb_work() skips it
  * on a requeue, and a retry via rpc_restart_call_prepare() re-enters
@@ -6315,9 +6358,9 @@ static bool nfsd4_recall_grant_slot_retired(struct nfs4_delegation *dp)
  */
 static void nfsd4_refresh_recall_grant(struct nfs4_delegation *dp)
 {
-	dp->dl_recall_grant.retired_at_send =
+	dp->dl_recall_retired_at_send =
 			nfsd4_recall_grant_slot_retired(dp);
-	if (dp->dl_recall_grant.retired_at_send)
+	if (dp->dl_recall_retired_at_send)
 		nfsd41_cb_destroy_referring_call_list(&dp->dl_recall);
 }
 
@@ -6345,15 +6388,9 @@ static bool nfsd4_cb_recall_prepare(struct nfsd4_callback *cb)
 
 	nfsd4_refresh_recall_grant(dp);
 
-	if (dp->dl_recall_grant.valid && !dp->dl_recall_grant.retired_at_send) {
-		struct nfsd4_sessionid sid;
-
-		nfsd4_recall_grant_sessionid(dp, &sid);
-		nfsd41_cb_referring_call(&dp->dl_recall,
-					 (struct nfs4_sessionid *)&sid,
-					 dp->dl_recall_grant.slotid,
-					 dp->dl_recall_grant.seqid);
-	}
+	if (!dp->dl_recall_retired_at_send)
+		nfsd41_cb_referring_grant(&dp->dl_recall, dp->dl_stid.sc_client,
+					  &dp->dl_recall_grant);
 	return true;
 }
 
@@ -6405,7 +6442,7 @@ static int nfsd4_cb_recall_done(struct nfsd4_callback *cb,
 		 * the grant. Trust the rejection only if the slot had
 		 * retired when this recall was sent.
 		 */
-		if (dp->dl_recall_grant.retired_at_send) {
+		if (dp->dl_recall_retired_at_send) {
 			nfsd4_deleg_recall_rejected(dp);
 			return 1;
 		}
@@ -7014,19 +7051,25 @@ static bool nfsd4_want_read_deleg(const struct nfsd4_open *open)
 		OPEN4_SHARE_ACCESS_WANT_READ_DELEG;
 }
 
-static void
-nfs4_delegation_record_grant_slot(struct nfs4_delegation *dp,
-				 const struct nfsd4_compound_state *cstate)
+/**
+ * nfsd41_record_grant_slot - remember the slot that carries a request
+ * @grant: record to fill in
+ * @cstate: compound state of the request
+ *
+ * Leaves @grant alone for a request without a session (NFSv4.0).
+ */
+void nfsd41_record_grant_slot(struct nfsd4_grant_slot *grant,
+			      const struct nfsd4_compound_state *cstate)
 {
 	const struct nfsd4_sessionid *sid;
 
 	if (!cstate->session)
 		return;
 	sid = (struct nfsd4_sessionid *)cstate->session->se_sessionid.data;
-	dp->dl_recall_grant.sessionid_seq = sid->sequence;
-	dp->dl_recall_grant.slotid = cstate->slot->sl_index;
-	dp->dl_recall_grant.seqid = cstate->slot->sl_seqid;
-	dp->dl_recall_grant.valid = true;
+	grant->sessionid_seq = sid->sequence;
+	grant->slotid = cstate->slot->sl_index;
+	grant->seqid = cstate->slot->sl_seqid;
+	grant->valid = true;
 }
 
 static struct nfs4_delegation *
@@ -7135,7 +7178,7 @@ nfs4_set_delegation(struct nfsd4_open *open,
 	 * visible to lease breakers. A conflicting open can drive
 	 * CB_RECALL to completion from that point on.
 	 */
-	nfs4_delegation_record_grant_slot(dp, cstate);
+	nfsd41_record_grant_slot(&dp->dl_recall_grant, cstate);
 
 	if (stp->st_stid.sc_export)
 		dp->dl_stid.sc_export = exp_get(stp->st_stid.sc_export);
@@ -10771,7 +10814,7 @@ nfsd_get_dir_deleg(struct nfsd4_compound_state *cstate,
 	dp = alloc_init_dir_deleg(clp, fp);
 	if (!dp)
 		goto out_delegees;
-	nfs4_delegation_record_grant_slot(dp, cstate);
+	nfsd41_record_grant_slot(&dp->dl_recall_grant, cstate);
 	if (cstate->current_fh.fh_export)
 		dp->dl_stid.sc_export =
 			exp_get(cstate->current_fh.fh_export);
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 5f43668486..2c00b334c3 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -276,6 +276,14 @@ struct nfsd4_cb_notify {
 	struct nfsd4_callback		ncn_cb;		// notify4 callback
 };
 
+/* Forward-channel slot that carried a request which created state */
+struct nfsd4_grant_slot {
+	u32			sessionid_seq;
+	u32			slotid;
+	u32			seqid;
+	bool			valid;
+};
+
 /*
  * Represents a delegation stateid. The nfs4_client holds references to these
  * and they are put when it is being destroyed or when the delegation is
@@ -315,13 +323,8 @@ struct nfs4_delegation {
 	bool			dl_setattr;
 
 	/* Forward-channel slot that carried the granting request */
-	struct {
-		u32			sessionid_seq;
-		u32			slotid;
-		u32			seqid;
-		bool			valid;
-		bool			retired_at_send;
-	} dl_recall_grant;
+	struct nfsd4_grant_slot	dl_recall_grant;
+	bool			dl_recall_retired_at_send;
 
 	union {
 		/* for CB_GETATTR */
@@ -949,6 +952,13 @@ extern void nfsd41_cb_referring_call(struct nfsd4_callback *cb,
 				     struct nfs4_sessionid *sessionid,
 				     u32 slotid, u32 seqno);
 extern void nfsd41_cb_destroy_referring_call_list(struct nfsd4_callback *cb);
+extern void nfsd41_record_grant_slot(struct nfsd4_grant_slot *grant,
+				     const struct nfsd4_compound_state *cstate);
+extern bool nfsd41_grant_slot_retired(struct nfs4_client *clp,
+				      const struct nfsd4_grant_slot *grant);
+extern void nfsd41_cb_referring_grant(struct nfsd4_callback *cb,
+				      struct nfs4_client *clp,
+				      const struct nfsd4_grant_slot *grant);
 extern void nfsd4_init_cb(struct nfsd4_callback *cb, struct nfs4_client *clp,
 		const struct nfsd4_callback_ops *ops, enum nfsd4_cb_op op);
 extern bool nfsd4_run_cb(struct nfsd4_callback *cb);

-- 
2.43.0

