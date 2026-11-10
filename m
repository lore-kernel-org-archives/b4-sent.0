From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 09 Nov 2026 20:00:34 -0800
Subject: [PATCH rdma-next v3 01/13] RDMA/core: widen the uverbs object key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261109-uet-ib-core-v3-1-3e7e7ffed2e9@broadcom.com>
References: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
In-Reply-To: <20261109-uet-ib-core-v3-0-3e7e7ffed2e9@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283250; l=1286;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=u+nXPfZ0LmyAEAoR1U+2+X3qtGAMbzz65HSY7TilY5Q=;
 b=bHYxjlj+/59loJyAi9T22qMZUnYDem+lB39Z/CmoeRe2ng+ZwL8FJqmAua1x92gfdtI6nGR3I
 dYVfGrtWy+qCUqx3LcwYM5My7gHgZ/3wv9qcs3RsatF8vVzEl9NZpvs
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three more core objects would leave drivers nine object keys, and mlx5
alone uses ten. Add a bit to the object key.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 include/rdma/uverbs_ioctl.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/include/rdma/uverbs_ioctl.h b/include/rdma/uverbs_ioctl.h
index 1aaaadb8daf6..a920e57ce990 100644
--- a/include/rdma/uverbs_ioctl.h
+++ b/include/rdma/uverbs_ioctl.h
@@ -108,7 +108,7 @@ struct uverbs_attr_spec {
  *  object_id, attr_id, method_id
  *
  * Which is a 48 bit value, with most of the bits guaranteed to be zero. Based
- * on the current kernel support this is compressed into 16 bit key for the
+ * on the current kernel support this is compressed into 17 bit key for the
  * radix tree. Since this compression is entirely internal to the kernel the
  * below limits can be revised if the kernel gains additional data.
  *
@@ -144,7 +144,7 @@ enum uapi_radix_data {
 		UVERBS_API_METHOD_KEY_BITS + UVERBS_API_METHOD_KEY_SHIFT - 1,
 		UVERBS_API_METHOD_KEY_SHIFT),
 
-	UVERBS_API_OBJ_KEY_BITS = 5,
+	UVERBS_API_OBJ_KEY_BITS = 6,
 	UVERBS_API_OBJ_KEY_SHIFT =
 		UVERBS_API_METHOD_KEY_BITS + UVERBS_API_METHOD_KEY_SHIFT,
 	UVERBS_API_OBJ_KEY_NUM_CORE = 20,

-- 
2.56.0

