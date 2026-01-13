From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH 0/3] Pinephone Pro Connectivity: Adding Modem, Bluetooth,
 and Wi-Fi
Date: Mon, 12 Jan 2026 22:42:23 -0800
Message-Id: <20260112-ppp_connectivity-v1-0-284d6e83b212@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFDpZWkC/yXN2wrCMAyA4VcZvTbSlh3cEPE9ZIzaxRlY29nWq
 ojvbp25+wP58mYBPWFgXfFmHhMFcjaH2BRMX5WdEGjMzSSXNRdCwrIsg3bWoo6UKL6gwjFPcy5
 bXrJ8tni80HMlT/2/Pd7uWY7/JTMYglrlrthnuBJSVis803SNg9Ia58GoaUhuhtE9LKQaOOx00
 6oSdw3n4jgZRfNWO3P4PT2rgJDDUOyKVG9FC15XrP98vtxVLGDiAAAA
X-Change-ID: 20260112-ppp_connectivity-5edddd7b4904
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Lee Jones <lee@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, Martijn Braam <martijn@brixit.nl>, 
 =?utf-8?q?Kamil_Trzci=C5=84ski?= <ayufan@ayufan.eu>, 
 Ondrej Jirman <megi@xff.cz>, Danct12 <danct12@disroot.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768286545; l=3352;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=8tXZjIGktkSj/gIsBOODpm0xDPGQpoD1AscqdH+ddjM=;
 b=zixIm9Y8C+p6V0XPwI08j+ah9mKT91Eo3L76RzVp8W0TjkE+M7AfqSyS7f5AfgUzSQLMyLDEY
 Evxb8NGmqQvBlzyD44ElB20KzPu0uvR7fz8zWayHjnDK1RRsv2JfkCE
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continuing the work on upstreaming Pinephone Pro functionality,
this patch series gets the connectivity side of the Pinephone Pro
mainlined. Here are the following patches with sources to the original
implementation(s):

arm64: dts: rockchip: Remove interrupt GPIO for WiFi for the Pinephone Pro
- arm64: dts: rockchip: Disable interrupt GPIO for WiFi for the Pinephone Pro
----- https://codeberg.org/megi/linux/commit/7395662eb6700ba19a92fbfb244d4858f08404f3

mfd: rk8xx-core: Configure `rk808-clkout2` function
- power: rk818: Configure rk808-clkout2 function
----- https://codeberg.org/megi/linux/commit/75be96faf939504d0fd5112846e73e437573f716

arm64: dts: rockchip: Add modem to the Pinephone Pro
- arm64: dts: rk3399-pinephone-pro: Add 5V power supply
----- https://codeberg.org/megi/linux/commit/808e7cdaf3ed
- arm64: dts: rk3399-pinephone-pro: Add modem support 
----- https://codeberg.org/megi/linux/commit/8f7e3464
- arm64: dts: rk3399-pinephone-pro: Change modem codec samplerate to 16kHz
----- https://codeberg.org/megi/linux/commit/3bea535
- arm64: dts: rk3399-pinephone-pro: Remove modem node
----- https://gitlab.com/pine64-org/linux/-/commit/f9f847c6fd1

I've also included a short guide on how to test these patches. This
generally follows this page:
https://wiki.postmarketos.org/wiki/PINE64_PinePhone_Pro_(pine64-pinephonepro)

To test, please follow the following steps:
// Follow pmbootstrap installation instructions:
//   https://docs.postmarketos.org/pmbootstrap/main/installation.html
// Next, follow the instructions here to put the Pinephone Pro into USB Mass Storage mode:
//   https://wiki.postmarketos.org/wiki/PINE64_PinePhone_Pro_(pine64-pinephonepro)#Internal_storage_(eMMC)
cd /to/linux/directory/with/these/patches/on/top
// I typically choose Phosh. Defaults should work
pmbootstrap init
wget https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/master/device/community/linux-pine64-pinephonepro/config-pine64-pinephonepro.aarch64 -O arch/arm64/configs/orangepi_defconfig
make LLVM=1 CC="ccache clang" O=.output ARCH=arm64 -j $(nproc) W=1 orangepi_defconfig all
pmbootstrap build --envkernel linux-pine64-pinephonepro
pmbootstrap build --force device-pine64-pinephonepro
// Change /dev/sdX appropriately
pmbootstrap install --sdcard=/dev/sdX
// Cleanup everything
pmbootstrap -y zap -a

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Kamil Trzciński (1):
      mfd: rk8xx-core: Configure `rk808-clkout2` function

Ondrej Jirman (1):
      arm64: dts: rockchip: Remove interrupt GPIO for WiFi for the Pinephone Pro

Rudraksha Gupta (1):
      arm64: dts: rockchip: Add modem to the Pinephone Pro

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 86 +++++++++++++++++++++-
 drivers/mfd/rk8xx-core.c                           |  1 +
 include/linux/mfd/rk808.h                          |  2 +
 3 files changed, 86 insertions(+), 3 deletions(-)
---
base-commit: d0e305301e82474223bf26185e86e7dc2eb85350
change-id: 20260112-ppp_connectivity-5edddd7b4904
prerequisite-message-id: <20251225-ppp_light_accel_mag_vol-down-v6-0-8c79a4e87001@gmail.com>
prerequisite-patch-id: 8b32de16edffc9f81d299e40107c95908ead6a81
prerequisite-patch-id: 7714aa0d065ea9bc58a8fe67f04d738153752221

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

