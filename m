From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 23 Jul 2026 13:47:43 +0800
Subject: [PATCH 2/2] ceph: use GFP_KERNEL consistently in
 __ceph_pool_perm_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-gfp_nofs-v1-2-c06b40354ec9@clyso.com>
References: <20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com>
In-Reply-To: <20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784785666; l=1692;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=wLYsu77cBeEkfqrRltnBpmEAlrz6vICedFaEgwuS1YY=;
 b=CxLO/iRpEuiNm6INHXXt7v3pl9FjaKvZpoU0Mfa0PkCTICZe6YXYYTGA/L+FiSBwSQ1PlCRqJ
 ARjcS/8ik7RAmOh8a6IrMFtCYsVXn8BhEwjvvkKSzhREJ2Pn4RjZ9oP
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__ceph_pool_perm_get() has four allocations for building OSD STAT
requests, three of which used GFP_NOFS and one (the page vector
allocation) used GFP_KERNEL, making them inconsistent.

The function is only called from ceph_try_get_caps() and
__ceph_get_caps(), both of which are in the user I/O path (read,
write, fallocate, mmap fault), not in the writeback path.  There is
no risk of recursive writeback, so GFP_NOFS is unnecessarily
restrictive.  Use GFP_KERNEL consistently for all four allocations.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index e2da3ab9f808..d2ac3df47e97 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -2479,12 +2479,12 @@ static int __ceph_pool_perm_get(struct ceph_inode_info *ci,
 		rd_req->r_base_oloc.pool_ns = ceph_get_string(pool_ns);
 	ceph_oid_printf(&rd_req->r_base_oid, "%llx.00000000", ci->i_vino.ino);
 
-	err = ceph_osdc_alloc_messages(rd_req, GFP_NOFS);
+	err = ceph_osdc_alloc_messages(rd_req, GFP_KERNEL);
 	if (err)
 		goto out_unlock;
 
 	wr_req = ceph_osdc_alloc_request(&fsc->client->osdc, NULL,
-					 1, false, GFP_NOFS);
+					 1, false, GFP_KERNEL);
 	if (!wr_req) {
 		err = -ENOMEM;
 		goto out_unlock;
@@ -2495,7 +2495,7 @@ static int __ceph_pool_perm_get(struct ceph_inode_info *ci,
 	ceph_oloc_copy(&wr_req->r_base_oloc, &rd_req->r_base_oloc);
 	ceph_oid_copy(&wr_req->r_base_oid, &rd_req->r_base_oid);
 
-	err = ceph_osdc_alloc_messages(wr_req, GFP_NOFS);
+	err = ceph_osdc_alloc_messages(wr_req, GFP_KERNEL);
 	if (err)
 		goto out_unlock;
 

-- 
2.53.0

