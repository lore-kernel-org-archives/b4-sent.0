From: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
Subject: [PATCH v5 0/6] Add support for Blaize BLZP1600 SoC
Date: Wed, 04 Dec 2024 16:05:23 +0000
Message-Id: <20241204-blaize-blzp1600_init_board_support-v5-0-b642bcc49307@blaize.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMN9UGcC/53NQQrCMBAF0KuUWRtJahONK+8hUtI02gFNQlKDt
 vTuphWXgjib4Q/M+yNEE9BE2BcjBJMworM58FUBulP2Ygi2OUNJy4rlIc1V4WDyGjwTlNZosa8
 bp0Jbx7v3LvSEsXLHZKWV3ArIkA/mjI+l5HjKucPYu/BcOhOfrx+e/8InTijRVFJZGbFpNT+8n
 9ba3WD2k/jH5N/NaZpe1cUITykBAAA=
X-Change-ID: 20241111-blaize-blzp1600_init_board_support-1128194ca976
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 James Cowgill <james.cowgill@blaize.com>, 
 Matt Redfearn <matt.redfearn@blaize.com>, 
 Neil Jones <neil.jones@blaize.com>, 
 Niko Pasaloukos <nikolaos.pasaloukos@blaize.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Olof Johansson <olof@lixom.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, soc@lists.linux.dev, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733328392; l=2384;
 i=nikolaos.pasaloukos@blaize.com; s=20241111; h=from:subject:message-id;
 bh=V7BO1ptbAkL1Yo+zXuNam1yKuSO5DtHXBeNULjuF9dE=;
 b=fPh1ioEVlho7W+IqTeSP6WFdrEGCIDEG3gNT/kPqAEBd4ucS4JflSG7ZWSOK3770VwULgRTcB
 IPuH09RdjKmBgRAqSezIXNYP20hhWbv1NAhuIdWAVwuRf8UbbWYo6pL
X-Developer-Key: i=nikolaos.pasaloukos@blaize.com; a=ed25519;
 pk=gGEjGCXdSuvCJPIiu0p0UeiPcW5LC710Z6KGN/dzo3g=
X-Endpoint-Received: by B4 Relay for nikolaos.pasaloukos@blaize.com/20241111 with auth_id=274
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Blaize, Inc. (www.blaize.com) is a SoC designer and manufacturer
with integrated programmable Graph-Streaming-Processors for AI
and ML. This series adds support for the Blaize BLZP1600 SoC.

The SoC can run as either a PCIe based accelerator in a host
system, or as a stand alone SoC running Linux on its integrated
dual core ARM Cortex A53 cluster.

The SoC includes a suite of peripherals, support for which will
be added later.

This first series is just the basics to get the upstream
kernel to boot with a UART console and ARM SCMI based
clocks and resets.

Resending V5 with tags applied and 'From' fixed.

V5 changes:
 * Add more information on patches and on files
 * Rename arch to ARCH_BLAIZE

V4 changes:
 * Add maintainer for blaize in arm64 dts
 * Fix Blaize schema & dts code style
 * Add range and reserved-memory as suggested

V3 changes:
 * Removed unnecessary dt-bindings
 * Update SoBs

V2 changes:
 * Update SoBs
 * `make dtbs_check` has no warnings
 * Fix dts names and removed dead code
 * DTS is separated from anything else

Signed-off-by: Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>
---
Nikolaos Pasaloukos (6):
      dt-bindings: Add Blaize vendor prefix
      dt-bindings: arm: blaize: Add Blaize BLZP1600 SoC
      arm64: Add Blaize BLZP1600 SoC family
      arm64: dts: Add initial support for Blaize BLZP1600 CB2
      arm64: defconfig: Enable Blaize BLZP1600 platform
      MAINTAINER: Add entry for Blaize SoC

 Documentation/devicetree/bindings/arm/blaize.yaml  |  40 ++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   9 +
 arch/arm64/Kconfig.platforms                       |   5 +
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/blaize/Makefile                |   2 +
 arch/arm64/boot/dts/blaize/blaize-blzp1600-cb2.dts |  83 +++++++++
 .../arm64/boot/dts/blaize/blaize-blzp1600-som.dtsi |  23 +++
 arch/arm64/boot/dts/blaize/blaize-blzp1600.dtsi    | 205 +++++++++++++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 10 files changed, 371 insertions(+)
---
base-commit: 83d67c257f4d045ff477309b5617d931f9a7be66
change-id: 20241111-blaize-blzp1600_init_board_support-1128194ca976

Best regards,
-- 
Nikolaos Pasaloukos <nikolaos.pasaloukos@blaize.com>

