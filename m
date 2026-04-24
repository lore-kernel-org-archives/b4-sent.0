From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 24 Apr 2026 18:40:14 +0100
Subject: [PATCH v4 1/4] dmaengine: Fix possible use after free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260424-dma-dmac-handle-vunmap-v4-1-90f43412fdc0@analog.com>
References: <20260424-dma-dmac-handle-vunmap-v4-0-90f43412fdc0@analog.com>
In-Reply-To: <20260424-dma-dmac-handle-vunmap-v4-0-90f43412fdc0@analog.com>
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777052415; l=1250;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=J8FQACGd3OeySCyq4xc/4O/tuVwcfMAzSY7wby2Naks=;
 b=H17/8Zb+644xB77ycJ5potIObMnRnYyuLvr7PBnDpo3PvOfGkHcoaRNSRuwzwQ2Tn8s8zZbRd
 KuOTEA3ypmOCn6oQUmiqdfkToJ307HXTxnkpo92fXlVzotmAkBiZefo
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In dma_release_channel(), check chan->device->privatecnt after call
dma_chan_put(). However, dma_chan_put() call dma_device_put() which could
release the last reference of the device if the DMA provider is already
gone and hence free it.

Fixes it by moving dma_chan_put() after the check.

Fixes: 0f571515c332 ("dmaengine: Add privatecnt to revert DMA_PRIVATE property")
Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/dma/dmaengine.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/dmaengine.c b/drivers/dma/dmaengine.c
index 405bd2fbb4a3..9049171df857 100644
--- a/drivers/dma/dmaengine.c
+++ b/drivers/dma/dmaengine.c
@@ -905,11 +905,12 @@ void dma_release_channel(struct dma_chan *chan)
 	mutex_lock(&dma_list_mutex);
 	WARN_ONCE(chan->client_count != 1,
 		  "chan reference count %d != 1\n", chan->client_count);
-	dma_chan_put(chan);
 	/* drop PRIVATE cap enabled by __dma_request_channel() */
 	if (--chan->device->privatecnt == 0)
 		dma_cap_clear(DMA_PRIVATE, chan->device->cap_mask);
 
+	dma_chan_put(chan);
+
 	if (chan->slave) {
 		sysfs_remove_link(&chan->dev->device.kobj, DMA_SLAVE_NAME);
 		sysfs_remove_link(&chan->slave->kobj, chan->name);

-- 
2.54.0

