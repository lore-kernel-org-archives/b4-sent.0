From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v4 0/4] dmaengine: dma-axi-dmac: Some memory related fixes
Date: Fri, 24 Apr 2026 18:40:13 +0100
Message-Id: <20260424-dma-dmac-handle-vunmap-v4-0-90f43412fdc0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNTQ7CIBAF4KsY1mJgoLR15T2MC1oGxdifFCWap
 ncXaowa08UsXmbmeyPxODj0ZLsayYDBede1Mcj1itQn3R6ROhMzAQaKCcioaXSamsatuSANt7b
 RPS2kZsrY3HAhSHzuB7TuPsP7wyv7W3XG+pq0dHFy/toNj7k58HT3LlFLJYFTRisUKJW12qpyp
 1t96Y6bumtIagnw7eSLDkSHAbdlZhkWefXniI8jWbHoiOiAzJQ2UALP5I8zTdMTDW94kl8BAAA
 =
X-Change-ID: 20260325-dma-dmac-handle-vunmap-84a06df7d133
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777052415; l=1159;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=xZL6Q8zEKVnEPzDpoBXi4fY8xiM5sA7I1SfhLEzZKX0=;
 b=JKSeLtIo/vPqAO6NN5tYwb+qVSO7rPZFygVH2lNQM1plz3wgkbO5ZoPrel5PuVLNbkQlWpr3U
 GGpJPym9naYAR+4G9SdceW4y2qCxka3zA8bCCQ4fmGhW2/j+BWGp3zj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here it goes v3. Given there are some discussions about adding devlinks
in damengine, I dropped the patch implementing the .device_release() for
now.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Changes in v4:
- Patch 1:
  * Commit reword as per Frank suggestion
- Patch 2:
  * Commit reword as per Frank suggestion
- Patch 3:
  * Commit reword as per Frank suggestion
- Patch 4:
  * Commit subjectreword as per Frank suggestion
  * Added Fixes tag
- Link to v3: https://patch.msgid.link/20260408-dma-dmac-handle-vunmap-v3-0-2456ad292154@analog.com

---
Nuno Sá (4):
      dmaengine: Fix possible use after free
      dmaengine: dma-axi-dmac: Properly free struct axi_dmac_desc
      dmaengine: dma-axi-dmac: Drop struct clk from main struct
      dmaengine: dma-axi-dmac: use DMA pool to manange DMA descriptor

 drivers/dma/dma-axi-dmac.c | 77 +++++++++++++++++++++++++++-------------------
 drivers/dma/dmaengine.c    |  3 +-
 2 files changed, 47 insertions(+), 33 deletions(-)
---
base-commit: b7560798466a07d9c3fb011698e92c335ab28baf
change-id: 20260325-dma-dmac-handle-vunmap-84a06df7d133
--

Thanks!
- Nuno Sá

