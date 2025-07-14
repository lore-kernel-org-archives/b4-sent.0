From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH RESEND 0/4] dma: dma-axi-dmac: fixes and improvements
Date: Mon, 14 Jul 2025 16:39:06 +0100
Message-Id: <20250714-dev-axi-dmac-fixes-v1-0-c3888b0d671b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
To: dmaengine@vger.kernel.org
Cc: Paul Cercueil <paul@crapouillou.net>, 
 Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752507553; l=827;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=WFtUBJqlAhF8dGqTN2nXC1pQiRHrSopQJ1PTtE6d/n0=;
 b=3ok2fFkrfW44j04sii5qHrmmXVYMG2uUVYPY8C0t+W0kYm8PyeMIvmb+x/kK6BoawGjpMxtUD
 MiLZ3qFXykNDw9HU5R7eRH0/5MeQeNBmot/apEUVAvTHr9U2vnzX1+4
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
base-commit: 3c018bf5a0ee3abe8d579d6a0dda616c3858d7b2
change-id: 20250520-dev-axi-dmac-fixes-41502e41d982
--

Thanks!
- Nuno Sá
-- 
Nuno Sá <nuno.sa@analog.com>

