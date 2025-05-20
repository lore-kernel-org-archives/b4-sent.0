From: Maud Spierings <maudspierings@gocontroll.com>
Subject: [PATCH v7 0/8] arm64: dts: freescale: Add support for the
 GOcontroll Moduline Display
Date: Tue, 20 May 2025 08:34:49 +0200
Message-Id: <20250520-initial_display-v7-0-a8f0195420aa@gocontroll.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIkiLGgC/3XPzWoDIRDA8VcJnmvR8TunvkcJxXU1EbZr0GVJC
 PvuNblkQXv8D8xvmAcqPkdf0PHwQNmvscQ011AfB+Qudj57HMfaCAgIAsBxnOMS7fQzxnKd7B0
 HqwGo9kR6gerWNfsQby/x+1T7EsuS8v11YKXP6f/WSjHBwrlhCJIywdnXObk0LzlN06dLv+gJr
 rBHZItARYAFGyxlRFPVRdgbYaBahFWEe228pVJJO3QR/kY4gRbhFTFBG62ZtlryLiJ2CBUtIio
 SGKnOqCg3povIPdJ5R1aEORnkCNwpGxpk27Y/1jJmPAwCAAA=
X-Change-ID: 20250224-initial_display-fa82218e06e5
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 imx@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Maud Spierings <maudspierings@gocontroll.com>, Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747722892; l=4059;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=MaCkDQE8U2QDmRDmED4Ce+Q4F2+F5eALbfrUvn+NHJQ=;
 b=sX+e/W5gyP6cgDk/CGRsehxUQzRmluCed7s/xWuO4IpWq/A+pT52Q8KmJd8MFSG8m0B0qMgvr
 6YIkBKGll72DcN0w5iCr0PQxDJyPiKtUmBD03WVzk9IXMaGsqNLVSH9
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add inital support for 2 variants of the Moduline Display controller.
This system is powered by the Ka-Ro Electronics tx8p-ml81 COM, which
features an imx8mp SoC.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
Changes in v7:
- Fix indentation as requested by Shawn
- Set alias for fec to ethernet1 so eqos actually becomes end0 throught
  systemd, without that alias eqos was both ethernet0 and ethernet1, and
  it would become end1 instead of the desired end0.
- Link to v6: https://lore.kernel.org/r/20250417-initial_display-v6-0-3c6f6d24c7af@gocontroll.com

Changes in v6:
- Fix spi cs formatting in baseboard dts
- Add model to baseboard dts
- Fix commit typo in karo tx8p ml81 dtsi
- Link to v5: https://lore.kernel.org/r/20250415-initial_display-v5-0-f309f8d71499@gocontroll.com

Changes in v5:
- Merge the makefile patch into the two dtso patches
- Fix references to the root node in the dtso patches
- Enable the USB bus going to the adapter board in the mainboard dts
- Fix some formatting issues in the mainboard dts
- Fix some formatting issues in the COM dts
- Change a clock as suggested in the COM dts
- Fix the maintainers entries, remove devicetree list and imx list
- Rebase on latest linux-next
- Link to v4: https://lore.kernel.org/r/20250402-initial_display-v4-0-9f898838a864@gocontroll.com

Changes in v4:
- Add imx mailing list to ka-ro tx8p maintainer entry
- Fix several small indentation and ordering issues in devicetrees
- Change the two display adapter boards to overlays
- Add the missing patch for the Makefile to actually be able to build
  the new devicetrees
- Link to v3: https://lore.kernel.org/r/20250327-initial_display-v3-0-4e89ea1676ab@gocontroll.com

Changes in v3:
- Set regulator-boot-on and always-on on LDO5 of the pmic, after 20 ish
  seconds it auto disabled this LDO causing weird behaviour like
  ethernet droping out, wifi not working anymore. This LDO can control
  the IO voltage level of certain pins, just let it keep the u-boot
  value.
- Fix the comment style in imx8mp-pinfunc.h
- Rebase on newest next tag
- Link to v2: https://lore.kernel.org/r/20250226-initial_display-v2-0-23fafa130817@gocontroll.com

Changes in v2:
- Dropped the trivial-devices patch
- Added a patch with bindings for the gocontroll,moduline-module-slot
- Added a patch to spidev.c to enable the spidev driver for the module
  slot
- Added a missing usb-c connector in the av101hdt-a10 variant dts
- Switched to the new bindings for the module slots in the base dts
- Fixed some commit typos
- Link to v1: https://lore.kernel.org/r/20250224-initial_display-v1-0-5ccbbf613543@gocontroll.com

---
Maud Spierings (8):
      dt-bindings: arm: fsl: Add GOcontroll Moduline Display
      arm64: dts: imx8mp: Add pinctrl config definitions
      MAINTAINERS: add maintainer for the Ka-Ro tx8p-ml81 COM module
      MAINTAINERS: add maintainer for the GOcontroll Moduline controllers
      arm64: dts: freescale: add Ka-Ro Electronics tx8p-ml81 COM
      arm64: dts: freescale: Add the GOcontroll Moduline Display baseboard
      arm64: dts: freescale: Add the BOE av101hdt-a10 variant of the Moduline Display
      arm64: dts: freescale: Add the BOE av123z7m-n17 variant of the Moduline Display

 Documentation/devicetree/bindings/arm/fsl.yaml     |   1 +
 MAINTAINERS                                        |  12 +
 arch/arm64/boot/dts/freescale/Makefile             |   8 +
 arch/arm64/boot/dts/freescale/imx8mp-pinfunc.h     |  33 ++
 ...x8p-ml81-moduline-display-106-av101hdt-a10.dtso |  94 ++++
 ...x8p-ml81-moduline-display-106-av123z7m-n17.dtso | 139 ++++++
 .../imx8mp-tx8p-ml81-moduline-display-106.dts      | 527 ++++++++++++++++++++
 .../arm64/boot/dts/freescale/imx8mp-tx8p-ml81.dtsi | 548 +++++++++++++++++++++
 8 files changed, 1362 insertions(+)
---
base-commit: fb44e19e78df2950877a9f7b4f24b58db790d293
change-id: 20250224-initial_display-fa82218e06e5

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

