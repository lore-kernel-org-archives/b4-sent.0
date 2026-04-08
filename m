From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v3 0/4] dmaengine: dma-axi-dmac: Some memory related fixes
Date: Wed, 08 Apr 2026 13:42:39 +0100
Message-Id: <20260408-dma-dmac-handle-vunmap-v3-0-2456ad292154@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6DIBBFf8WwLg2ConbV/2i6QBiUxldASRvjv
 xdsmrQLF7O4mXvPWZEDa8ChS7IiC944Mw4hsFOCZCuGBrBRISNKKCeM5lj1Ip7E4as6wH4ZejH
 hMhOEK12olDEUxpMFbZ47+Hb/ZLfUD5BzpMVGa9w82tdu9mnsfSX8SOJTTHANDDKutdC8uopBd
 GNzlmOPosXTX05xyKGBQ2iqq1wTKIv6j7Nt2xs7bu+sFwEAAA==
X-Change-ID: 20260325-dma-dmac-handle-vunmap-84a06df7d133
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775652161; l=943;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=LMqWJzfF94rZChyrIXed1rTS6WeTaHpN2Sas+xgnyR8=;
 b=eiR8vmLkZWNGkruGVJcJLXhrucZQ49hJrYwO99kKDtqx+5Krgy6XkIythBNZgvtd9EjE0FS52
 lSn0kNJPs2OBQdre+ahw3cQjy7IO05Vp9q7AXxKDnlVXVp6AO9mQW20
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here it goes v3. Given there are some discussions about adding devlinks
in damengine, I dropped the patch implementing the .device_release() for
now.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Changes in v3:
 - Drop commit ("dmaengine: dma-axi-dmac: fix use-after-free on unbind")
 - Patch 3:
   * New patch
 - Patch 4:
   * Rework to use DMA Pool API.

---
Nuno Sá (4):
      dmaengine: Fix possible use after free
      dmaengine: dma-axi-dmac: Properly free struct axi_dmac_desc
      dmaengine: dma-axi-dmac: Drop struct clk from main struct
      dmaengine: dma-axi-dmac: Fig BUG() on vunmap()

 drivers/dma/dma-axi-dmac.c | 77 +++++++++++++++++++++++++++-------------------
 drivers/dma/dmaengine.c    |  3 +-
 2 files changed, 47 insertions(+), 33 deletions(-)
---
base-commit: b7560798466a07d9c3fb011698e92c335ab28baf
change-id: 20260325-dma-dmac-handle-vunmap-84a06df7d133
--

Thanks!
- Nuno Sá

