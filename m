From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/2] dmaengine: dma-axi-dmac: Some memory related fixes
Date: Thu, 26 Mar 2026 13:37:34 +0000
Message-Id: <20260326-dma-dmac-handle-vunmap-v1-0-be3e46ffaf69@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7kBM1IpXKS5iZmynaJRERRDv3
 lgXf/H4vHdA5CAcockOCLxJlMknyB8ZuI/1b0ahxKCVrpTRJdJorzlMLw2M2+pHO2NdWFVR/6T
 cGEjyHLiX/R9+tTfHtfuyW64anOcP5evccXoAAAA=
X-Change-ID: 20260325-dma-dmac-handle-vunmap-84a06df7d133
To: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>, Eliza Balas <eliza.balas@analog.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774532297; l=1511;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=UsmwhaGP+e5WwipGleUgGHqJL8dBThe2HRGuRQN3g7A=;
 b=nkgfcGteA/fbgayHV/UsxRPyYRHyEnS84P0LXM3iOYJyz450JJ50y/a1koPPn0jI9C+yeplRj
 ZLQMLUIgIX6CavXkS6RHXcPPaWYlYkLKQKiXSTd67g5Yn48ahq/rd8S
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series aims to fix some issues with axi-dmac driver related to
memory:

1. When testing the IP on a microblaze based platform, we get vmalloced
   memory when allocation DMAC descriptors which will lead to BUG() when
   releasing them. More on the commit message.
2. The second is related with a well known issues with devm allocations
   of reference counted objects on a provider-consumer relationship.
   Seems to be a knows issue in dmaengine but fix it in the AXI-DMAC
   driver by properly implementing .the device_release() callback.

Didn't add any fixes tag because for 1), it was not an issue when the
drivers was first implemented (just triggered very recently) and for 2),
because it seems like a well known issue. Anyways, for 2) seems more
reasonable to have a fixes tag (IMO) if you want me to add one.

Also note that my signoff on Eliza patch is merely because I'm sending
the patch on her behalf. I had not part in the solution (just improved
comments and commit message a bit).

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Eliza Balas (1):
      dmaengine: dma-axi-dmac: Defer freeing DMA descriptors

Nuno Sá (1):
      dmaengine: dma-axi-dmac: fix use-after-free on unbind

 drivers/dma/dma-axi-dmac.c | 95 +++++++++++++++++++++++++++++++++++++---------
 1 file changed, 78 insertions(+), 17 deletions(-)
---
base-commit: b7560798466a07d9c3fb011698e92c335ab28baf
change-id: 20260325-dma-dmac-handle-vunmap-84a06df7d133
--

Thanks!
- Nuno Sá

