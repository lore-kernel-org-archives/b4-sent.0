From: Folker Schwesinger <dev@folker-schwesinger.de>
Date: Tue, 26 Mar 2024 19:54:36 +0100
Subject: [PATCH 2/3] devicetree: phy: rockchip-emmc: Document changed
 strobe-pulldown property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240326-rk-default-enable-strobe-pulldown-v1-2-f410c71605c0@folker-schwesinger.de>
References: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
In-Reply-To: <20240326-rk-default-enable-strobe-pulldown-v1-0-f410c71605c0@folker-schwesinger.de>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1613;
 i=dev@folker-schwesinger.de; h=from:subject:message-id;
 bh=lYZfvZDtpySgOOqOAfgoLZ9THvZvx3kUJVgOxDEo5RE=;
 b=owGbwMvMwCXG5FBoZNu1u5bxtFoSQxqz1KSXEXPm32GZ9Ic3tF984fKDer0GAtunykV0cP6yz
 H7bbzOzo5SFQYyLQVZMkYU1L2MLc2b5Uuuun69h5rAygQxh4OIUgIloiDH8M3MoEvsnn9Sap6p9
 m/mcrMz8Y3p7k5le/NnupqBbaKzYzfA/8b/SW42WBQVnEx5bsJ+P/fN+1SF+002WnFemZ19pzyr
 mAAA=
X-Developer-Key: i=dev@folker-schwesinger.de; a=openpgp;
 fpr=056E68B4036977A53B8AF9EB024071323D8ABB7D
X-Endpoint-Received: by B4 Relay for dev@folker-schwesinger.de/default with auth_id=144
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the changes regarding the optional strobe-pulldown property.
These changes are necessary as the default behavior of the driver was
restored to the Rockchip kernel behavior of enabling the internal
pulldown by default.

Fixes: f34e43f12382 ("devicetree: phy: rockchip-emmc: pulldown property")
Signed-off-by: Folker Schwesinger <dev@folker-schwesinger.de>
---
 Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt b/Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt
index 57d28c0d5696..10c05437f7ab 100644
--- a/Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt
+++ b/Documentation/devicetree/bindings/phy/rockchip-emmc-phy.txt
@@ -16,8 +16,8 @@ Optional properties:
  - drive-impedance-ohm: Specifies the drive impedance in Ohm.
                         Possible values are 33, 40, 50, 66 and 100.
                         If not set, the default value of 50 will be applied.
- - rockchip,enable-strobe-pulldown: Enable internal pull-down for the strobe
-                                    line.  If not set, pull-down is not used.
+ - rockchip,disable-strobe-pulldown: Disable internal pull-down for the strobe
+                                     line.  If not set, pull-down is used.
  - rockchip,output-tapdelay-select: Specifies the phyctrl_otapdlysec register.
                                     If not set, the register defaults to 0x4.
                                     Maximum value 0xf.

-- 
2.44.0

