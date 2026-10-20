From: Eric Davis <eric.davis@broadcom.com>
Date: Mon, 19 Oct 2026 20:03:28 -0700
Subject: [PATCH rdma-next v2 01/13] RDMA/core: widen the uverbs object key
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-uet-ib-core-v2-1-8bd654f25370@broadcom.com>
References: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
In-Reply-To: <20261019-uet-ib-core-v2-0-8bd654f25370@broadcom.com>
To: Jason Gunthorpe <jgg@ziepe.ca>, Leon Romanovsky <leon@kernel.org>
Cc: linux-rdma@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Eric Davis <eric.davis@broadcom.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792465414; l=803;
 i=eric.davis@broadcom.com; s=20261014; h=from:subject:message-id;
 bh=1sjWpbXcpF/RMAH3lqB9kxQ2MgDBM9KHKD16FP2T8gE=;
 b=wwGhebSzQGEJE3rwfJx9Gj++6Gy6KRldlGwu3ycsbFzFf3tE84Gxk6SNLmRHoXLXlFcaS8Y0M
 vxizmp1bZJWAdPL8ynl7VaEqoz21FEP7LTZbVggRThMoX2nn+7FoizB
X-Developer-Key: i=eric.davis@broadcom.com; a=ed25519;
 pk=uy3oCTOYBipIPjryXGMynBmtPvbO6qN2FOrduzpiI4A=
X-Endpoint-Received: by B4 Relay for eric.davis@broadcom.com/20261014 with auth_id=1186
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Three more core objects would leave drivers nine object keys, and mlx5
alone uses ten. Add a bit to the object key.

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

