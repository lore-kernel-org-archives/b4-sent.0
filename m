From: Daejun Park <daejun7.park@samsung.com>
Date: Wed, 14 Oct 2026 16:30:03 +0900
Subject: [PATCH v2 7/7] nfsd: do not fence a client for a layout recall
 with no layouts left
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-nfsd-layout-recall-v2-7-764462bddfd1@samsung.com>
References: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
In-Reply-To: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791962996; l=1852;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=fJWkfHrjhyvPcMpES15/0yb8WW8jmYTA1ewdCgCzzTI=;
 b=EVCcY+Aufz3R/M09NJGKhiZcGv6CotWf/kaFW46PiG4BakFaPacdpRYdum2FJdh9A14R0qJyz
 dKdaYrYzOskCKt7jHZ5WfkjtU04aqlQ/rJjjL3RqHNI5w0wEUsOzCaf
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd4_cb_layout_done() fences the client for any answer to a
CB_LAYOUTRECALL that it does not handle, without looking at whether the
layout stateid still has layouts. A LAYOUTRETURN can return the last
layout while the recall is still out. The Linux client answers
NFS4ERR_NOMATCHING_LAYOUT then, which RFC 8881 section 20.3.3 allows
for a client that holds no layouts for the file. A client that answers
NFS4ERR_BAD_STATEID is right too, since section 12.5.3 makes a layout
stateid invalid once the client has no layouts for the file, but it is
fenced for nothing.

Check for layouts before fencing, as the polls already do before their
time limit, and end the recall when none are left. This does not depend
on the earlier patches in this series.

A pynfs client that returns its layout on the recall and then answers
it NFS4ERR_BAD_STATEID: without this patch, nfsd logged "failed to
respond to layout recall" and ran the fence for it; with it, the recall
ended without either.

Fixes: c5c707f96fc9 ("nfsd: implement pNFS layout recalls")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 fs/nfsd/nfs4layouts.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/nfsd/nfs4layouts.c b/fs/nfsd/nfs4layouts.c
index f54515e7f6..e7a4eae51e 100644
--- a/fs/nfsd/nfs4layouts.c
+++ b/fs/nfsd/nfs4layouts.c
@@ -931,6 +931,15 @@ nfsd4_cb_layout_done(struct nfsd4_callback *cb, struct rpc_task *task)
 		}
 		fallthrough;
 	default:
+		/*
+		 * Nothing to fence for once the layouts are gone: a
+		 * LAYOUTRETURN can return the last one while the recall is
+		 * still out.
+		 */
+		if (list_empty(&ls->ls_layouts)) {
+			trace_nfsd_layout_recall_done(&ls->ls_stid.sc_stateid);
+			return 1;
+		}
 		/*
 		 * Unknown error or non-responding client, we'll need to fence.
 		 */

-- 
2.43.0

