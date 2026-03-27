From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 27 Mar 2026 16:58:39 +0000
Subject: [PATCH v2 2/4] dmaengine: dma-axi-dmac: Properly free struct
 axi_dmac_desc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260327-dma-dmac-handle-vunmap-v2-2-021f95f0e87b@analog.com>
References: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
In-Reply-To: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774630718; l=889;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=FiW+zvQ0Vg5geNpbllXV8K8Pu2uQGa6K1A0veJRrIZI=;
 b=ZqTnBw5uXCp7pFYSt/5bMscZVq8LUTat+TLk9lcl/HYXupAduoZ+/etCrHJx2iu/Lrrppym8+
 XVRcBW4z8eGC+jBms4+uT94JNNhP/WrH/N4bIcVGvwrHSZdfVinVc5E
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In axi_dmac_prep_peripheral_dma_vec() if we fail after calling
axi_dmac_alloc_desc(), we need to use axi_dmac_free_desc() to fully free
the descriptor.

Fixes: 74609e568670 ("dmaengine: dma-axi-dmac: Implement device_prep_peripheral_dma_vec")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dma-axi-dmac.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/dma/dma-axi-dmac.c b/drivers/dma/dma-axi-dmac.c
index 45c2c8e4bc45..127c3cf80a0e 100644
--- a/drivers/dma/dma-axi-dmac.c
+++ b/drivers/dma/dma-axi-dmac.c
@@ -769,7 +769,7 @@ axi_dmac_prep_peripheral_dma_vec(struct dma_chan *c, const struct dma_vec *vecs,
 	for (i = 0; i < nb; i++) {
 		if (!axi_dmac_check_addr(chan, vecs[i].addr) ||
 		    !axi_dmac_check_len(chan, vecs[i].len)) {
-			kfree(desc);
+			axi_dmac_free_desc(desc);
 			return NULL;
 		}
 

-- 
2.53.0

