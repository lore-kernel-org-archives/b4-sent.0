From: Nikita Shubin <n.shubin@yadro.com>
Date: Fri, 24 May 2024 13:24:48 +0300
Subject: [PATCH 3/3] dmaengine: ioatdma: Fix kmemleak in ioat_pci_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240524-ioatdma-fixes-v1-3-b785f1f7accc@yadro.com>
References: <20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com>
In-Reply-To: <20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com>
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Logan Gunthorpe <logang@deltatee.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <n.shubin@yadro.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716546287; l=3610;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=4F6Y41syeecTB0IjN8FIDbj5S9PP/ayLta+MVmDUoqA=;
 b=FI8qyvqmkOkuefCviyEdsbJ7x1T5n4nUv3F7H/eVvjt8dZNAV5mKqVrl8n/l/gJT7x/3wlYW6GLA
 iv1HrOdUBK4kgE8i6OQykyxaMAXaV1uGBeakzhC85NoqMgkUb78s
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If probing fails we end up with leaking ioatdma_device and each
allocated channel.

Following kmemleak is easy to be reproduced by injecting error in
ioat_alloc_chan_resources() when doing ioat_dma_self_test().

unreferenced object 0xffff888014ad5800 (size 1024):
  comm "modprobe", pid 73, jiffies 4294681749
  hex dump (first 32 bytes):
    00 10 00 13 80 88 ff ff 00 c0 3f 00 00 c9 ff ff  ..........?.....
    00 ce 76 13 80 88 ff ff 00 00 00 00 00 00 00 00  ..v.............
  backtrace (crc 1f353f55):
    [<ffffffff827692ca>] kmemleak_alloc+0x4a/0x80
    [<ffffffff81430600>] kmalloc_trace+0x270/0x2f0
    [<ffffffffa000b7d1>] ioat_pci_probe+0xc1/0x1c0 [ioatdma]
    [<ffffffff8199376a>] local_pci_probe+0x7a/0xe0
    [<ffffffff81995189>] pci_call_probe+0xd9/0x2c0
    [<ffffffff81995975>] pci_device_probe+0xa5/0x170
    [<ffffffff81f5f89b>] really_probe+0x14b/0x510
    [<ffffffff81f5fd4a>] __driver_probe_device+0xda/0x1f0
    [<ffffffff81f5febf>] driver_probe_device+0x4f/0x120
    [<ffffffff81f6028a>] __driver_attach+0x14a/0x2b0
    [<ffffffff81f5c56c>] bus_for_each_dev+0xec/0x160
    [<ffffffff81f5ee1b>] driver_attach+0x2b/0x40
    [<ffffffff81f5e0d3>] bus_add_driver+0x1a3/0x300
    [<ffffffff81f61db3>] driver_register+0xa3/0x1d0
    [<ffffffff8199325b>] __pci_register_driver+0xeb/0x100
    [<ffffffffa003009c>] 0xffffffffa003009c

repeated for each ioatdma channel:

unreferenced object 0xffff8880148e5c00 (size 512):
  comm "modprobe", pid 73, jiffies 4294681751
  hex dump (first 32 bytes):
    40 58 ad 14 80 88 ff ff 00 00 00 00 00 00 00 00  @X..............
    01 00 00 00 01 00 00 00 00 00 00 00 00 00 00 00  ................
  backtrace (crc fbc62789):
    [<ffffffff827692ca>] kmemleak_alloc+0x4a/0x80
    [<ffffffff81430600>] kmalloc_trace+0x270/0x2f0
    [<ffffffffa0009641>] ioat_enumerate_channels+0x101/0x2d0 [ioatdma]
    [<ffffffffa000b266>] ioat3_dma_probe+0x4d6/0x970 [ioatdma]
    [<ffffffffa000b891>] ioat_pci_probe+0x181/0x1c0 [ioatdma]
    [<ffffffff8199376a>] local_pci_probe+0x7a/0xe0
    [<ffffffff81995189>] pci_call_probe+0xd9/0x2c0
    [<ffffffff81995975>] pci_device_probe+0xa5/0x170
    [<ffffffff81f5f89b>] really_probe+0x14b/0x510
    [<ffffffff81f5fd4a>] __driver_probe_device+0xda/0x1f0
    [<ffffffff81f5febf>] driver_probe_device+0x4f/0x120
    [<ffffffff81f6028a>] __driver_attach+0x14a/0x2b0
    [<ffffffff81f5c56c>] bus_for_each_dev+0xec/0x160
    [<ffffffff81f5ee1b>] driver_attach+0x2b/0x40
    [<ffffffff81f5e0d3>] bus_add_driver+0x1a3/0x300
    [<ffffffff81f61db3>] driver_register+0xa3/0x1d0

Fixes: bf453a0a18b2 ("dmaengine: ioat: Support in-use unbind")
Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
 drivers/dma/ioat/init.c | 5 ++++-
 1 file changed, 4 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/ioat/init.c b/drivers/dma/ioat/init.c
index 26964b7c8cf1..d0d787cfd0e0 100644
--- a/drivers/dma/ioat/init.c
+++ b/drivers/dma/ioat/init.c
@@ -1348,7 +1348,7 @@ static int ioat_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	struct device *dev = &pdev->dev;
 	struct ioatdma_device *device;
 	u8 version;
-	int err;
+	int err, i;
 
 	err = pcim_enable_device(pdev);
 	if (err)
@@ -1384,6 +1384,9 @@ static int ioat_pci_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 
 	err = ioat3_dma_probe(device, ioat_dca_enabled);
 	if (err) {
+		for (i = 0; i < IOAT_MAX_CHANS; i++)
+			kfree(device->idx[i]);
+		kfree(device);
 		dev_err(dev, "Intel(R) I/OAT DMA Engine init failed\n");
 		return -ENODEV;
 	}

-- 
2.43.2

