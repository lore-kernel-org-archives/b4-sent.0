From: Nikita Shubin <n.shubin@yadro.com>
Subject: [PATCH 0/3] dmaengine: ioatdma: Fix mem leakage series
Date: Fri, 24 May 2024 13:24:45 +0300
Message-Id: <20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO1qUGYC/x3LywqEMAyF4VeRrCegRfHyKjKLtI2ahVUSGQbEd
 7e6/M/hO8FYhQ2G4gTln5hsKUf1KSAslGZGibnBla4uG1ejbHTElXCSPxtSN4UQqfex7SEbT8b
 olVJYHrWSHazPsSu/Iq/j97puo6NkF3gAAAA=
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Logan Gunthorpe <logang@deltatee.com>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <n.shubin@yadro.com>, 
 Andy Shevchenko <andy.shevchenko@gmail.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716546287; l=737;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=CrQprNIxi//+Z+cGBKn4Waq6Mg5oFx7AbnKkwtEfBjE=;
 b=A65t7okArOSAbkRGfS8XIdJSEtnY1eofhkJ67p2bUVcBKNM65EhPIQlRCcHuefQIRXEYGuxpkcqb
 0pfpc8vLCljl7kZuHmzGmBpIfRBGq9Rsje3JoDhhpHnxKDR4oszc
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Started with observing leakage in patch 3, ivestigating revealed much
more problems in probing error path.

Andy you are always welcome to review if you have a spare time.

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
Nikita Shubin (3):
      dmaengine: ioatdma: Fix leaking on version mismatch
      dmaengine: ioatdma: Fix error path in ioat3_dma_probe()
      dmaengine: ioatdma: Fix kmemleak in ioat_pci_probe()

 drivers/dma/ioat/init.c | 55 ++++++++++++++++++++++++++-----------------------
 1 file changed, 29 insertions(+), 26 deletions(-)
---
base-commit: 6d69b6c12fce479fde7bc06f686212451688a102
change-id: 20240524-ioatdma-fixes-a8fccda9bd79

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

