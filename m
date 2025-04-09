From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v4 0/3] Driver for the Apple SPMI controller
Date: Wed, 09 Apr 2025 23:52:11 +0200
Message-Id: <20250409-spmi-v4-0-eb81ecfd1f64@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAvs9mcC/13MywrCMBCF4VcpWRuZJL2NK99DXKS5tAF7IZGgl
 L67aa1QXJ5hvn8mwXhnArlkM/EmuuDGIY38lBHVyaE11Om0CQdegICchql3tNRC8bxB4JUk6XX
 yxrrXlrnd0+5ceI7+vVUjW6+/QPENREaBKqxtUTIrEe217aV7nNXYkzUQ+RFVO+IJGaV0A6W0D
 eI/EgfEYEciIeSy5qbSaEEf0bIsH2wPcXQCAQAA
X-Change-ID: 20250304-spmi-6d3c24b9027a
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Neal Gompa <neal@gompa.dev>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Jean-Francois Bortolotti <jeff@borto.fr>, Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744235551; l=1649;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=CXl1nA0gkeV3YEJmr8NWq0DTje/v81qqIMYYeDNAeDU=;
 b=XaQhaaJwxWHZCyL0KjusE3kB1Cm7zwrQ5Xz6uFE0AeD50bT/9JjX1VrQy+u4VWeDkY50nLAPX
 baXS3qrjf/BBHGmLCoCIkp68qo0X+nI92t2lj1YDpAIHXpBgv0S4QhT
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds support for the SPMI controller persent in most
Apple SoCs. The drivers for the attached PMU and subdevices will be in
further patch series.

Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
Changes in v4:
- Rebase on 6.14
- Link to v3: https://lore.kernel.org/r/20250310-spmi-v3-0-92a82e7d9f0d@gmail.com

Changes in v3:
- Inlined helpers, dropped unneccesary error prefixes
- Link to v2: https://lore.kernel.org/r/20250307-spmi-v2-0-eccdb06afb99@gmail.com

Changes in v2:
- Removed redundant error prints
- Various style fixes
- Better explanation of why the driver is needed
- Link to v1: https://lore.kernel.org/r/20250305-spmi-v1-0-c98f561fa99f@gmail.com

---
Jean-Francois Bortolotti (1):
      spmi: add a spmi driver for Apple SoC

Sasha Finkelstein (2):
      dt-bindings: spmi: Add Apple SPMI controller
      arm64: dts: apple: Add SPMI controller nodes

 .../devicetree/bindings/spmi/apple,spmi.yaml       |  49 ++++++
 MAINTAINERS                                        |   2 +
 arch/arm64/boot/dts/apple/t600x-die0.dtsi          |   7 +
 arch/arm64/boot/dts/apple/t8103.dtsi               |   8 +
 arch/arm64/boot/dts/apple/t8112.dtsi               |   7 +
 drivers/spmi/Kconfig                               |   8 +
 drivers/spmi/Makefile                              |   1 +
 drivers/spmi/spmi-apple-controller.c               | 168 +++++++++++++++++++++
 8 files changed, 250 insertions(+)
---
base-commit: a24588245776dafc227243a01bfbeb8a59bafba9
change-id: 20250304-spmi-6d3c24b9027a

Best regards,
-- 
Sasha Finkelstein <fnkl.kernel@gmail.com>

