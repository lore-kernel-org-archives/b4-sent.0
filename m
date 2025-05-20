From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/4] dma: dma-axi-dmac: fixes and improvements
Date: Tue, 20 May 2025 14:31:50 +0100
Message-Id: <20250520-dev-axi-dmac-fixes-v1-0-b849ea23f80b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEaELGgC/x3LQQqAIBBA0avErBvQQaG6SrSQnGoWWSiIIN49a
 fn4/AqJo3CCZagQOUuSJ3TocYD9cuFkFN8NpMgqSwo9Z3RF0N9ux0MKJzTaKmKj/TwR9PGN/If
 +rVtrH8O2ypNkAAAA
X-Change-ID: 20250520-dev-axi-dmac-fixes-41502e41d982
To: dmaengine@vger.kernel.org
Cc: Paul Cercueil <paul@crapouillou.net>, 
 Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747747912; l=791;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=bQplEFaliKEKoH2ZDbrTHL2azpLej98i3LppExx6HI0=;
 b=NkJGwJtQBYB6Yx01OpTnqgU1nxKwFcABMV36cmNR6J4JBrbawFnZ/UbT3aKzcYCz3eWvFFQSO
 NXsVRuYuOvwBM88MfPVd7AGMbg3Gp9NdZb3EXU6e+szYD20bxgclwTk
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

