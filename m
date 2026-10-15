From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 15 Oct 2026 13:15:47 +0900
Subject: [PATCH v3 6/7] nfsd: keep polling a layout recall answered with
 NFS4ERR_OLD_STATEID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-nfsd-layout-recall-v3-6-ba3269f8ca22@samsung.com>
References: <20261015-nfsd-layout-recall-v3-0-ba3269f8ca22@samsung.com>
In-Reply-To: <20261015-nfsd-layout-recall-v3-0-ba3269f8ca22@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037741; l=11972;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=DSYyTU1AKeyaggXtFeay8jWf3qfCdEtJfKHveNWlY+4=;
 b=K5zZ4AvKtMKprIFC6g1/eveP0/rldjHzlPHM6BAsLP2ZW14fXcqsvkMCsCvNiPIbZMrVoyOHQ
 qNRtI6UI0WzBlQn8K+sQicA/6bgTIGJd3VUgn+CNje/FoTxbNAvZclJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a client answers CB_LAYOUTRECALL with NFS4_OK and still holds
layouts, nfsd4_cb_layout_done() sends the callback again after 10 ms to
see if the client is done. The repeat carries the stateid of the first
callback, although RFC 8881 section 12.5.3 has the server increment the
seqid in each CB_LAYOUTRECALL request.

The same section makes the seqid of a processed CB_LAYOUTRECALL the
current seqid of the client. Since commit dce72920c81b ("NFSv4.1: if
referring calls are complete, trust the stateid argument"), which is in
v6.8, the Linux client answers a recall whose seqid is not newer than
its own with NFS4ERR_OLD_STATEID, unless a LAYOUTRETURN is on the wire
(NFS4ERR_DELAY) or the layouts are gone (NFS4ERR_NOMATCHING_LAYOUT).
Before that commit it answered a repeat of the recall it was working
on with NFS4_OK until its LAYOUTRETURN was prepared, and with
NFS4ERR_OLD_STATEID from then until nfsd had processed the LAYOUTRETURN
(read from the code, not run). So a client from v6.8 on that needs
more than 10 ms to finish its I/O and to send LAYOUTRETURN answers the
second callback with NFS4ERR_OLD_STATEID, and an older client can
answer a later one that way.

nfsd4_cb_layout_done() takes that as a failed recall. With the block
layout it logs "client ... failed to respond to layout recall.
Fencing.." and runs /sbin/nfsd-recall-failed, with the SCSI layout it
fences the client with a persistent reservation preempt, and in both
cases nfsd4_cb_layout_release() drops the layouts. Section 12.5.5
requires the server to wait one lease period after a recall before it
takes further action. Here the client is still using the layout: its
I/O can be in flight when the conflicting operation goes on, and what
it has written to newly allocated blocks stays unwritten on the server,
because the layout is gone when the client wants to commit it.

Clients doing O_DIRECT I/O in 1 MiB requests on one file for 30 seconds,
block layout on XFS. "after" is the polling of this patch, without the
new seqid described below, with "nfsd: make the time limit of a layout
recall work", on nfsd-testing 32eb1a60b456. The same runs with the new
seqid and the rest of this series gave no failed recall and no lost
block either.

Recalls that ended in the failure path, out of the recalls sent:

                                                   before      after
  2 clients read (different halves of the file)    7 / 9       0 / 9
  2 clients write                                  8 / 9       0 / 9
  3 clients write                                  19 / 20     0 / 20
  2 clients write, the server writes 4 KiB to
  the file every 50 ms                             216 / 229   0 / 250

Blocks that read back as zeroes on the server, out of the 1 MiB blocks
that the clients wrote to a new file with O_DIRECT, followed by one
successful fsync():

                                                   before      after
  2 clients write                                  6 / 564     0 / 481
  3 clients write                                  11 / 527    0 / 569
  1 client writes, the server sets the file size
  every second                                     21 / 469    0 / 504
  2 clients write, file preallocated               8 / 601     0 / 602
  1 client writes, 1 client reads                  4 / 493     0 / 508

One client writing through a block layout whose path to the device is
cut for 15 seconds while it can still talk to the server, and a 4 KiB
write to the file on the server:

                                                   before      after
  the write on the server takes                    0.05 s      15.6 s
  the recall                                       fails       completes
  /sbin/nfsd-recall-failed is run                  yes         no

Before, the write of the client that was in flight when the layout was
recalled was stuck for 18.5 seconds and no WRITE was sent to the
server, so it reached the device about 15 seconds after the write on
the server had returned. After, the write on the server waits for it.

Two clients writing one file with the SCSI layout on an nvmet-tcp
namespace: before, both recalls sent ended in nfsd4_scsi_fence_client(),
the number of registrants on the namespace went from 4 to 2, and both
clients logged reservation conflicts and did the rest of the run
through the server. The same with a new file, after a fresh boot: both
clients were fenced, and one of the 630 blocks they had written read
back as zeroes. After, no client is fenced and no block is lost.

Handle NFS4ERR_OLD_STATEID like NFS4ERR_DELAY: the client has seen the
recall, so keep polling until the layouts are returned, the time limit
is reached, or a lease break has had the client fenced. Apply this only
together with the earlier patches in this series: the limit only works
with "nfsd: make the time limit of a layout recall work", with "nfsd:
run the fence script when a block layout lease break times out" a block
layout client is fenced when the lease break gives up, with "nfsd: end a
layout recall once a lease break has fenced the client" its recall ends
then, and "nfsd: answer NFS4ERR_DELAY instead of waiting for a layout
recall" keeps nfsd threads out of the longer wait. Kernels before v7.1
do not have the lease break timeout that the second and third of them
fix. There, an operation on the server that does not come from nfsd, and
an nfsd thread that still ends up in the filesystem's break, waits until
the recall ends, for at most two lease periods. Such a kernel already
waits that way, without a limit, for a client that keeps answering
NFS4ERR_DELAY, and RFC 8881 section 12.5.5 asks the server to wait at
least one lease period before it fences.

The poll sends the callback every 10 ms for as long as the client
holds the layout, as it already does for a client that answers
NFS4ERR_DELAY. With a client that needs long to return the layout
that is about 100 callbacks a second, for up to two lease periods.

A client can also answer NFS4ERR_OLD_STATEID without having taken the
recall up. A LAYOUTRETURN that returns some layouts and leaves others
gets a new seqid; if nfsd processes it after ->prepare, the client takes
in a seqid above the recall's from its reply. Such a client answers
every poll with NFS4ERR_OLD_STATEID. Polling alone would keep LAYOUTGETs
of other clients failing with NFS4ERR_RECALLCONFLICT for up to two lease
periods and then fence the client, although it was never asked for the
layouts it still holds. RFC 8881 section 12.5.3 has a new seqid for each
CB_LAYOUTRECALL request, so when a client that has not answered NFS4_OK
answers NFS4ERR_OLD_STATEID, give the next poll a new seqid, which the
client takes up. ->prepare clears ls_recall_accepted, and ->done sets it
when the client answers NFS4_OK. The new seqid is traced as
nfsd_layout_recall_new_seqid.

->done runs in rpciod and does not take ls_mutex, which could block it;
nfs4_inc_and_copy_stateid() takes sc_lock. So
nfsd4_preprocess_layout_stateid(), which checks under ls_mutex that the
seqid a client presents is not above the current one, now reads the
current seqid under sc_lock as well. While a recall is out, only a
LAYOUTRETURN changes the seqid besides, since "nfsd: fail a LAYOUTGET in
progress when the layout lease is broken" keeps LAYOUTGET from adding
layouts to a recalled layout stateid.

A pynfs client that holds a layout answers a recall whose seqid is not
above the first seqid of the recall with NFS4ERR_OLD_STATEID, and
returns the layout on a later one. With polling alone, nfsd sent the
recall 501 times in six seconds, all with the first seqid, and a
LAYOUTGET of another client still got NFS4ERR_RECALLCONFLICT. With the
new seqid, the second recall carried it, 10 ms later, the client
returned the layout, and the LAYOUTGET succeeded.

A client that has answered NFS4_OK is still polled with the seqid of the
recall. Sending each repeat with a new seqid, or ending the callback on
NFS4_OK and letting the LAYOUTRETURN finish the recall, would follow the
RFC; both are larger changes than a fix for stable kernels should be.

Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Fixes: 6b9b21073d3b ("nfsd: give up on CB_LAYOUTRECALLs after two lease periods")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
Reviewed-by: Jeff Layton <jlayton@kernel.org>
---
 fs/nfsd/nfs4layouts.c | 33 +++++++++++++++++++++++++++++++--
 fs/nfsd/state.h       |  2 ++
 fs/nfsd/trace.h       |  1 +
 3 files changed, 34 insertions(+), 2 deletions(-)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 574d16cbbd..a6934fc21a 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -366,6 +366,7 @@ nfsd4_preprocess_layout_stateid(struct svc_rqst *rqstp,
 	struct nfs4_stid *stid;
 	unsigned short typemask = SC_TYPE_LAYOUT;
 	__be32 status;
+	bool after;
 
 	if (create)
 		typemask |= (SC_TYPE_OPEN | SC_TYPE_LOCK | SC_TYPE_DELEG);
@@ -395,7 +396,15 @@ nfsd4_preprocess_layout_stateid(struct svc_rqst *rqstp,
 
 		status = nfserr_bad_stateid;
 		mutex_lock(&ls->ls_mutex);
-		if (nfsd4_stateid_generation_after(stateid, &stid->sc_stateid))
+		/*
+		 * The recall callback can move the seqid on without
+		 * ls_mutex, under sc_lock.
+		 */
+		spin_lock(&stid->sc_lock);
+		after = nfsd4_stateid_generation_after(stateid,
+						       &stid->sc_stateid);
+		spin_unlock(&stid->sc_lock);
+		if (after)
 			goto out_unlock_stid;
 		if (layout_type != ls->ls_layout_type)
 			goto out_unlock_stid;
@@ -884,6 +893,7 @@ nfsd4_cb_layout_prepare(struct nfsd4_callback *cb)
 	mutex_lock(&ls->ls_mutex);
 	nfs4_inc_and_copy_stateid(&ls->ls_recall_sid, &ls->ls_stid);
 	mutex_unlock(&ls->ls_mutex);
+	ls->ls_recall_accepted = false;
 	return true;
 }
 
@@ -909,9 +919,28 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 
 	trace_nfsd_cb_layout_done(&ls->ls_stid.sc_stateid, task);
 	switch (task->tk_status) {
-	case 0:
+	case -NFS4ERR_OLD_STATEID:
+		/*
+		 * A client that has not accepted this recall is past its
+		 * seqid, e.g. after a LAYOUTRETURN: poll it with a new seqid
+		 * (RFC 8881 section 12.5.3). No ls_mutex here, it could block
+		 * rpciod; sc_lock orders the seqid.
+		 */
+		if (!ls->ls_recall_accepted) {
+			nfs4_inc_and_copy_stateid(&ls->ls_recall_sid,
+						  &ls->ls_stid);
+			trace_nfsd_layout_recall_new_seqid(&ls->ls_recall_sid);
+		}
+		fallthrough;
 	case -NFS4ERR_DELAY:
+	case 0:
+		if (!task->tk_status)
+			ls->ls_recall_accepted = true;
 		/*
+		 * The poll repeats the last seqid, against RFC 8881 section
+		 * 12.5.3; a client returning its layouts answers it with
+		 * NFS4ERR_OLD_STATEID.
+		 *
 		 * Anything left? If not, then call it done. Note that we don't
 		 * take the spinlock since this is an optimization and nothing
 		 * should get added until the cb counter goes to zero.
diff --git a/fs/nfsd/state.h b/fs/nfsd/state.h
index 23b2eb3ff1..f001edfad9 100644
--- a/fs/nfsd/state.h
+++ b/fs/nfsd/state.h
@@ -856,6 +856,8 @@ struct nfs4_layout_stateid {
 	struct nfsd4_callback		ls_recall;
 	stateid_t			ls_recall_sid;
 	ktime_t				ls_recall_start;
+	/* The client has answered NFS4_OK to the recall */
+	bool				ls_recall_accepted;
 	bool				ls_recalled;
 	struct mutex			ls_mutex;
 
diff --git a/fs/nfsd/trace.h b/fs/nfsd/trace.h
index abfdbc637c..e0908cb21c 100644
--- a/fs/nfsd/trace.h
+++ b/fs/nfsd/trace.h
@@ -681,6 +681,7 @@ DEFINE_STATEID_EVENT(layout_return_lookup_fail);
 DEFINE_STATEID_EVENT(layout_recall);
 DEFINE_STATEID_EVENT(layout_recall_empty);
 DEFINE_STATEID_EVENT(layout_recall_done);
+DEFINE_STATEID_EVENT(layout_recall_new_seqid);
 DEFINE_STATEID_EVENT(layout_recall_fail);
 DEFINE_STATEID_EVENT(layout_recall_release);
 

-- 
2.43.0

