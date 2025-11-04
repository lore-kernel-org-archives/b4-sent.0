From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH RESEND 0/4] dma: dma-axi-dmac: fixes and improvements
Date: Tue, 04 Nov 2025 16:22:24 +0000
Message-Id: <20251104-axi-dmac-fixes-and-improvs-v1-0-3e6fd9328f72@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEAoCmkC/x2MMQqEMBAAvyJb34KJpvDqs71CS7FYkvVuC6NkQ
 YTg3w2WAzOTQTkJK7yrDIkPUdliAfOqwP8p/hglFAZbW2dM3SKdgmElj4ucrEgxoKx72g5Fbig
 4Y6mxnYcy2BM/UuknGPqx/35gvq4biUob43QAAAA=
X-Change-ID: 20251104-axi-dmac-fixes-and-improvs-e3ad512a329c
To: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762273345; l=799;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=o7+zi7GXqBkQz18IsHHUAZB/ZiKichtFr8qpatSjrio=;
 b=CP+rdy2Ry0Bg7k8FJBgMtRxfz4jFy8Qn7wAFi54kfHeJVq79GhUxjYsf/rGuxNEpaaLjQt/h2
 8RTjgXeyz/PBtG3L2SQ86aCjDsSerZZgCAu9v2W/eOcSw9vIpsNqlZW
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds some fixes to the DMA core with respect with cyclic
transfer and HW scatter gather.

It also adds some improvements. Most notably for allowing bigger that
32bits DMA masks so we do not have to rely on bounce buffers from
swiotlb.

---
Nuno Sá (4):
      dma: dma-axi-dmac: fix SW cyclic transfers
      dma: dma-axi-dmac: fix HW scatter-gather not looking at the queue
      dma: dma-axi-dmac: support bigger than 32bits addresses
      dma: dma-axi-dmac: simplify axi_dmac_parse_dt()

 drivers/dma/dma-axi-dmac.c | 48 +++++++++++++++++++++++++++++++---------------
 1 file changed, 33 insertions(+), 15 deletions(-)
---
base-commit: 398035178503bf662281bbffb4bebce1460a4bc5
change-id: 20251104-axi-dmac-fixes-and-improvs-e3ad512a329c
--

Thanks!
- Nuno Sá

