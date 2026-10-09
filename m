From: Long Zhao <longzhao@ambarella.com>
Subject: [PATCH 0/4] arm64: add Ambarella CV75 SoC support
Date: Fri, 09 Oct 2026 19:00:21 +0800
Message-Id: <20261009-cv75-soc-v1-0-808330e93ff1@ambarella.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEXJyGoC/yXMQQ5AMBCF4avIrDWpilZcRSyoKWPRSgeRiLsrl
 l/yv3cBYyRkaLILIh7EFHxCkWdg595PKGhMBiWVLqQ0wh6mEhysQK1qV1bGSa0h5WtER+d31Xa
 /eR8WtNu7h/t+AP0El3tsAAAA
X-Change-ID: 20261007-cv75-soc-e628f357f066
To: Arnd Bergmann <arnd@arndb.de>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, soc@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Lee Jones <lee@kernel.org>, mfd@lists.linux.dev, devicetree@vger.kernel.org, 
 Long Zhao <longzhao@ambarella.com>, Long Zhao <zl020895@163.com>, 
 linux-kernel@vger.kernel.org, Linus Walleij <linusw@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791543624; l=2687;
 i=longzhao@ambarella.com; s=20260730; h=from:subject:message-id;
 bh=+tZNSX5k1H+sKgRoo1wVaQVdEfZrw4ENU3AszdLQqmI=;
 b=9A1njMKYc47+mS3RQO11zurFUDOCK/SFzr14TS4vhG6bLT+9X6m1jepTq0ByB83cTsLT272Ex
 USgQZlGOvtMBv0vFKJc0cm7JWEmpH7Dx+2hfnOEfMKa0GI6NH1bzSQb
X-Developer-Key: i=longzhao@ambarella.com; a=ed25519;
 pk=/xGhPTOX0/eYsyTWzyjjgAIW1Z/YD+IlnOnvcdRozow=
X-Endpoint-Received: by B4 Relay for longzhao@ambarella.com/20260730 with auth_id=903
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Split from the combined CV75 bring-up series. This series adds the
ambarella vendor prefix, the board binding, the secure scratchpad
syscon, ARCH_AMBARELLA, the CV75 EVK devicetree and MAINTAINERS.

The EVK devicetree includes dt-bindings/clock/ambarella,cv75-rct.h
from the clock series, so it does not build until that header is
applied. The devicetree also describes the CV75 pinctrl (already
applied in the pinctrl tree), GPIO, UART and RCT clock. Those
drivers are separate series.

The MAINTAINERS entry lists all Ambarella files including the RCT
clock files. If the clock series lands first, those files are
briefly unmaintained until this series follows.

The combined tree, including the other series, was booted on the
CV75 EVK before this split.

Link: https://patch.msgid.link/20261001-cv75-v5-v9-0-486cc289a4b8@ambarella.com

To: Arnd Bergmann <arnd@arndb.de>
To: Krzysztof Kozlowski <krzk@kernel.org>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>
To: soc@lists.linux.dev
To: linux-arm-kernel@lists.infradead.org
Cc: Rob Herring <robh@kernel.org>
Cc: Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: Conor Dooley <conor+dt@kernel.org>
Cc: Catalin Marinas <catalin.marinas@arm.com>
Cc: Will Deacon <will@kernel.org>
Cc: Lee Jones <lee@kernel.org>
Cc: mfd@lists.linux.dev
Cc: devicetree@vger.kernel.org
Cc: Long Zhao <longzhao@ambarella.com>
Cc: Long Zhao <zl020895@163.com>
Cc: linux-kernel@vger.kernel.org

Assisted-by: LLM
Signed-off-by: Long Zhao <longzhao@ambarella.com>
---
Long Zhao (4):
      dt-bindings: arm: add Ambarella CV75 platforms
      dt-bindings: mfd: syscon: add Ambarella CV75 secure scratchpad
      arm64: ambarella: add ARCH_AMBARELLA and CV75 EVK DT
      MAINTAINERS: add ARM/AMBARELLA SoC support

 .../devicetree/bindings/arm/ambarella.yaml         |  24 +++
 Documentation/devicetree/bindings/mfd/syscon.yaml  |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |  14 ++
 arch/arm64/Kconfig.platforms                       |   6 +
 arch/arm64/boot/dts/Makefile                       |   1 +
 arch/arm64/boot/dts/ambarella/Makefile             |   3 +
 arch/arm64/boot/dts/ambarella/cv75-evk.dts         |  30 ++++
 arch/arm64/boot/dts/ambarella/cv75.dtsi            | 177 +++++++++++++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 10 files changed, 259 insertions(+)
---
base-commit: 34cf6dafc47441dfb6b356a095b89c3585a93714
change-id: 20261007-cv75-soc-e628f357f066

Best regards,
--  
Long Zhao <longzhao@ambarella.com>

