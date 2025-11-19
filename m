From: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
Subject: [PATCH 00/11] mtd: spi-nor: Isolate stacked/parallel support from
 core
Date: Wed, 19 Nov 2025 14:12:59 +0900
Message-Id: <20251119-amd-cleanup-v1-0-c555bd85e6e4@infineon.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANtRHWkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0ML3cTcFN3knNTEvNIC3WQLAyNjC3OjVOPkNCWgjoKi1LTMCrBp0bG
 1tQAn32xhXQAAAA==
X-Change-ID: 20251118-amd-cleanup-c8023872e3cf
To: u-boot@lists.denx.de, Tudor Ambarus <tudor.ambarus@linaro.org>
Cc: Jagan Teki <jagan@amarulasolutions.com>, 
 Michal Simek <michal.simek@amd.com>, Tom Rini <trini@konsulko.com>, 
 Ibai Erkiaga <ibai.erkiaga-elorza@amd.com>, Vignesh R <vigneshr@ti.com>, 
 Prasad Kummari <prasad.kummari@amd.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Havish Mutya <havish.mutya@amd.com>, 
 Ashok Reddy Soma <ashok.reddy.soma@amd.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Daassi Bacem <Bacem.Daassi@infineon.com>, 
 Shinsuke Okada <Shinsuke.Okada@infineon.com>, 
 Hiroyuki Saito <Hiroyuki.Saito2@infineon.com>, 
 Takahiro Kuwano <tkuw584924@gmail.com>, 
 Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763529253; l=1974;
 i=Takahiro.Kuwano@infineon.com; s=20250227; h=from:subject:message-id;
 bh=89mLq7jie3MLaBNSYTnKuDeA/Rgz3c2z5ponCL5nMdw=;
 b=XOysCSdz7SPm34RJzyKvjnjkTbrMnpazB6msxhzgWxhol7ggAXODsHOqdpnB+y1/76y3fI6RC
 Pzy6Kb1le/YDnuhHEIUEa51TcreyC4We1jNnhurxQ9FArsmWkv/hNE4
X-Developer-Key: i=Takahiro.Kuwano@infineon.com; a=ed25519;
 pk=aS8V9WLuMUkl0vmgD0xJU19ZajdJmuyFBnBfVj0dfDs=
X-Endpoint-Received: by B4 Relay for Takahiro.Kuwano@infineon.com/20250227 with auth_id=566
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series suggests to isolate stacked/parallel support from
spi-nor-core by moving that to SPI controllers and new modules under
mtd/spi.

The patchset mainly focuses on removing references to stacked/parallel
related items from core. The stacked/parallel support logic itself may
have rooms to improve. Rework or further cleanup in stacked/parallel
support would be done by other patches after this series is applied.

Signed-off-by: Takahiro Kuwano <Takahiro.Kuwano@infineon.com>
---
Takahiro Kuwano (11):
      spi: zynqmp-gqspi: Set priv->is_parallel in child_pre_probe()
      spi: zynqmp_gqspi: Remove reference to SPI_XFER_LOWER flag.
      spi: zynqmp_gqspi: Read two bytes of SR and FSR in parallel mode
      spi: zynq-qspi: Set priv->is_parallel/stacked in child_pre_probe()
      spi: zynq_qspi: Remove reference to SPI_XFER_LOWER flag.
      spi: zynq_qspi: Read two bytes of SR and FSR in parallel mode
      mtd: spi-nor: Migrate stacked/parallel part to new modules
      mtd: spi-nor: stacked: Cleanup stacked/parallel flags
      mtd: spi-nor: parallel: Cleanup stacked/parallel flags
      mtd: spi-nor: Revert stacked/parallel related commits
      mtd: spi-nor: Call stacked/parallel post init fixups

 drivers/mtd/spi/Makefile       |   4 +
 drivers/mtd/spi/parallel.c     | 412 ++++++++++++++++++++++++++++++++++++++++
 drivers/mtd/spi/sf_internal.h  |  18 ++
 drivers/mtd/spi/spi-nor-core.c | 422 +++++++----------------------------------
 drivers/mtd/spi/stacked.c      | 389 +++++++++++++++++++++++++++++++++++++
 drivers/spi/zynq_qspi.c        |  47 +++--
 drivers/spi/zynqmp_gqspi.c     |  55 ++++--
 include/linux/mtd/spi-nor.h    |  10 -
 include/spi.h                  |   2 -
 9 files changed, 973 insertions(+), 386 deletions(-)
---
base-commit: e2d51f8db207f7db70dd8104fa1da2cffda419f2
change-id: 20251118-amd-cleanup-c8023872e3cf

Best regards,
-- 
Takahiro Kuwano <Takahiro.Kuwano@infineon.com>

