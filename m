From: Xiubo Li <xiubo.li@clyso.com>
Date: Mon, 19 Oct 2026 13:33:27 +0200
Subject: [PATCH v2 1/4] ceph: report the requested length in the netfs read
 metrics
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-ceph-metrics-percpu-v2-1-1fa5229b00b8@clyso.com>
References: <20261019-ceph-metrics-percpu-v2-0-1fa5229b00b8@clyso.com>
In-Reply-To: <20261019-ceph-metrics-percpu-v2-0-1fa5229b00b8@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Xiubo Li <xiubo.li@clyso.com>, Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan van der Ster <dan.vanderster@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792409634; l=1451;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=CzKRsfVGnXiWaBtWsr/Fqsu917e+WRvEXbKXVxY/rmA=;
 b=D3IIpAx4UkwduCGz3ETWsaXRSCBl5gQQhmehxEGZPmscvAXWF54I4egX4BD6RYhtZl/Yl4o7E
 DQr1eqvFAwjAwSt2SP8/dxB9PrxOujPBhmF9g3JIV1/exL8pF61gBVZ
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

finish_netfs_read() passes osd_data->length to
ceph_update_read_metrics(), but a buffered read of an unencrypted
file attaches its data as CEPH_OSD_DATA_TYPE_ITER, and
ceph_osd_iter_init() only sets the type and the iov_iter.  length
shares a union with the iov_iter, so the read size metrics record
some unrelated iov_iter field, which is normally 0, for every page
cache read, and metrics/size is useless for buffered reads.

Report op->extent.length, the length the OSD read asked for, which is
set for every data type and equals osd_data->length for the page
vector that encrypted files still use.

Fixes: 4de77f25fd85 ("ceph: use osd_req_op_extent_osd_iter for netfs reads")
Reported-by: Dan van der Ster <dan.vanderster@clyso.com>
Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index dd2bd8ed2424..8500d72702d6 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -236,7 +236,7 @@ static void finish_netfs_read(struct ceph_osd_request *req)
 	ceph_blog_enter_gfp(fsc, &__ji, GFP_ATOMIC);
 
 	ceph_update_read_metrics(&fsc->mdsc->metric, req->r_start_latency,
-				 req->r_end_latency, osd_data->length, err);
+				 req->r_end_latency, op->extent.length, err);
 
 	boutc(cl, "result %d subreq->len=%zu i_size=%lld\n", req->r_result,
 	      subreq->len, i_size_read(req->r_inode));

-- 
2.53.0

