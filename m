From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 06 Oct 2026 13:29:45 +0900
Subject: [PATCH 3/6] nfsd: keep polling a layout recall answered with
 NFS4ERR_OLD_STATEID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-nfsd-layout-recall-v1-3-b59b31caf342@samsung.com>
References: <20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com>
In-Reply-To: <20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791260982; l=7445;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=aFYCHNvCD98LiBhzu+LdJlmYFTK2Z3cHjp8ZewdyRRs=;
 b=kWcpd5vRiAqG+iRjMmCmMbgvrgTvvcXyv/RZLHTASU0bEyNv4pUXLMuaJCs/jEzminboYDiKa
 Q6Hz1FjkPS6CxBhveQyslRrswHjL9DTEl9H4tOzlnsz50BmvHnzCUdV
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a client answers CB_LAYOUTRECALL with NFS4_OK and still holds
layouts, nfsd4_cb_layout_done() sends the callback again after 10 ms to
see if the client is done.  The repeat carries the stateid of the first
callback, although RFC 8881 section 12.5.3 has the server increment the
seqid in each CB_LAYOUTRECALL request.

The same section makes the seqid of a processed CB_LAYOUTRECALL the
current seqid of the client.  Since commit dce72920c81b ("NFSv4.1: if
referring calls are complete, trust the stateid argument"), which is in
v6.8, the Linux client answers a recall whose seqid is not newer than
its own with NFS4ERR_OLD_STATEID, unless a LAYOUTRETURN is on the wire
(NFS4ERR_DELAY) or the layouts are gone (NFS4ERR_NOMATCHING_LAYOUT).
Before that commit it answered a repeat of the recall it was working
on with NFS4_OK until its LAYOUTRETURN was prepared, and with
NFS4ERR_OLD_STATEID from then until nfsd had processed the LAYOUTRETURN
(read from the code, not run).  So a client from v6.8 on that needs
more than 10 ms to finish its I/O and to send LAYOUTRETURN answers the
second callback with NFS4ERR_OLD_STATEID, and an older client can
answer a later one that way.

nfsd4_cb_layout_done() takes that as a failed recall.  With the block
layout it logs "client ... failed to respond to layout recall.
Fencing.." and runs /sbin/nfsd-recall-failed, with the SCSI layout it
fences the client with a persistent reservation preempt, and in both
cases nfsd4_cb_layout_release() drops the layouts.  Section 12.5.5
requires the server to wait one lease period after a recall before it
takes further action.  Here the client is still using the layout: its
I/O can be in flight when the conflicting operation goes on, and what
it has written to newly allocated blocks stays unwritten on the server,
because the layout is gone when the client wants to commit it.

Clients doing O_DIRECT I/O in 1 MiB requests on one file for 30
seconds, block layout on XFS.

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
the server had returned.  After, the write on the server waits for it.

Two clients writing one file with the SCSI layout on an nvmet-tcp
namespace: before, both recalls sent ended in nfsd4_scsi_fence_client(),
the number of registrants on the namespace went from 4 to 2, and both
clients logged reservation conflicts and did the rest of the run
through the server.  The same with a new file, after a fresh boot: both
clients were fenced, and one of the 630 blocks they had written read
back as zeroes.  After, no client is fenced and no block is lost.

Handle NFS4ERR_OLD_STATEID like NFS4ERR_DELAY: the client has seen the
recall, so keep polling until the layouts are returned or the time
limit is reached.  This patch must not be applied without the two
before it: the limit only works with "nfsd: make the time limit of a
layout recall work", and with "nfsd: run the fence script when a block
layout lease break times out" a block layout client is fenced when the
lease break gives up.  On kernels before v7.1 a lease break does not
time out; there the operation on the server waits until the recall
ends, for at most two lease periods.
That operation can be an nfsd thread serving a WRITE or SETATTR of
another client (xfs_break_layouts()).  It is what such a kernel does
today for a client that keeps answering NFS4ERR_DELAY, without the
limit of the first patch; RFC 8881 section 12.5.5 asks the server to
wait at least one lease period before it fences.

The poll sends the callback every 10 ms for as long as the client
holds the layout, as it already does for a client that answers
NFS4ERR_DELAY.  With a client that needs long to return the layout
that is about 100 callbacks a second, for up to two lease periods.

A client can also answer this way without having processed the recall,
when a LAYOUTRETURN that left layouts behind has moved its seqid past
the seqid of the recall.  With this patch alone it is then polled until
the time limit and fenced, where it used to be fenced at once, and
LAYOUTGETs for the file fail with NFS4ERR_RECALLCONFLICT meanwhile;
"nfsd: poll a layout recall with a new seqid when the client is past
it", later in this series, gives such a client a new seqid.

This keeps the poll as it is for a client that has answered NFS4_OK.
Sending each repeat with a new seqid, or ending the callback on NFS4_OK
and letting the LAYOUTRETURN finish the recall, would follow the RFC;
both are larger changes than a fix for stable kernels should be.

Fixes: 6b9b21073d3b ("nfsd: give up on CB_LAYOUTRECALLs after two lease periods")

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index 088e26e8e..3d288649c 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -707,7 +707,15 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 	switch (task->tk_status) {
 	case 0:
 	case -NFS4ERR_DELAY:
+	case -NFS4ERR_OLD_STATEID:
 		/*
+		 * RFC 8881 section 12.5.3 wants a new seqid in each
+		 * CB_LAYOUTRECALL request.  The poll below sends the request
+		 * again with the seqid of the first one.  A client that has
+		 * processed that one is at its seqid or past it, and the
+		 * Linux client answers the repeat with NFS4ERR_OLD_STATEID
+		 * while it is returning the layouts.
+		 *
 		 * Anything left? If not, then call it done. Note that we don't
 		 * take the spinlock since this is an optimization and nothing
 		 * should get added until the cb counter goes to zero.

-- 
2.43.0

