From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH v2 0/2] Pinephone Pro Connectivity: Adding Modem,
 Bluetooth, and Wi-Fi
Date: Mon, 24 Aug 2026 22:18:15 -0700
Message-Id: <20260824-ppp_connectivity-v2-0-a4b0e11cd62c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WOQQ6CMBBFr0JmbUlbEZSV9zDEQBlhEmlrWxsJ4
 e5WWDu7N/nz5i/g0RF6qLMFHEbyZHQCechAja0ekFGfGCSXJRdCMmvtXRmtUQWKFGZ2wj5N1RU
 XXkA6sw4f9NmUt2Znh693Mod9CV3rkSkzTRTqLFa5hF9uJB+Mm7cmUWzB/0+jYJzJc9GXeD52U
 sjrMLX0zJMVmnVdv9b81hvYAAAA
X-Change-ID: 20260112-ppp_connectivity-5edddd7b4904
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Lee Jones <lee@kernel.org>, Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, linux-clk@vger.kernel.org, 
 mfd@lists.linux.dev, Martijn Braam <martijn@brixit.nl>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787635096; l=3246;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=c8m+kP4UJbinGZZP2vZ7BLyVif62dvbVb9w5w4QtJ2c=;
 b=eDOMM9OmCwYq19j0gxgg9RZnGrdgNhF6ujkRI210fik9net1+FPePUNOMqma7F1PoPW9p2xeD
 a56SRW7MxFjBjIRkeG3gkYif1H3LKFgLDw4rHnhD4d1/WZDeoDS1HWG
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Continuing the work on upstreaming Pinephone Pro functionality,
this patch series gets the connectivity side of the Pinephone Pro
mainlined. Here are the following sources:

- https://codeberg.org/megi/linux
- https://gitlab.com/pine64-org/linux/-/commit/f9f847c6fd1

All credits to the following folks:
- Martijn Braam: original author for the Pinephone Pro bringup
- Kamil Trzcinski: original author for the Pinephone Pro bringup. No
  longer credited as I can't seem to contact this person
- Ondrej Jirman: maintains https://codeberg.org/megi/linux
- Dang Huynh: for the modem patch above

As far as I can tell, I've credited everyone that I know about, but
may be missing some because of how long its been since the original
implementation till now has been.

I've also included a short guide on how to test these patches. This
generally follows this page:
https://wiki.postmarketos.org/wiki/PINE64_PinePhone_Pro_(pine64-pinephonepro)

To test, please follow the following steps:
    https://wiki.postmarketos.org/wiki/PINE64_PinePhone_Pro_(pine64-pinephonepro)#External_storage_(microSD_card)

To build your own image, you will need to do something like this:
pmbootstrap init    # I typically choose Phosh. Defaults should work
wget https://gitlab.postmarketos.org/postmarketOS/pmaports/-/raw/main/device/community/linux-pine64-pinephonepro/config-pine64-pinephonepro.aarch64 -O arch/arm64/configs/orangepi_defconfig
make LLVM=1 CC="ccache clang" O=.output ARCH=arm64 -j $(nproc) W=1 orangepi_defconfig all
pmbootstrap build --envkernel linux-pine64-pinephonepro
pmbootstrap build --force device-pine64-pinephonepro
pmbootstrap install --sdcard=/dev/sdX    # Change /dev/sdX appropriately
pmbootstrap -y zap -a    # Cleanup everything

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Changes in v2:
- dropped removing the interrupt GPIO for Wifi as that is now merged into mainline
- reworked clkout2
- dropped all the signed-off-by's. credited in cover letter
- Link to v1: https://lore.kernel.org/r/20260112-ppp_connectivity-v1-0-284d6e83b212@gmail.com

To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Heiko Stuebner <heiko@sntech.de>
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney@redhat.com>
To: Lee Jones <lee@kernel.org>
Cc: devicetree@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-rockchip@lists.infradead.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: mfd@lists.linux.dev

---
Martijn Braam (2):
      arm64: dts: rockchip: Enable the EG25-G modem on the Pinephone Pro
      clk: rk808: Select the clock function of CLK32KOUT2 on the RK818

 .../boot/dts/rockchip/rk3399-pinephone-pro.dts     | 69 ++++++++++++++++++++++
 drivers/clk/clk-rk808.c                            | 46 ++++++++++++++-
 include/linux/mfd/rk808.h                          |  1 +
 3 files changed, 115 insertions(+), 1 deletion(-)
---
base-commit: 237a1c39e8dfd3e1c6f1f023eea37a48ec04cc63
change-id: 20260112-ppp_connectivity-5edddd7b4904

Best regards,
--  
Rudraksha Gupta <guptarud@gmail.com>

