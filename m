From: Sven Peter <sven@kernel.org>
Date: Thu, 06 Aug 2026 17:27:34 +0200
Subject: [PATCH 2/6] nvme-apple: Don't set a DMA direction for commands
 without a data transfer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260806-b4-nvme-fwabi-v1-2-bde19ce8db04@kernel.org>
References: <20260806-b4-nvme-fwabi-v1-0-bde19ce8db04@kernel.org>
In-Reply-To: <20260806-b4-nvme-fwabi-v1-0-bde19ce8db04@kernel.org>
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1006; i=sven@kernel.org;
 h=from:subject:message-id; bh=6Q/s+CU1jpcGZ6EF4+2fc7K8wZes4JUuaLdDIeWZEvE=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1bJCo1Ci7YTJ/Rde1f9ieC46p6heE9usf/Ngm1HjzDnu
 nlx87R1lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACbia8bwm0VC95rI952nKy5O
 k+yrOnvNPvxZiqP1g4rFlnrf6tO1axj+KUirywmJL1G+vHKK1P2DUx+5l/DL5W+7ub7a6YPfq7y
 5/AA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Setting the DMA direction for commands that don't do any transfer likely
triggered the PRP NULL check for which we needed a chicken bit. That bit
has disappeared starting with macOS 15 so let's just do this correctly
instead.

Fixes: 5bd2927aceba ("nvme-apple: Add initial Apple SoC NVMe driver")
Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/nvme/host/apple.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/drivers/nvme/host/apple.c b/drivers/nvme/host/apple.c
index 321502847a2c..f134b5ffb774 100644
--- a/drivers/nvme/host/apple.c
+++ b/drivers/nvme/host/apple.c
@@ -324,7 +324,9 @@ static void apple_nvme_submit_cmd_t8103(struct apple_nvme_queue *q,
 	tcb->length = cmd->rw.length;
 	tcb->command_id = tag;
 
-	if (nvme_is_write(cmd))
+	if (!cmd->common.dptr.prp1)
+		tcb->dma_flags = 0;
+	else if (nvme_is_write(cmd))
 		tcb->dma_flags = APPLE_ANS_TCB_DMA_TO_DEVICE;
 	else
 		tcb->dma_flags = APPLE_ANS_TCB_DMA_FROM_DEVICE;

-- 
2.55.0

