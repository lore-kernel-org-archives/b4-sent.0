From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Subject: [PATCH v3 0/3] spi: xilinx: switch to device properties and make
 IRQs optional
Date: Mon, 19 Jan 2026 07:06:21 +0000
Message-Id: <20260119-spi-xilinx-v3-0-4566c33bac0d@nexthop.ai>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO3XbWkC/03MQQ6CMBBA0auQWTukU6SiK+9hXBQZ7CRSyBRNE
 8LdbVy5fIv/N0iswgku1QbKH0kyx4LmUMEj+PhklKEYrLHOEHWYFsEsL4kZqe+649D2rqUzlGB
 RHiX/Zrd78ajzhGtQ9v+LkyFLjauta601SOj74a3qw+TjNXJew7zUXmDfv27egTSdAAAA
X-Change-ID: 20260118-spi-xilinx-1b884d5b6519
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Michal Simek <michal.simek@amd.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768806393; l=1190;
 i=abdurrahman@nexthop.ai; s=20260119; h=from:subject:message-id;
 bh=tpnfYEEUGGCcAt473upHUWl8HqVkQmGsCrvb4CiklBI=;
 b=YHnrC+P6MuDz85zvTkEdBwOIu0gWm/BLsiWVugyfCbkuGtF2+tNjvrjF4b2AXibOgorGlYwPo
 CCRNsI8TXKmBOhUslCDbZIkLbruGmnpr1r+tXRbtA+X0vDTpRR7CdX/
X-Developer-Key: i=abdurrahman@nexthop.ai; a=ed25519;
 pk=S+ysnf+NwMcBdHBlyKIUEAtaFGSIhQwcJcgcXhq0osg=
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/20260119 with auth_id=608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Transition the driver to use the generic device property API.

Additionally, make interrupts optional to allow the driver to fall back
to its existing polling mode on systems where interrupts are either missing
or broken.

Abdurrahman Hussain (3):
  spi: xilinx: use device property accessors.
  spi: xilinx: make irq optional
  spi: dt-bindings: xilinx: make interrupts optional

 .../devicetree/bindings/spi/spi-xilinx.yaml          |  1 -
 drivers/spi/spi-xilinx.c                             | 12 ++++++------
 2 files changed, 6 insertions(+), 7 deletions(-)

--
2.52.0

base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
---
Abdurrahman Hussain (3):
      spi: dt-bindings: xilinx: make interrupts optional
      spi: xilinx: make irq optional
      spi: xilinx: use device property accessors.

 Documentation/devicetree/bindings/spi/spi-xilinx.yaml |  1 -
 drivers/spi/spi-xilinx.c                              | 12 ++++++------
 2 files changed, 6 insertions(+), 7 deletions(-)
---
base-commit: 944aacb68baf7624ab8d277d0ebf07f025ca137c
change-id: 20260118-spi-xilinx-1b884d5b6519

Best regards,
-- 
Abdurrahman Hussain <abdurrahman@nexthop.ai>

