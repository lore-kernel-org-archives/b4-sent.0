From: Oliver Gaskell <Oliver.Gaskell@analog.com>
Subject: [PATCH v2 00/20] arm: Initial support for Analog Devices SC5xx
 boards
Date: Thu, 12 Sep 2024 16:50:41 +0100
Message-Id: <20240912-sc5xx-upstreaming-patches-v2-0-1185a80df79e@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANEN42YC/32Nyw6CMBBFf8XM2jGl1kBd+R+GxdgHTCItaZFgC
 P9uJXHr8pzknrtCdoldhuthheRmzhxDAXk8gOkpdA7ZFgYppBKNrDCby7Lga8xTcjRw6HCkyfQ
 uoxGqeZD2utYEZT8m53nZ2/e2cM95ium9X83V1/6qzZ/qXKFApawm660/y/pGgZ6xO5k4QLtt2
 wdksIZ4wwAAAA==
To: Tom Rini <trini@konsulko.com>, 
 Nathan Barrett-Morrison <nathan.morrison@timesys.com>, 
 Greg Malysa <greg.malysa@timesys.com>, 
 Ian Roberts <ian.roberts@timesys.com>, 
 Vasileios Bimpikas <vasileios.bimpikas@analog.com>, 
 Utsav Agarwal <utsav.agarwal@analog.com>, 
 Arturs Artamonovs <arturs.artamonovs@analog.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, adsp-linux@analog.com, 
 Oliver Gaskell <Oliver.Gaskell@analog.com>, 
 Trevor Woerner <twoerner@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726156261; l=5381;
 i=Oliver.Gaskell@analog.com; s=20240821; h=from:subject:message-id;
 bh=Xj/meaRgDFyAmwkr6tu2q92rPXq/jjCcq2OgMAHdieI=;
 b=zSr+pzZOepbuousZeGSMnTvnY9b1DkqjW29BNqKAMsg87cI7fU/GslMoVWRGjMSR2e5NxiOKY
 n1MTW/0/vBaCNr2wI7zDozL3bxaUwwJO+K1rmJXSG1UYfEdzJw88smI
X-Developer-Key: i=Oliver.Gaskell@analog.com; a=ed25519;
 pk=Icq9TxwFJ6FePHS28YbBWMvtZpFWxpPQLhLA9cNvZ/Y=
X-Endpoint-Received: by B4 Relay for Oliver.Gaskell@analog.com/20240821 with auth_id=197
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ADSP-SC5xx is a series of ARM-based DSPs.
This comprises the armv7 based SC57x, SC58x and SC594 series, and the
armv8 based SC598.

This patch series includes configurations, init code, and minimal DTs
to enable Analog Devices' evaluation boards for these SoCs to boot
through SPL and into U-Boot Proper, as well as devicetree schemas for
the added DTs.

This patch series depends on ("arm: Add Analog Devices SC5xx Machine
Type") (https://lists.denx.de/pipermail/u-boot/2024-April/552043.html)

Signed-off-by: Oliver Gaskell <Oliver.Gaskell@analog.com>
---
Changes in v2:
- Reorganise Kconfig defaults into the root Kconfig, and
  common/spl/Kconfig.
- Sort Kconfig `select`s alphabetically
- Clean up implementation of bss_clear to be not platform-dependent
- Update adi_rom_boot_args for SC598-SOM to support RevC and newer of
  the SoM.
- Link to v1: https://lore.kernel.org/r/20240828-sc5xx-upstreaming-patches-v1-0-44d9adfdf327@analog.com

---
Oliver Gaskell (20):
      arm: dts: Support SC573-EZKIT
      arm: dts: Support SC584-EZKIT
      arm: dts: Support SC589-MINI
      arm: dts: Support SC589-EZKIT
      arm: dts: Support SC594-SOM-EZKIT
      arm: dts: Support SC594-SOM-EZLITE
      arm: dts: Support SC598-SOM-EZKIT
      arm: dts: Support SC598-SOM-EZLITE
      dt-bindings: arm: Add SC5xx Series binding
      dt-bindings: clock: Add SC5xx clock tree bindings
      dt-bindings: timer: Add SC5xx Timer bindings
      arm: mach-sc5xx: clean up Kconfig
      arm: SC598-SOM-EZKIT initial support
      arm: SC598-SOM-EZLITE initial support
      arm: SC594-SOM-EZKIT initial support
      arm: SC594-SOM-EZLITE initial support
      arm: SC584-EZKIT initial support
      arm: SC589-EZKIT initial support
      arm: SC589-MINI initial support
      arm: SC573-EZKIT initial support

 Kconfig                                            |   8 +-
 MAINTAINERS                                        |   7 +
 arch/arm/Kconfig                                   |  14 ++
 arch/arm/dts/Makefile                              |   9 ++
 arch/arm/dts/sc573-ezkit.dts                       |  13 ++
 arch/arm/dts/sc57x.dtsi                            |  21 +++
 arch/arm/dts/sc584-ezkit.dts                       |  13 ++
 arch/arm/dts/sc589-ezkit.dts                       |  13 ++
 arch/arm/dts/sc589-mini.dts                        |  13 ++
 arch/arm/dts/sc58x.dtsi                            |  23 ++++
 arch/arm/dts/sc594-som-ezkit.dts                   |  13 ++
 arch/arm/dts/sc594-som-ezlite.dts                  |  13 ++
 arch/arm/dts/sc594-som.dtsi                        |  19 +++
 arch/arm/dts/sc598-som-ezkit.dts                   |  13 ++
 arch/arm/dts/sc598-som-ezlite.dts                  |  13 ++
 arch/arm/dts/sc598-som.dtsi                        |  31 +++++
 arch/arm/dts/sc5xx.dtsi                            |  54 ++++++++
 arch/arm/mach-sc5xx/Kconfig                        | 145 +++++++++++++++++----
 arch/arm/mach-sc5xx/Makefile                       |   4 +
 arch/arm/mach-sc5xx/sc57x-spl.c                    |  26 ++++
 arch/arm/mach-sc5xx/sc58x-spl.c                    |  26 ++++
 arch/arm/mach-sc5xx/sc59x-spl.c                    |  26 ++++
 arch/arm/mach-sc5xx/sc59x_64-spl.c                 |  26 ++++
 arch/arm/mach-sc5xx/sc59x_64.c                     |  25 ++++
 arch/arm/mach-sc5xx/soc.c                          |  36 +++++
 board/adi/sc573-ezkit/Kconfig                      | 116 +++++++++++++++++
 board/adi/sc573-ezkit/sc573-ezkit.env              |  13 ++
 board/adi/sc584-ezkit/Kconfig                      | 116 +++++++++++++++++
 board/adi/sc584-ezkit/sc584-ezkit.env              |  13 ++
 board/adi/sc589-ezkit/Kconfig                      | 116 +++++++++++++++++
 board/adi/sc589-ezkit/sc589-ezkit.env              |  13 ++
 board/adi/sc589-mini/Kconfig                       | 116 +++++++++++++++++
 board/adi/sc589-mini/sc589-mini.env                |  13 ++
 board/adi/sc594-som-ezkit/Kconfig                  | 133 +++++++++++++++++++
 board/adi/sc594-som-ezkit/sc594-som-ezkit.env      |  13 ++
 board/adi/sc594-som-ezlite/Kconfig                 | 133 +++++++++++++++++++
 board/adi/sc594-som-ezlite/sc594-som-ezlite.env    |  13 ++
 board/adi/sc598-som-ezkit/Kconfig                  | 100 ++++++++++++++
 board/adi/sc598-som-ezkit/sc598-som-ezkit.env      |  13 ++
 board/adi/sc598-som-ezlite/Kconfig                 | 100 ++++++++++++++
 board/adi/sc598-som-ezlite/sc598-som-ezlite.env    |  13 ++
 common/spl/Kconfig                                 |  17 ++-
 doc/device-tree-bindings/arm/adi/adi,sc5xx.yaml    |  46 +++++++
 .../clock/adi,sc5xx-clocks.yaml                    | 112 ++++++++++++++++
 .../timer/adi,sc5xx-gptimer.yaml                   |  42 ++++++
 include/configs/sc573-ezkit.h                      |  18 +++
 include/configs/sc584-ezkit.h                      |  18 +++
 include/configs/sc589.h                            |  19 +++
 include/configs/sc594-som.h                        |  19 +++
 include/configs/sc598-som.h                        |  23 ++++
 50 files changed, 1923 insertions(+), 29 deletions(-)
---
base-commit: 1312faac5f52d27cfb45dfe1a5a93a2944ca5c21
change-id: 20240821-sc5xx-upstreaming-patches-c048ba9f979a

Best regards,
-- 
Oliver Gaskell <Oliver.Gaskell@analog.com>

