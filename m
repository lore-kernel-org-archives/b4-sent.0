From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 15 Oct 2026 13:15:46 +0900
Subject: [PATCH v3 5/7] nfsd: end a layout recall once a lease break has
 fenced the client
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-nfsd-layout-recall-v3-5-ba3269f8ca22@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792037741; l=4349;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=nVtMqe8T1gMU7/sTzRvdu6siQwlULmEcLD9qbYjYlVY=;
 b=S6KtnPRgLBnDAQYYDcLR6S2xybcaOez2haT/mbKNQXRny0HxobKrX7xePGT3C5LTTpJ70mOjD
 mYI9ToGif6uDIgHaTdpNcGRRqMDgPuTGHTosaYVCwyYTVLM+YUbLNYc
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a lease break on a layout times out,
nfsd4_layout_lm_breaker_timedout() has the fence worker fence the client
that holds the layout, with ->fence_client() for the SCSI layout since
the commit this fixes, and with the fence script for the block layout
since "nfsd: run the fence script when a block layout lease break times
out". The lease is then removed and the operation that broke it goes on.
The CB_LAYOUTRECALL of that layout stateid is not ended: a client whose
path to the device is cut keeps answering it with NFS4_OK or
NFS4ERR_DELAY (a Linux client before v6.8, and every Linux client with
"nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID",
later in this series), and nfsd polls it until the time limit of the
recall, two lease periods. Meanwhile fi_lo_recalls stays raised and
every LAYOUTGET for the file, from any client, gets
NFS4ERR_RECALLCONFLICT, for up to 135 seconds with the default times.
And a LAYOUTCOMMIT that the fenced client sends when its path is back is
applied after the operation that broke the lease went on; XFS then
converts whatever unwritten extents the file has in that range by then.

End the recall at the next poll once the fence worker is done, for both
layout types. nfsd4_cb_layout_release() then drops the layouts, as on
the recall failure path (RFC 8881 section 12.5.6). A LAYOUTCOMMIT that
the client sends after that gets NFS4ERR_BADLAYOUT, so what it wrote
through the layout and had not committed by then is lost; the Linux
client does not report that error. Setting fs.lease-break-time to at
least the lease time gives such a client the one lease period that RFC
8881 section 12.5.5 has the server wait after a recall.

ls_fenced is also set when the fence worker stopped without a fence: the
layout stateid is being torn down or was revoked, its lease is already
gone, or no layouts are left. Ending the recall is right in those cases
too: the caller drops the layouts, or the stateid has been revoked.

Tested together with "nfsd: keep polling a layout recall answered with
NFS4ERR_OLD_STATEID", as a current Linux client otherwise has the recall
fail after 10 ms, on nfsd-testing 78c334bc5ae6. "Without this patch" is
v2 of this series, which fences the same way and does not end the
recall. A client writing through a block layout whose path to the device
is cut for 210 seconds while it can still talk to the server, default
lease and lease break times, and a 4 KiB write to the file on the
server: the fence script ran once either way. Without this patch the
recall was polled until its time limit, 180 seconds after it started;
with it the recall ended 47.5 seconds after it started, right after the
script. With the SCSI layout the fence worker fenced the client either
way, and the recall ended 10 ms after the fence with this patch and at
the time limit without it.

With the path cut for 70 seconds, the recall ended 48 seconds after it
started with this patch, and the LAYOUTCOMMIT that the client sent when
its path was back got NFS4ERR_BADLAYOUT. Without it, the recall ended
when the client returned the layout, 71 seconds after it started, and
the LAYOUTCOMMIT was applied. The loss of what the client wrote and had
not committed is read from the code: the test overwrites a file written
beforehand, so no extent is left unwritten.

Fixes: f52792f484ba ("NFSD: Enforce timeout on layout recall and integrate lease manager fencing")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index f3bed0fa98..574d16cbbd 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -918,6 +918,15 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		 */
 		if (list_empty(&ls->ls_layouts))
 			return 1;
+		/*
+		 * The fence worker of a lease break is done: revoke the
+		 * layouts (RFC 8881 section 12.5.6), before one lease period
+		 * (section 12.5.5) when fs.lease-break-time is shorter.
+		 */
+		if (nfsd4_layout_fenced(ls)) {
+			trace_nfsd_layout_recall_fail(&ls->ls_stid.sc_stateid);
+			return 1;
+		}
 
 		/* Poll the client until it's done with the layout */
 		now = ktime_get_boottime();

-- 
2.43.0

