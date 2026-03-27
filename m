From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/4] dmaengine: dma-axi-dmac: Some memory related fixes
Date: Fri, 27 Mar 2026 16:58:37 +0000
Message-Id: <20260327-dma-dmac-handle-vunmap-v2-0-021f95f0e87b@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6DIBBFf8WwLg2CpY9V/6NxgTAojYIBJW0M/
 16w6bKLWZzMvfdsKIA3ENCt2pCHaIJxNgM9VEgOwvaAjcqMKKGcMHrCahLlJM5fNQKOq53EjC+
 NIFzps6oZQ7k8e9DmtQ8/2i+HtXuCXMpaSQwmLM6/d3OsS+4n4f8kscYEd8Cg4VoLza93YcXo+
 qN0E2pTSh9SV3dOzwAAAA==
X-Change-ID: 20260325-dma-dmac-handle-vunmap-84a06df7d133
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Eliza Balas <eliza.balas@analog.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774630718; l=2035;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=sIUaoSXsT5CAZce6MTex4xhkMIXKMV1V7N/fTuD9Qns=;
 b=XjJ008vde2HzUu9jC0uuA6Uklh1HpL/1Ng0PNAeXfUl+yidN+Ro5JearkUJLNuWsnnaQSJdTh
 RU1hmVwAuNDAMEWpaoAsUjYs2TAiEbgPpBEEYu4csnRl56qy+9zizpw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ok, I rushed into v2 because I saw (based on AI review) that I already
had some fundamental issues. Some fairly straight (a bit embarrassing tbh)
but others not so much. Another thing to notice is that I changed the
order between "fix use-after-free on unbind" and "Defer freeing DMA
descriptors" because it just makes more sense given that using the
worker only works 100% if we don't have our DMA object bounded with the
platform driver.

Anyways, more details on the changelog.

Also note the addition of two new patches. The dmaengine one seems legit
but I want to note it was just by code inspection.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Changes in v2:
- Patch 1:
  * New patch.
- Patch 2:
  * New patch.
- Patch 3:
  * Use __free() to allocate the ojject so we don't leak in early
    errors. Note that after dmaenginem_async_device_register(), the
    object lifetime is handled by dmaengine;
  * Move get_device() to after registering the device;
  * Still allow to free DMA descriptors in axi_dmac_terminate_all();
  * Use spin_lock_irqsave() to avoid possible deadlocks. 
  * Include spinlock.h
- Patch 4:
  * Include workqueue.h;
  * Save struct device directly in struct axi_dmac_desc and get a
    reference when allocating. Give the reference when freeing the
    descriptor.
- Link to v1: https://patch.msgid.link/20260326-dma-dmac-handle-vunmap-v1-0-be3e46ffaf69@analog.com

---
Eliza Balas (1):
      dmaengine: dma-axi-dmac: Defer freeing DMA descriptors

Nuno Sá (3):
      dmaengine: Fix possuible use after free
      dmaengine: dma-axi-dmac: Properly free struct axi_dmac_desc
      dmaengine: dma-axi-dmac: fix use-after-free on unbind

 drivers/dma/dma-axi-dmac.c | 122 ++++++++++++++++++++++++++++++++++++---------
 drivers/dma/dmaengine.c    |   3 +-
 2 files changed, 100 insertions(+), 25 deletions(-)
---
base-commit: b7560798466a07d9c3fb011698e92c335ab28baf
change-id: 20260325-dma-dmac-handle-vunmap-84a06df7d133
--

Thanks!
- Nuno Sá

