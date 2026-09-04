From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 03 Sep 2026 18:48:36 -0700
Subject: [PATCH] libceph: only set read_from_replica on read requests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260903-b4-read-from-replica-v1-1-76d1ad8d7c2e@clyso.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMBCE4Vche3aT2iUEfRXjoS0DrFEgWzUmh
 Hen6m2+w/wrZZgi07layfDWrPNUcDxUlMYwDWDtisk737iTE441G0LHvc2Pspa7psBeRBBi9Gi
 FynUx9Pr5ZS/Xv/Mr3pCe3xZt2w4AJj7qeAAAAA==
X-Change-ID: 20260903-b4-read-from-replica-2333eabb2e83
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, Jeff Layton <jlayton@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788486534; l=1667;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=1pp/hauPyQPUhFkDy5Rb9gGCh+DLMtRFxWdPt0GBjHY=;
 b=dsJX6n/Fq3mMTVrwc5yJ4ApdkX4MOSvn+uELMQtll59cU0ddJ1liPq502KO3I9qJ4Lf4d4o/n
 U6kHeQxGItsBPQOhW9Ov8Eh04CDAoqBA0UGqlOyPY8ozSVCx7X4+7x4
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_osdc_alloc_request() ORs the mount option's read_from_replica
flag into r_flags for every request, writes included.  The flag is
meant for reads: calc_target() skips the replica choice for any
request that has CEPH_OSD_FLAG_WRITE, and the OSDs only know
BALANCE_READS on read ops.  Sending it on writes is at best ignored;
with read_from_replica=balance a buffered write that fell back to
ceph_sync_write() after losing BUFFER to a revoke failed with -EIO,
while the same run without the option works fine.

Gate the flag on CEPH_OSD_FLAG_READ.

Fixes: 22d2cfdffa5b ("libceph: move away from global osd_req_flags")
Cc: stable@vger.kernel.org
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 net/ceph/osd_client.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/net/ceph/osd_client.c b/net/ceph/osd_client.c
index f68918fc27f9..a5fc5de2c2b5 100644
--- a/net/ceph/osd_client.c
+++ b/net/ceph/osd_client.c
@@ -1109,7 +1109,9 @@ struct ceph_osd_request *ceph_osdc_new_request(struct ceph_osd_client *osdc,
 	req->r_base_oloc.pool = layout->pool_id;
 	req->r_base_oloc.pool_ns = ceph_try_get_string(layout->pool_ns);
 	ceph_oid_printf(&req->r_base_oid, "%llx.%08llx", vino.ino, objnum);
-	req->r_flags = flags | osdc->client->options->read_from_replica;
+	req->r_flags = flags;
+	if (flags & CEPH_OSD_FLAG_READ)
+		req->r_flags |= osdc->client->options->read_from_replica;
 
 	req->r_snapid = vino.snap;
 	if (flags & CEPH_OSD_FLAG_WRITE)

---
base-commit: 6b039a71d37a39bb90a64c4e271f90ee0588ac4a
change-id: 20260903-b4-read-from-replica-2333eabb2e83

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

