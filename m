From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Subject: [PATCH v3 0/3] Driver for the Apple SPMI controller
Date: Mon, 10 Mar 2025 23:07:57 +0100
Message-Id: <20250310-spmi-v3-0-92a82e7d9f0d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL1iz2cC/02MyQrCMBRFf6W8tZEMHUxX/oe4SNKkfWAHEglKy
 b+bVoUuz+Wes0KwHm2AtljB24gB5ymDOBVgBjX1lmCXGTjlFRW0JGEZkdSdMLzUkvJGQb4u3jp
 87ZnbPfOA4Tn7916NbFv/geobiIxQYuTFVTVzSkp37UeFj7OZR9gCkR+l5ifxLFljOk1r5bSUR
 yml9AH68rAFzQAAAA==
X-Change-ID: 20250304-spmi-6d3c24b9027a
To: Sven Peter <sven@svenpeter.dev>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Stephen Boyd <sboyd@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, 
 Jean-Francois Bortolotti <jeff@borto.fr>, Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741644479; l=1465;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=4NH90Cs04TqlOhUoz/iIw6tRYGsatu8fWNgt044t36M=;
 b=g8CnRI6E0LKqOAOS/T7gnJRQIpwR+RGZtCOByjaUTDPnkY/76IvmqdKFQH66bpW46p5MmnOXm
 cbATFvvfMoqBVkC6MTfJwMvVEb2+tmF81rCQYQLPCjubErPipZ6zuYG
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
base-commit: 48a5eed9ad584315c30ed35204510536235ce402
change-id: 20250304-spmi-6d3c24b9027a

