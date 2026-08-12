From: Xiubo Li <xiubo.li@clyso.com>
Date: Wed, 12 Aug 2026 00:36:26 -0700
Subject: [PATCH v2 2/2] ceph: use GFP_KERNEL consistently in
 __ceph_pool_perm_get()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-b4-gfp_nofs-v2-2-9574af8a417d@clyso.com>
References: <20260812-b4-gfp_nofs-v2-0-9574af8a417d@clyso.com>
In-Reply-To: <20260812-b4-gfp_nofs-v2-0-9574af8a417d@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786520227; l=2293;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=t65MUA8RDPniD/z/fS7QaPun27tPX+DNMHXeSlQgYew=;
 b=MNc89SwKGOeJZneDMP4ikd4abzX8rANwDsg58TXjLXj2FXwnN3SnJPwGYp9+GRQ8+HIPvh/cA
 Cmc+LG3tc5qBrGAuURhdsaQE7LtEpyU8x3KPu6oMdB/NKR+KpeyR7mo
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__ceph_pool_perm_get() has six allocations for building OSD STAT
requests, five of which used GFP_NOFS and one (the page vector
allocation) used GFP_KERNEL, making them inconsistent.

The function is only called from ceph_try_get_caps() and
__ceph_get_caps(), both of which are in the user I/O path (read,
write, fallocate, mmap fault), not in the writeback path.  There is
no risk of recursive writeback, so GFP_NOFS is unnecessarily
restrictive.  Use GFP_KERNEL consistently for all six allocations.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/addr.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/fs/ceph/addr.c b/fs/ceph/addr.c
index e2da3ab9f808..9ea6be704820 100644
--- a/fs/ceph/addr.c
+++ b/fs/ceph/addr.c
@@ -2466,7 +2466,7 @@ static int __ceph_pool_perm_get(struct ceph_inode_info *ci,
 	}
 
 	rd_req = ceph_osdc_alloc_request(&fsc->client->osdc, NULL,
-					 1, false, GFP_NOFS);
+					 1, false, GFP_KERNEL);
 	if (!rd_req) {
 		err = -ENOMEM;
 		goto out_unlock;
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
 
@@ -2534,7 +2534,7 @@ static int __ceph_pool_perm_get(struct ceph_inode_info *ci,
 	}
 
 	pool_ns_len = pool_ns ? pool_ns->len : 0;
-	perm = kmalloc_flex(*perm, pool_ns, pool_ns_len + 1, GFP_NOFS);
+	perm = kmalloc_flex(*perm, pool_ns, pool_ns_len + 1, GFP_KERNEL);
 	if (!perm) {
 		err = -ENOMEM;
 		goto out_unlock;

-- 
2.53.0

