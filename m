From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 20 Oct 2026 14:01:11 +0900
Subject: [PATCH] NFSv4.1: Return NFS4ERR_DELAY when a referring call wait
 times out
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-nfs-referring-call-delay-v1-1-0be8f0608f7c@samsung.com>
X-B4-Tracking: v=1; b=H4sIAJb11moC/x2MQQqAMAzAviI9W9imVPAr4mFsVQtjSgeiiH93e
 AwkeaCwChcYmweUTymy5wq2bSBsPq+MEiuDM46scQbzUlB5YVXJKwafEkZO/kbqBrI9RW86gpo
 f1ZLrX0/z+36wK4BiagAAAA==
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 Olga Kornievskaia <okorniev@redhat.com>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 linux-nfs@vger.kernel.org, stable@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792472470; l=4242;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=02LTmI/rckeyrcaFfqhLpIKa7n4ZNNpxGuJF72qSrHU=;
 b=fixfIzdcyuiXmZyiDH2FDbN0cdQRRWBrv/ep1P4uOFnwOkbh1Q31406/iWHYD0VOz9H5P3jBv
 w8dfkjDhysGCi81Eqfzxqwl7WNTCzD3UIovVYvnby3/HZwfOLHujptw
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 045d2a6d076a ("NFSv4.1: Delay callback processing when there
are referring triples") made nfs4_callback_sequence() wait up to half
a second for each request named in the referring call lists and answer
NFS4ERR_DELAY if one is still outstanding, so that the server sends
the callback again later (RFC 8881 section 2.10.6.3).

Commit 8618289c4655 ("NFSv4: Fix a sleep in atomic context in
nfs4_callback_sequence()") turned referring_call_exists() from bool
into int and made the caller test for a negative value, but kept

	status = nfs4_slot_wait_on_seqid(...) < 0;

A timeout stores 1, referring_call_exists() never returns a negative
value, and the callback is processed as if the request had completed.

nfsd has named the COPY in CB_OFFLOAD since commit b53a42970fa4
("NFSD: Record each NFSv4 call's session slot index"). "NFSD: Send
referring calls with CB_RECALL" [1], queued for v7.4, also names the
OPEN that granted a delegation in a recall of it, and expects
NFS4ERR_DELAY until the client has recorded the delegation. A client
that has not recorded it within half a second answers
NFS4ERR_BADHANDLE instead. nfsd sends the recall once more two seconds
later, and if that is answered the same way, it gives up: a
conflicting open then waits until the delegation is revoked when the
lease time has passed.

Keep the error from nfs4_slot_wait_on_seqid(). A server that names a
request the client has not finished with now gets NFS4ERR_DELAY until
the client has, however long that takes, where the callback used to
be processed after half a second. Each resend answered this way holds
a callback thread for half a second; by default there is one callback
thread per minor version, shared by all servers.

With [1] on the server and a test-only sleep of five seconds before
the client records a delegation, opening for write, on the server, a
file that the client had just opened read-only took 90 to 92 seconds
in five runs (lease time 90 seconds): both recalls were answered with
NFS4ERR_BADHANDLE and the delegation was not returned. With this patch
the client answered NFS4ERR_DELAY twice and then returned the
delegation, and the open took 5.1 seconds in each of five runs.

Fixes: 8618289c4655 ("NFSv4: Fix a sleep in atomic context in nfs4_callback_sequence()")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/r/20260802-nfsd-deleg-destroy-badhandle-v1-9-323aa7196055@kernel.org # [1]
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
The patch applies unchanged to v7.3, next-20261019 and the stable
branches back to linux-5.10.y. Before v6.8 referring_call_exists()
returns status itself and the caller already tests it for a negative
value, so the change has the same effect there. [1] is queued for
v7.4, so this would be good to have in v7.4 too.

Tested in QEMU guests with Chuck's nfsd-testing b4e06bef3884 (based on
v7.3-rc6, contains [1]) as client and server kernel; its NFS client
callback, session and OPEN code is the same as in v7.3. KASAN and
lockdep on, NFSv4.2, the export on XFS, nfsv4leasetime 90. The
test-only sleep is a module parameter that makes
nfs4_process_delegation() sleep before it records the delegation,
while the OPEN still holds its slot. It is not part of this patch.
Without the sleep the recall was answered at once with and without
this patch (five runs each), and three async COPYs of 64 MiB completed
with CB_OFFLOAD answered NFS4_OK in both.
---
 fs/nfs/callback_proc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/nfs/callback_proc.c b/fs/nfs/callback_proc.c
index 3fb10c8e42..f4ccfa50a0 100644
--- a/fs/nfs/callback_proc.c
+++ b/fs/nfs/callback_proc.c
@@ -489,7 +489,7 @@ static int referring_call_exists(struct nfs_client *clp,
 			ref = &rclist->rcl_refcalls[j];
 			spin_unlock(lock);
 			status = nfs4_slot_wait_on_seqid(tbl, ref->rc_slotid,
-					ref->rc_sequenceid, HZ >> 1) < 0;
+					ref->rc_sequenceid, HZ >> 1);
 			spin_lock(lock);
 			if (status)
 				goto out;

---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261020-nfs-referring-call-delay-6376146da036

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

