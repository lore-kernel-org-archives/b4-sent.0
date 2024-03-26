From: Folker Schwesinger <dev@folker-schwesinger.de>
Subject: [PATCH 0/3] phy: rockchip: emmc: Enable internal strobe pull-down
 by default
Date: Tue, 26 Mar 2024 19:54:34 +0100
Message-Id: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOsZA2YC/x3NTQqDMBBA4avIrB3QRKX0KsVFfiY6NCQy0bYg3
 r3B5bd574RCwlTg2Zwg9OHCOVX0bQNuNWkhZF8NqlNDp9WE8kZPwRxxR0rGRsKyS7aE2xGjz9+
 EWo+Te7jQ2yFA7WxCgX/34zVf1x+9MGmIcwAAAA==
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Chris Ruehl <chris.ruehl@gtsys.com.hk>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Christopher Obbard <chris.obbard@collabora.com>, 
 Alban Browaeys <alban.browaeys@gmail.com>, 
 Doug Anderson <dianders@chromium.org>, 
 Brian Norris <briannorris@chromium.org>, 
 Jensen Huang <jensenhuang@friendlyarm.com>, linux-phy@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Folker Schwesinger <dev@folker-schwesinger.de>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1969;
 i=dev@folker-schwesinger.de; h=from:subject:message-id;
 bh=E43foxj+UySf1m9AXwAy4EcKz2179uEogLNPhzYtuqU=;
 b=owGbwMvMwCXG5FBoZNu1u5bxtFoSQxqzVPcG4XrhRdxbmas+173ql3lw5G3uxq5OPd6sDzq9m
 U3MsX86SlkYxLgYZMUUWVjzMrYwZ5Yvte76+RpmDisTyBAGLk4BmMgeNoY/nM+WhP5tVnq2wjs6
 kPnsU9EmyWUTV69YUBTcenfrjbKcfoZ/RmG52hezVCr2HS/90XD65CTtk8kWC3YYC4SuPKa2tfc
 NJwA=
X-Developer-Key: i=dev@folker-schwesinger.de; a=openpgp;
 fpr=056E68B4036977A53B8AF9EB024071323D8ABB7D
X-Endpoint-Received: by B4 Relay for dev@folker-schwesinger.de/default with auth_id=144
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Various RK3399 boards, including the Rock Pi 4 series, the NanoPi 4
series and possibly others showed instabilities with some eMMC modules
when operating in HS400 mode [1]. Later, a missing pull-down resistor on
the eMMC strobe line was identified as the root cause of these
instabilities [2].

This series changes the Rockchip eMMC PHY driver to enable the
internal pull-down for the strobe line by default, effectively
restoring the behavior of the vendor kernel [3].
Addressing the problem in the driver avoids fix-ups in individual
board DTs.

As this change makes the optional DT property enable-strobe-pulldown
obsolete, it is replaced by a new property disable-strobe-pulldown,
that, when used, allows to disable the internal pull-down.

While at it, the enable-strobe-pulldown property was removed from the
NanoPi4 series DTS (which was the only user of the property in the kernel).

[1]: https://lore.kernel.org/all/20230705144255.115299-1-chris.obbard@collabora.com/
[2]: https://lore.kernel.org/all/20220822074139.3810-1-jensenhuang@friendlyarm.com/
[3]: https://github.com/rockchip-linux/kernel/blob/develop-4.4/drivers/phy/rockchip/phy-rockchip-emmc.c#L310

Signed-off-by: Folker Schwesinger <dev@folker-schwesinger.de>
---
Folker Schwesinger (3):
      phy: rockchip: emmc: Enable pulldown for strobe line
      devicetree: phy: rockchip-emmc: Document changed strobe-pulldown property
      arm64: dts: rockchip: Remove enable-strobe-pulldown for NanoPi4 boards

 Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt | 4 ++--
 arch/arm64/boot/dts/rockchip/rk3399-nanopi4.dtsi            | 1 -
 drivers/phy/rockchip/phy-rockchip-emmc.c                    | 6 +++---
 3 files changed, 5 insertions(+), 6 deletions(-)
---
base-commit: 4cece764965020c22cff7665b18a012006359095
change-id: 20240326-rk-default-enable-strobe-pulldown-3356c8cf1b4f

Best regards,
-- 
Folker Schwesinger <dev@folker-schwesinger.de>

