From: Nikita Shubin <n.shubin@yadro.com>
Subject: [PATCH v2 0/3] dmaengine: ioatdma: Fix mem leakage series
Date: Tue, 28 May 2024 09:09:22 +0300
Message-Id: <20240528-ioatdma-fixes-v2-0-a9f2fbe26ab1@yadro.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABJ1VWYC/3WNMQ6DMAxFr4I8NxVEIKBT71ExOI5TPEAqB6Eix
 N0b2Du+9/X0d0iswgkexQ7KqySJcwZ7K4BGnN9sxGcGW9q6bGxtJOLiJzRBvpwMdoHIY+9820N
 uHCY2TnGm8awmTAvrOXyUryLb15B5lLRE3a7ftTrtv4u1MqVxbdeEKrRIRM8NvcY7xQmG4zh+i
 CioVsMAAAA=
To: Vinod Koul <vkoul@kernel.org>, Dave Jiang <dave.jiang@intel.com>, 
 Logan Gunthorpe <logang@deltatee.com>
Cc: Andy Shevchenko <andy.shevchenko@gmail.com>, 
 Nikita Shubin <nikita.shubin@maquefel.me>, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux@yadro.com, 
 Nikita Shubin <n.shubin@yadro.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716876563; l=1143;
 i=n.shubin@yadro.com; s=20230718; h=from:subject:message-id;
 bh=yL9QuRyCclHUhhy3AcGDuaeU09XaZ3aXaTF2FrRGqEQ=;
 b=K4gvr1A5/gyMVLHQfIfsxddXfjDgycKJo70pdAg85txaURyEa+qlUCFPsS5oPFoUE7Sg1sKc6lG8
 rm8wd6zPD+hBhf85i+hCRkyQERBYdLmxp7yd95vJWjTCJIIqhNon
X-Developer-Key: i=n.shubin@yadro.com; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for n.shubin@yadro.com/20230718 with auth_id=161
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Started with observing leakage in patch 3, investigating revealed much
more problems in probing error path.

Andy you are always welcome to review if you have a spare time.

Thank you Andy and Markus for your comments.

Signed-off-by: Nikita Shubin <n.shubin@yadro.com>
---
Changes in v2:
- dmaengine: ioatdma: Fix error path in ioat3_dma_probe():
  Markus:
    - fix typo

- dmaengine: ioatdma: Fix kmemleak in ioat_pci_probe()
  Andy:
    - s/int/unsigned int/
    - fix spelling errors
    - trimmed kmemleak reports

- Link to v1: https://lore.kernel.org/r/20240524-ioatdma-fixes-v1-0-b785f1f7accc@yadro.com

---
Nikita Shubin (3):
      dmaengine: ioatdma: Fix leaking on version mismatch
      dmaengine: ioatdma: Fix error path in ioat3_dma_probe()
      dmaengine: ioatdma: Fix kmemleak in ioat_pci_probe()

 drivers/dma/ioat/init.c | 54 ++++++++++++++++++++++++++-----------------------
 1 file changed, 29 insertions(+), 25 deletions(-)
---
base-commit: 6d69b6c12fce479fde7bc06f686212451688a102
change-id: 20240524-ioatdma-fixes-a8fccda9bd79

Best regards,
-- 
Nikita Shubin <n.shubin@yadro.com>

