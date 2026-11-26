From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 11:02:09 +0900
Subject: [PATCH v4 1/5] block: add an accessor for the active zone limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-zoned-ufs-v4b-v4-1-f90239d12a55@samsung.com>
References: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
In-Reply-To: <20261126-zoned-ufs-v4b-v4-0-f90239d12a55@samsung.com>
To: qemu-devel@nongnu.org
Cc: Jeuk Kim <jeuk20.kim@samsung.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Fam Zheng <fam@euphon.net>, Kevin Wolf <kwolf@redhat.com>, 
 Hanna Reitz <hreitz@redhat.com>, qemu-block@nongnu.org, 
 Fabiano Rosas <farosas@suse.de>, Laurent Vivier <lvivier@redhat.com>, 
 Pierrick Bouvier <pierrick.bouvier@oss.qualcomm.com>, 
 Niklas Cassel <cassel@kernel.org>, Damien Le Moal <dlemoal@kernel.org>, 
 Sam Li <faithilikerun@gmail.com>, Stefan Hajnoczi <stefanha@redhat.com>, 
 Stanley Jhu <stanleyjhu@google.com>, 
 Keoseong Park <keosung.park@samsung.com>, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795658528; l=1796;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=TBiFpQFT/9RXsABdcgs7OOsn9LXZG6k+QhQ33mxHGPc=;
 b=xyA/YlLPKFFMXWspm2MVtP0IZK8h1oSznI7SAdADwQe+GKbGf8ueQo9EBaoN8BbnfRJzlppVF
 Xq1UziodUyaD7mrlRiyoQ7GB1FVdUiphNQlzT3Uz6AxgY7jWt4R7YON
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add blk_get_max_active_zones() next to blk_get_max_open_zones(). A
device model whose protocol cannot report an active zone limit, such as
ZBC, needs it to reject a backend whose limit a guest could reach.

Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
 block/block-backend.c             | 11 +++++++++++
 include/system/block-backend-io.h |  1 +
 2 files changed, 12 insertions(+)

diff --git a/block/block-backend.c b/block/block-backend.c
index 397ec9ed5a..1e591a81b9 100644
--- a/block/block-backend.c
+++ b/block/block-backend.c
@@ -2371,6 +2371,17 @@ uint64_t blk_get_zone_capacity(BlockBackend *blk)
     return bs ? bs->bl.zone_capacity : 0;
 }
 
+/*
+ * Returns the maximum number of active zones of a zoned backend, or 0 if
+ * there is no limit or @blk is not zoned.
+ */
+uint32_t blk_get_max_active_zones(BlockBackend *blk)
+{
+    BlockDriverState *bs = blk_bs(blk);
+    IO_CODE();
+    return bs ? bs->bl.max_active_zones : 0;
+}
+
 /* Returns the optimal write zeroes alignment, in bytes; guaranteed nonzero */
 uint32_t blk_get_pwrite_zeroes_alignment(BlockBackend *blk)
 {
diff --git a/include/system/block-backend-io.h b/include/system/block-backend-io.h
index 7c958843b4..aa6303c8a1 100644
--- a/include/system/block-backend-io.h
+++ b/include/system/block-backend-io.h
@@ -125,6 +125,7 @@ uint64_t blk_get_zone_size(BlockBackend *blk);
 BlockZoneModel blk_get_zone_model(BlockBackend *blk);
 uint32_t blk_get_max_open_zones(BlockBackend *blk);
 uint64_t blk_get_zone_capacity(BlockBackend *blk);
+uint32_t blk_get_max_active_zones(BlockBackend *blk);
 
 int coroutine_fn blk_co_copy_range(BlockBackend *blk_in, int64_t off_in,
                                    BlockBackend *blk_out, int64_t off_out,

-- 
2.43.0

