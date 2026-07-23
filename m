From: Xiubo Li <xiubo.li@clyso.com>
Date: Thu, 23 Jul 2026 13:47:42 +0800
Subject: [PATCH 1/2] ceph: use GFP_NOFS for cap flush allocation in
 writeback path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-b4-gfp_nofs-v1-1-c06b40354ec9@clyso.com>
References: <20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com>
In-Reply-To: <20260723-b4-gfp_nofs-v1-0-c06b40354ec9@clyso.com>
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784785666; l=1682;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=ZrpOLLgIzASawCWfTKDXlCq3HzO5pZbOM91CKtXE5rg=;
 b=b2KftckOo4HLm6R9Gb4GDH6A7nK84KzexuI0nQCZZtZIMROqHAk1lKjYNUPCmRMwanHSnbxf5
 owGK/AVfqFVBI0yhSZoXQ/+hjauAbx0kJPxC3D070RMFTb7M+MTYNu0
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ceph_alloc_cap_flush() is called from ceph_writepages_start() inside
the writeback layer, where other allocations in the same path
(ceph_osdc_alloc_request, ceph_osdc_alloc_messages) already use
GFP_NOFS.  A GFP_KERNEL allocation here can trigger direct reclaim
that recursively enters the filesystem writeback path:

  ceph_writepages_start()                       // inode A writeback
    ceph_alloc_cap_flush()
      kmem_cache_alloc(..., GFP_KERNEL)
        [direct reclaim]
          try_to_free_pages()
            shrink_slab()
              super_cache_scan()
                prune_icache_sb()
                  inode_lru_isolate()
                    iput() -> evict(inode_B)
                      [inode_B has dirty pages]
                      filemap_flush()
                        ceph_writepages_start()  // re-enters writeback
                          ceph_alloc_cap_flush()
                            -> RECURSION / STACK OVERFLOW

All 11 callers of ceph_alloc_cap_flush() are in write or writeback
contexts: writepages (x2), write_iter, fallocate, copy_file_range,
setxattr, setattr, and page_mkwrite.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
 fs/ceph/caps.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/ceph/caps.c b/fs/ceph/caps.c
index f8d898ad091e..cbaebeac06f7 100644
--- a/fs/ceph/caps.c
+++ b/fs/ceph/caps.c
@@ -1875,7 +1875,7 @@ struct ceph_cap_flush *ceph_alloc_cap_flush(void)
 {
 	struct ceph_cap_flush *cf;
 
-	cf = kmem_cache_alloc(ceph_cap_flush_cachep, GFP_KERNEL);
+	cf = kmem_cache_alloc(ceph_cap_flush_cachep, GFP_NOFS);
 	if (!cf)
 		return NULL;
 

-- 
2.53.0

