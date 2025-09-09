From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v5 0/3] support for Amlogic SPI Flash Controller IP
Date: Tue, 09 Sep 2025 13:13:24 +0800
Message-Id: <20250909-spifc-v5-0-962bc147d17f@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHW3v2gC/2XMTQrCMBCG4atI1kYy+WvjynuIizadaQNqSiNFk
 d7dWCxUuvyGed43SzgETOy4e7MBx5BCvOdh9jvmu+reIg9N3kwKaUQpNE99IM9NYQGVoRqBWP7
 tB6TwnDvnS95dSI84vObsCN/rUih/hRG44EQalUBpK1ufqts1tsEffLyxb2OUKydhcTK7GsCR1
 bXxwm2dWju7OJVdgU5aoaEpyG6dXju3OJ0doCmoUY5Mqf/dNE0fbW3wR0QBAAA=
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liang Yang <liang.yang@amlogic.com>, 
 Feng Chen <feng.chen@amlogic.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757394806; l=1969;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=6PX2e7dGJjwC4zwK2oyfFNmBAEYYwMR+WepuRDhd+V4=;
 b=YzPNsHeKO+ldWi+RFRj6miT15/ZHAsvByjJbWR4va/heDq/6NXdgIbfh69kdvVWpqEYDVfvmI
 fU3RXriUQ+vD1izrpa/k1j+6WQDPKhYuOS+kNFzBWoplEEb9tRl8KT1
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This Flash Controller is derived by adding an SPI path to the original
raw NAND controller. This controller supports two modes: raw mode and
SPI mode. The raw mode has already been implemented in the community
(drivers/mtd/nand/raw/meson_nand.c).
This submission supports the SPI mode.

Add the drivers and bindings corresponding to the SPI Flash Controller.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v5:
- Initialize local variables and handle exceptions solve compilation error problems.
- Link to v4: https://lore.kernel.org/r/20250829-spifc-v4-0-1e57fd39f584@amlogic.com

Changes in v4:
- Reword desc of 'amlogic, rx-adj' in bingding file.
- Link to v3: https://lore.kernel.org/r/20250826-spifc-v3-0-7e926041d7f6@amlogic.com

Changes in v3:
- Restore message description and modify subject [1/3] that was omitted in v2. 
- Link to v2: https://lore.kernel.org/r/20250821-spifc-v2-0-b119f64b5c09@amlogic.com

Changes in v2:
- Remove clock reg descriptor and get clock from common clk.
- Remove ecc and ramdom descriptor in bindings.
- Modify the format and message description.
- Link to v1: https://lore.kernel.org/r/20250808-spifc-v1-0-ff4e30e26a6b@amlogic.com

---
Feng Chen (2):
      spi: dt-bindings: add Amlogic A113L2 SFC
      spi: amlogic: add driver for Amlogic SPI Flash Controller

Xianwei Zhao (1):
      MAINTAINERS: Add an entry for Amlogic spifc driver

 .../devicetree/bindings/spi/amlogic,a4-spifc.yaml  |   82 ++
 MAINTAINERS                                        |   10 +
 drivers/spi/Kconfig                                |   10 +
 drivers/spi/Makefile                               |    1 +
 drivers/spi/spi-amlogic-spifc-a4.c                 | 1222 ++++++++++++++++++++
 5 files changed, 1325 insertions(+)
---
base-commit: f8b3f0d7b2a91ba84d06343c3ca4522e35a65f56
change-id: 20250804-spifc-5761e35fbe1f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

