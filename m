From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 27 Jan 2026 14:28:22 +0000
Subject: [PATCH 1/5] dmaengine: Document cyclic transfer for
 dmaengine_prep_peripheral_dma_vec()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260127-axi-dac-cyclic-support-v1-1-b32daca4b3c7@analog.com>
References: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
In-Reply-To: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769524107; l=1056;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=BEZcMmBHOTRyRMifvwwtob/CQu0G30yF4zSIlGcRh/A=;
 b=+rj34g4ATJGfj27smTYYekoyiIGtId+A82QX3yUpTjSCgpcqfU1X2K1iNpCCQdbBUz499KR7k
 ntvXbYzqc0+ARbEZQFAbRTxI5HlS9djcLmDq0nt87xDrl590GLY1gsC
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document that the DMA_PREP_REPEAT flag can be used with the
dmaengine_prep_peripheral_dma_vec() to mark a transfer as cyclic similar
to dmaengine_prep_dma_cyclic().

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 include/linux/dmaengine.h | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/include/linux/dmaengine.h b/include/linux/dmaengine.h
index 99efe2b9b4ea..b3d251c9734e 100644
--- a/include/linux/dmaengine.h
+++ b/include/linux/dmaengine.h
@@ -996,7 +996,8 @@ static inline struct dma_async_tx_descriptor *dmaengine_prep_slave_single(
  * @vecs: The array of DMA vectors that should be transferred
  * @nents: The number of DMA vectors in the array
  * @dir: Specifies the direction of the data transfer
- * @flags: DMA engine flags
+ * @flags: DMA engine flags - DMA_PREP_REPEAT can be used to mark a cyclic
+ *         DMA transfer
  */
 static inline struct dma_async_tx_descriptor *dmaengine_prep_peripheral_dma_vec(
 	struct dma_chan *chan, const struct dma_vec *vecs, size_t nents,

-- 
2.52.0

