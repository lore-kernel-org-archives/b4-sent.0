From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH RESEND v3 0/2] dmaengine: axi-dmac: move to device managed
 probe
Date: Thu, 28 Mar 2024 14:58:49 +0100
Message-Id: <20240328-axi-dmac-devm-probe-v3-0-523c0176df70@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJl3BWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIxMDYyML3cSKTN2U3MRk3ZTUslzdgqL8pFTdJBMT41TLlFTL5DRDJaDOgqL
 UtMwKsKnRSkGuwa5+LkqxtbUAm41oy20AAAA=
To: dmaengine@vger.kernel.org
Cc: Vinod Koul <vkoul@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 stable@kernel.org, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711634330; l=934;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=m0ql8MFfa+1VMdbESosL+rnjy6vxsXVOUNl8/db4URE=;
 b=ei4DCpTy3lc2ngzogdcWrECGRv9vuGjJVr3hDLguDWWPZ11s+wcxFrMXuYOmuqPfbVAAyu7gD
 Fc4E02yhy0jB/b6xwjQ71/KkUBBZm1QOEy9mNdX14QOMt4ynKpWTQXj
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Added a new patch so we can easily backport a possible race in the
unbind path.

Vinod, I'm just resending these patches again (as merge window is now
over. I applied and compiled them on top of the next branch. Tip in:

8b7149803af17 ("MAINTAINERS: Drop Gustavo Pimentel as EDMA Reviewer")

---
Changes in v3:
- Patch 1
  * New patch.
- Patch 2
  * Updated commit message (request_irq() is no longer moved).
- Link to v2: https://lore.kernel.org/r/20240219-axi-dmac-devm-probe-v2-1-1a6737294f69@analog.com

---
Nuno Sa (2):
      dmaengine: axi-dmac: fix possible race in remove()
      dmaengine: axi-dmac: move to device managed probe

 drivers/dma/dma-axi-dmac.c | 78 ++++++++++++++++++++--------------------------
 1 file changed, 34 insertions(+), 44 deletions(-)
---
base-commit: 8b7149803af174f3184d97c779faa1c7608da5af
change-id: 20240328-axi-dmac-devm-probe-b443e9de9cf1
--

Thanks!
- Nuno Sá

