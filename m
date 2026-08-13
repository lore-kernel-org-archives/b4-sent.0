From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 13 Aug 2026 17:26:30 +0200
Subject: [PATCH v4 10/14] ata: ahci: fix zero-length DMA handling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-rn102-rn104-series-v4-10-f932ac63efa0@gmail.com>
References: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
In-Reply-To: <20260813-rn102-rn104-series-v4-0-f932ac63efa0@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786634824; l=2309;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=U28sDr11sjBGnOLVYdX8Njnzc51JgZyNTmxXitpA2yk=;
 b=V+u2H5j+C5I8nE/Uu5gVQ8XBi1KELNwV6EbKP5ZO9NaYMn/04u++HAZLe4TdOPSQozjuRcCa/
 K3mTaSg2fQ1AsBeF0mrZfzlMp04V1lN9qRc/S/fFliNrFtgxyYFmo5m
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ata: ahci: fix zero-length DMA handling

Commands without a data buffer must not trigger DMA setup. The previous
code unconditionally programmed PRDT entries and attempted DMA mapping
even when buf_len was zero, leading to invalid PRD tables and spurious
DMA operations.

This patch ensures that DMA mapping, PRDT setup and unmapping are only
performed when buf_len > 0.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 drivers/ata/ahci.c | 33 ++++++++++++++++++---------------
 1 file changed, 18 insertions(+), 15 deletions(-)

diff --git a/drivers/ata/ahci.c b/drivers/ata/ahci.c
index fd27da40f2..ea2df31515 100644
--- a/drivers/ata/ahci.c
+++ b/drivers/ata/ahci.c
@@ -193,30 +193,32 @@ static int ahci_io(struct ahci_port *ahci_port, u8 *fis, int fis_len, void *rbuf
 		const void *wbuf, int buf_len)
 {
 	u32 opts;
-	int sg_count;
+	int sg_count = 0;
 	int ret;
-	void *buf;
-	dma_addr_t buf_dma;
-	enum dma_data_direction dma_dir;
+	void *buf = NULL;
+	dma_addr_t buf_dma = 0;
+	enum dma_data_direction dma_dir = DMA_NONE;
 
 	if (!ahci_link_ok(ahci_port, 1))
 		return -EIO;
 
-	if (wbuf) {
-		buf = (void *)wbuf;
-		dma_dir = DMA_TO_DEVICE;
-	} else {
-		buf = rbuf;
-		dma_dir = DMA_FROM_DEVICE;
-	}
+	if (buf_len > 0) {
+		if (wbuf) {
+			buf = (void *)wbuf;
+			dma_dir = DMA_TO_DEVICE;
+		} else {
+			buf = rbuf;
+			dma_dir = DMA_FROM_DEVICE;
+		}
 
-	buf_dma = dma_map_single(ahci_port->ahci->dev, buf, buf_len, dma_dir);
+		buf_dma = dma_map_single(ahci_port->ahci->dev, buf, buf_len, dma_dir);
+		sg_count = ahci_fill_sg(ahci_port, buf_dma, buf_len);
+	}
 
 	memcpy(ahci_port->cmd_tbl, fis, fis_len);
 
-	sg_count = ahci_fill_sg(ahci_port, buf_dma, buf_len);
 	opts = (fis_len >> 2) | (sg_count << 16);
-	if (wbuf)
+	if (wbuf && buf_len > 0)
 		opts |= CMD_LIST_OPTS_WRITE;
 	ahci_fill_cmd_slot(ahci_port, opts);
 
@@ -225,7 +227,8 @@ static int ahci_io(struct ahci_port *ahci_port, u8 *fis, int fis_len, void *rbuf
 	ret = wait_on_timeout(WAIT_DATAIO,
 			(ahci_port_read(ahci_port, PORT_CMD_ISSUE) & 0x1) == 0);
 
-	dma_unmap_single(ahci_port->ahci->dev, buf_dma, buf_len, dma_dir);
+	if (buf_len > 0)
+		dma_unmap_single(ahci_port->ahci->dev, buf_dma, buf_len, dma_dir);
 
 	return ret;
 }

-- 
2.47.3

