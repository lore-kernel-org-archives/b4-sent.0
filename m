From: Eric Davis <eric.davis@broadcom.com>
Date: Wed, 14 Oct 2026 15:21:10 -0700
Subject: [PATCH rdma-next 01/13] RDMA/core: widen the uverbs object key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-uet-ib-core-v1-1-a0e626117113@broadcom.com>
References: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
In-Reply-To: <20261014-uet-ib-core-v1-0-a0e626117113@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792016478; l=816;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=0pZ/yOMME6vt8eCKBPBTLR9qDLIACpEFlGj8+/VeYZQ=;
 b=+e5IDuhfCMxm8psiTuzSGsWWiYvvQdxzVfr7TrTh500kjvPpvMCdf9S9aZuFC2botKH1B+siY
 srPfKEmxN6JDYX1imfcvuSGKQt8KMj3LNNoVlHW1O0BjNODIOhepJAR
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two more core objects would leave drivers no free object keys. mlx5
alone uses all ten that remain. Add a bit to the object key.

Signed-off-by: Eric Davis <eric.davis@broadcom.com>
---
 include/rdma/uverbs_ioctl.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/rdma/uverbs_ioctl.h b/include/rdma/uverbs_ioctl.h
index 1aaaadb8daf6..f4d93bc3625a 100644
--- a/include/rdma/uverbs_ioctl.h
+++ b/include/rdma/uverbs_ioctl.h
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

