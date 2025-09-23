From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH RESEND 0/4] dma: dma-axi-dmac: fixes and improvements
Date: Tue, 23 Sep 2025 09:23:34 +0100
Message-Id: <20250923-b4-dev-axi-dmac-fixes-v1-0-5896dcbbd909@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAZZ0mgC/x3LuwqDQBBG4VeRqR3QIQZMra2FKSXFXv5NpvDCL
 oggvrtLyo/DOSkhKhK9ipMidk26Lhl1WZD7meULVp9NUklTtSJsH+yxszmU/WwcBz2Q2NrwlOA
 boHWU3y3iH/I60di/+6Gjz3Xddxj4728AAAA=
X-Change-ID: 20250922-b4-dev-axi-dmac-fixes-bbf62fd5ee9c
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Paul Cercueil <paul@crapouillou.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758615815; l=794;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=aEcU6mSTdWkmiEX7gNxqh2qLkoNW20dvqKm8ckSwD/c=;
 b=jtQbHQyTX3z+s2B0dfVGKudcqIclK98s6CBhhMTYpem83HtdpHKle4a474nE88KR6SkLuJ77E
 Tgxc6uH7uxyBNAnpfyZ0Q0rQDoVBo5IiOdNTpZ+phcEKTn0DBwjs6K+
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
base-commit: cc0bacac6de7763a038550cf43cb94634d8be9cd
change-id: 20250922-b4-dev-axi-dmac-fixes-bbf62fd5ee9c
--

Thanks!
- Nuno Sá

