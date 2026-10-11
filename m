From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH v2 0/9] pinephone-pro-rk3399: enable display and USB gadget
Date: Sun, 11 Oct 2026 21:35:42 +0200
Message-Id: <20261011-b4-pinephone-pro-defconfig-v2-0-6b7be35fbee7@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr2K6dkxboUVX3sOwgDKFMdI2LRIN4
 e4WvIDLl//z3sISRsLEroeFRZwpkXcZ5PHAzNC4HoG6zExyqQQXHNoCAjkMg3cIIXro0BrvLPV
 gq3OjeKNLrTTLghDR0nuX3+sfp1f7QDNtxu0xUJp8/Oz1WWy/v0KzAAFlWVQaKyPVBW95n7wbG
 3qejB9Zva7rFx63hgHbAAAA
X-Change-ID: 20261010-b4-pinephone-pro-defconfig-f83a60a75767
To: u-boot@lists.u-boot-project.org
Cc: Peter Robinson <pbrobinson@gmail.com>, David Heidelberg <david@ixit.cz>, 
 Ondrej Jirman <megi@xff.cz>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, Simon Glass <sjg@chromium.org>, 
 Philipp Tomsich <philipp.tomsich@vrull.eu>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Lukasz Majewski <lukma@denx.de>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791747347; l=2951;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=bMM97UtOmPn252lxqp+l7iRphjL6KRTbx5k7lFIxSBQ=;
 b=k2sk7toprx89vGq4tQW1hVbejsbu9usxcQKs6Q7eNQBxHvGtLXI93KkdAKL4MSRbUDOi+arNA
 pe7bJvNifokCKPMtlqoUwv6PxnXzBWU/vX/djy4PcDRKKA6Wxy2LmQy
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the MIPI-DSI panel and the USB gadget stack on the Pinephone
Pro. Additionaly enable the buttons, DFU, mass storage and watchdog
bits needed to drive it without a serial console. The volume keys depend on the
separate "button: adc: implement get_code()" patch series. See:

https://lore.kernel.org/all/20261010-b4-button-adc-get-code-v1-1-843d04f5dfd5@protonmail.com/T/#t

The DSI/VOP display and the USB peripheral DTS are based on Ondrej
Jirman's tree. Tested on a Pinephone Pro.

See https://download.ixit.cz/ppro.jpeg

For convenience the DFU targets the spinor so the initial sequence to
flash the firmware needs to be done just once.

'''
rkdeveloptool db rk3399_loader_spinor_v1.15.114.bin
rkdeveloptool wl 0 u-boot-rockchip-spi.bin
rkdeveloptool rd
'''

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v2:
- Add USB peripheral mode
- Add the DSI/VOP display stack
- Split into clk, DSI core, lane rate, dphy, display adapter and DTS
- Update defconfig patch
- Define DFU spinor target
- Link to v1: https://patch.msgid.link/20261010-b4-pinephone-pro-defconfig-v1-1-55487e8c269e@protonmail.com

To: u-boot@lists.u-boot-project.org
Cc: Simon Glass <sjg@chromium.org>
Cc: Philipp Tomsich <philipp.tomsich@vrull.eu>
Cc: Kever Yang <kever.yang@rock-chips.com>
Cc: Peter Robinson <pbrobinson@gmail.com>
Cc: Tom Rini <trini@konsulko.com>
Cc: Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Ondrej Jirman <megi@xff.cz>
Cc: Petr Hodina <petr.hodina@protonmail.com>
Cc: Lukasz Majewski <lukma@denx.de>
Cc: Anatolij Gustschin <ag.dev.uboot@gmail.com>

---
Ondrej Jirman (1):
      arm: dts: rk3399-pinephone-pro: Enable USB port (peripheral mode)

Petr Hodina (8):
      clk: rockchip: rk3399: add the clocks the DSI and VOP paths need
      video: dw_mipi_dsi: sync LP command and clock lane handling with Linux
      video: rockchip: dw_mipi_dsi: account for burst mode in the lane rate
      video: rockchip: dw_mipi_dsi: tolerate -ENOENT for the optional dphy
      video: rockchip: dw_mipi_dsi: add a UCLASS_DISPLAY adapter for rk_vop
      arm: dts: rk3399-pinephone-pro-u-boot: drop VOP clock assignments
      configs: pinephone-pro-rk3399: Update defconfig
      configs: pinephone-pro-rk3399: add a DFU alt setting for the SPI NOR

 arch/arm/dts/rk3399-pinephone-pro-u-boot.dtsi | 33 +++++++++
 configs/pinephone-pro-rk3399_defconfig        | 17 ++++-
 drivers/clk/rockchip/clk_rk3399.c             | 21 ++++++
 drivers/video/dw_mipi_dsi.c                   | 33 ++++++---
 drivers/video/rockchip/dw_mipi_dsi_rockchip.c | 96 ++++++++++++++++++++++-----
 include/configs/pinephone-pro-rk3399.h        |  3 +-
 6 files changed, 176 insertions(+), 27 deletions(-)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-pinephone-pro-defconfig-f83a60a75767

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

