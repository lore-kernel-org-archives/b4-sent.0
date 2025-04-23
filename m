From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v3 0/3] Apple PMIC NVMEM cell driver (Formerly: Generic
 SPMI NVMEM cell driver)
Date: Wed, 23 Apr 2025 19:55:12 +0200
Message-Id: <20250423-spmi-nvmem-v3-0-2985aa722ddc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIApCWgC/23MQQqDMBCF4avIrJuSTIyGrnqP0oWmow40KkkJL
 eLdG11Z6PI9+P4FIgWmCJdigUCJI09jHvpUgBuasSfBj7wBJRpZKiPi7FmMyZMXJG2ljVaVqg1
 kMAfq+L3Hbve8B46vKXz2dlLb+zeTlJACUVZ1S2i06669b/h5dpOHLZPwSOsfipm21lqjSJdN1
 x7puq5fOHbWGN8AAAA=
X-Change-ID: 20250415-spmi-nvmem-e08635316175
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Hector Martin <marcan@marcan.st>, 
 Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745430928; l=1822;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=/LVwP2J7phmJo5xUbPuYBsq73NOkQB14cAElXzkBoks=;
 b=DYImOHdO3m2rCslcCrmKq+Ure36xtXDMfMi0nYTg6CXkPtjKnUVyEChYMW8gOT5qVYqXuThMd
 Ci910bPQ5VpCr/YdCgRCnRTDLNFysECw1DxHkbLO6gFHVJK4qBZ/w7M
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds a driver for exposing a set of registers
as NVMEM cells on a SPMI-attached PMIC on Apple ARM platforms.
Those are used to store the RTC offset and to communicate platform
power state between the OS and boot firmware.

The NVMEM cell consumer drivers will be sent in a further series.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v3:
- No longer try to make it generic, use for the 3 relevant PMICs only
- Link to v2: https://lore.kernel.org/r/20250417-spmi-nvmem-v2-0-b88851e34afb@gmail.com

Changes in v2:
- s/pmu/pmic/
- Sort dts in unit-order, instead of t600x-unit-order
- Link to v1: https://lore.kernel.org/r/20250415-spmi-nvmem-v1-0-22067be253cf@gmail.com

---
Hector Martin (2):
      nvmem: Add apple-spmi-nvmem driver
      arm64: dts: apple: Add PMIC NVMEM

Sasha Finkelstein (1):
      dt-bindings: spmi: Add Apple SPMI NVMEM

 .../bindings/nvmem/apple,spmi-nvmem.yaml           | 54 +++++++++++++++++++
 MAINTAINERS                                        |  2 +
 arch/arm64/boot/dts/apple/t6001.dtsi               |  1 +
 arch/arm64/boot/dts/apple/t6002.dtsi               |  1 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          | 50 +++++++++++++++++
 arch/arm64/boot/dts/apple/t8103.dtsi               | 50 +++++++++++++++++
 arch/arm64/boot/dts/apple/t8112.dtsi               | 50 +++++++++++++++++
 drivers/nvmem/Kconfig                              | 13 +++++
 drivers/nvmem/Makefile                             |  2 +
 drivers/nvmem/apple-spmi-nvmem.c                   | 62 ++++++++++++++++++++++
 10 files changed, 285 insertions(+)
---
base-commit: 2e0e70c95077172b29a5b13716c4b159d578e82c
change-id: 20250415-spmi-nvmem-e08635316175

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

