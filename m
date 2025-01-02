From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH 00/19] powerpc: MPC83xx cleanup and LANCOM NWAPP2 board
Date: Thu, 02 Jan 2025 19:31:41 +0100
Message-Id: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAI7bdmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDI2ND3dyCZAvjigpdQ/NkC0uLRBNLExNDJaDqgqLUtMwKsEnRsbW1ALn
 E2NdZAAAA
X-Change-ID: 20241231-mpc83xx-17c898a49441
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=2877;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=s9KOsJHPX8mNPryGVyICWhP1YoIx1vF2Sh4FXkHLgpk=;
 b=Yes62fmOx2x2qZhQDLO1dreJSQZiMF9f1nnFMaGDZeK+FBloj2U8kviImy+hqs0K4bJ17FFXx
 oLI8tgG+VsmCNh41LCNbnc+oAla8AExIhxUWOPTE8qd9z8vIciFRu5Y
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds a devicetree for the LANCOM NWAPP2 board based on the
MPC8314E platform, and slightly modernizes the MPC83xx platform support
in the process.

This board is nominally end-of-life, but available to hobbyists.
A U-Boot port is also in the making.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
J. Neuschäfer (19):
      powerpc: Generalize MPC831x platform support
      powerpc: dts: Extract mpc8315e.dtsi from mpc8315erdb.dts
      powerpc: dts: mpc8315e: Use IRQ_TYPE_* macros
      powerpc: dts: mpc8315e: Add labels to peripherals
      powerpc: dts: mpc8315e: Disable peripherals by default
      powerpc: dts: mpc8315e: Add missing #cells properties to SPI bus
      powerpc: dts: mpc8315erdb: Add missing model property
      powerpc: boot: Enable FIT image generation
      powerpc: boot: Build devicetrees when CONFIG_MPC831x=y
      powerpc: dts: Add MPC8314E devicetree
      dt-bindings: gpio: fsl,qoriq-gpio: Add compatible string fsl,mpc8314-gpio
      powerpc: dts: mpc8315e: Add GPIO controller node
      gpio: mpc8xxx: Add MPC8314 support
      powerpc: mpc83xx: Switch to of_platform_populate
      dt-bindings: vendor-prefixes: Add LANCOM Systems GmbH
      powerpc: dts: Add LANCOM NWAPP2 board devicetree
      powerpc: Regenerate mpc83xx_defconfig
      powerpc: mpc83xx_defconfig: Enable NWAPP2 board features
      MAINTAINERS: Add entry for LANCOM board support

 .../devicetree/bindings/gpio/fsl,qoriq-gpio.yaml   |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   8 +
 arch/powerpc/Makefile                              |   3 +-
 arch/powerpc/boot/Makefile                         |  11 +
 arch/powerpc/boot/dts/Makefile                     |   6 +
 arch/powerpc/boot/dts/lancom-nwapp2.dts            | 276 +++++++++++++++
 arch/powerpc/boot/dts/mpc8314e.dtsi                |   7 +
 arch/powerpc/boot/dts/mpc8315e.dtsi                | 390 +++++++++++++++++++++
 arch/powerpc/boot/dts/mpc8315erdb.dts              | 327 +----------------
 arch/powerpc/configs/83xx/mpc8313_rdb_defconfig    |   2 +-
 arch/powerpc/configs/83xx/mpc8315_rdb_defconfig    |   2 +-
 arch/powerpc/configs/mpc83xx_defconfig             |  41 ++-
 arch/powerpc/configs/ppc6xx_defconfig              |   2 +-
 arch/powerpc/platforms/83xx/Kconfig                |   6 +-
 arch/powerpc/platforms/83xx/Makefile               |   2 +-
 arch/powerpc/platforms/83xx/misc.c                 |   6 +-
 .../platforms/83xx/{mpc831x_rdb.c => mpc831x.c}    |  21 +-
 drivers/gpio/gpio-mpc8xxx.c                        |   1 +
 19 files changed, 769 insertions(+), 345 deletions(-)
---
base-commit: fc033cf25e612e840e545f8d5ad2edd6ba613ed5
change-id: 20241231-mpc83xx-17c898a49441

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

