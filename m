From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v6 0/3] support for Amlogic SPI Flash Controller IP
Date: Wed, 10 Sep 2025 18:18:24 +0800
Message-Id: <20250910-spifc-v6-0-1574aa9baebd@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHBQwWgC/2XMTW7CMBCG4asgr2vk8c84ZsU9UBexMwOWCkExi
 qhQ7l6DGpoqy280z/sQhYZMRew2DzHQmEvuL3Xgx0akU3s5ksxd3UIr7VSjrCzXzEk6j0DGcSR
 gUX+vA3G+vzqHz7pPudz64fuVHeF5nQvNb2EEqSSzJaNIY4tx356/+mNO29SfxbMx6oXTMDtdX
 QQIjDa6pMLamaXD2ZnqPAWNykLnGdfOLl2Yna0OyHnuTGDX2LVzfy6ot3PVBdQxgfUdeP7vpmn
 6AdSb/JR8AQAA
To: Mark Brown <broonie@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liang Yang <liang.yang@amlogic.com>, 
 Feng Chen <feng.chen@amlogic.com>
Cc: linux-spi@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757499505; l=2152;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=BbK/5/N5DEttwRbyK9p+3UuFCTTMS4wF1GIjggC2Nlo=;
 b=3z0r6eHSJGhKnflgUXglWaK8KQfYOk5kSmwKX6tRqdVICuN0wOphryrB0BIsoIMKMK5mhBoze
 Q5tA3dbEuWDAlrfePULm0R0q5pOYCFIbv5Rjw7yOKcn9OxSoMXPAHK4
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
Changes in v6:
- Fix compilation warning appeared in v4 version tested by kernel test robot.
- Link to v5: https://lore.kernel.org/r/20250909-spifc-v5-0-962bc147d17f@amlogic.com

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
base-commit: 475541d2f3dfe72e8cfe94bfb1b824030f8d9b68
change-id: 20250804-spifc-5761e35fbe1f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

