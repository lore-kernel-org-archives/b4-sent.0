From: Frank Li <Frank.Li@nxp.com>
Subject: [PATCH 0/3] mtd: rawnand: mxc: set raw chip's to child nand@0
Date: Tue, 10 Mar 2026 15:07:36 -0400
Message-Id: <20260310-gpmi_nand-v1-0-6a665151aa75@nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPhrsGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYwMT3fSC3Mz4vMS8FN00C3MDM9MUCyOL1DQloPqCotS0zAqwWdGxtbU
 ATw+ipVsAAAA=
X-Change-ID: 20260304-gpmi_nand-f87065d828ef
To: Han Xu <han.xu@nxp.com>, Miquel Raynal <miquel.raynal@bootlin.com>, 
 Richard Weinberger <richard@nod.at>, Vignesh Raghavendra <vigneshr@ti.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: imx@lists.linux.dev, linux-mtd@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Max Krummenacher <max.oss.09@gmail.com>, 
 Francesco Dolcini <francesco.dolcini@toradex.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773169659; l=1291;
 i=Frank.Li@nxp.com; s=20240130; h=from:subject:message-id;
 bh=gCNcVUJrbZCTx48PDUwX/v6AbMJIIgCA0UtWdlcRzS8=;
 b=JtKAcoccqwCOput4I+Q0xQSZ8wccSMzXvMjV1Hy9NnjhF2ZqA43LLSYFkQeUDYjNFVKtFmLWB
 XIxkoshi519BUYVKc28LvUWBnuScyy/mJY7iVD9SaFK/mWwa2xzFFpz
X-Developer-Key: i=Frank.Li@nxp.com; a=ed25519;
 pk=I0L1sDUfPxpAkRvPKy7MdauTuSENRq+DnA+G4qcS94Q=
X-Endpoint-Received: by B4 Relay for Frank.Li@nxp.com/20240130 with auth_id=121
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nand-controller.yaml binding requires a child node (e.g. nand@0) under
the NAND controller. However, the driver currently assigns the controller's
of_node directly to the NAND chip.

Search for the first child node with the "nand" prefix and assign it to
chip->of_node. This filters out properties such as "partition" that may be
placed under the controller node in some older DTS files.

Fall back to using the controller's of_node if no suitable child node is
found to maintain backward compatibility.

This issue went unnoticed because the default behavior works for most NAND
chips.

Signed-off-by: Frank Li <Frank.Li@nxp.com>
---
Frank Li (3):
      mtd: rawnand: gpmi: set chip->of_node to nand@0 child node if present
      mtd: rawnand: mxc: set chip->of_node to nand@0 child node if present
      mtd: rawnand: ifc: set chip->of_node to nand@0 child node if present

 drivers/mtd/nand/raw/fsl_ifc_nand.c        | 10 +++++++++-
 drivers/mtd/nand/raw/gpmi-nand/gpmi-nand.c | 11 ++++++++++-
 drivers/mtd/nand/raw/mxc_nand.c            | 10 +++++++++-
 3 files changed, 28 insertions(+), 3 deletions(-)
---
base-commit: fc7b1a72c6cd5cbbd989c6c32a6486e3e4e3594d
change-id: 20260304-gpmi_nand-f87065d828ef

Best regards,
--
Frank Li <Frank.Li@nxp.com>

