From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] Add the PCA9655E GPIO expander to Kobol Helios64
Date: Fri, 09 Oct 2026 20:45:35 +0000
Message-Id: <20261009-helios64-pca9655-v1-0-673ee4432650@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHBSyWoC/x3MQQqAIBBA0avErBswU8GuEi1kmnIgLBQikO6et
 HyL/ysUzsIFpq5C5luKnKlh6DugGNLOKGszaKXdoJTHyIecxRm8KHhnLY7emZF0oM2s0LIr8yb
 Pv5yX9/0AYNOxXWIAAAA=
To: Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Rosen Penev <rosenp@gmail.com>, 
 Gregory Clement <gregory.clement@bootlin.com>, Andrew Lunn <andrew@lunn.ch>, 
 Sebastian Hesselbarth <sebastian.hesselbarth@gmail.com>, 
 linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1301; i=iav@iav.lv;
 h=from:subject:message-id; bh=UQ+m+cX3b8a09KtNN9qmo839za4WugcpVesAEN25Y/A=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkng4q0jVm3fLHmSZ6XtP9CnjVPy+yV+xJmp7YomyX7c
 K63MV3fUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACbyq4bhf2RqyCKN1INvJcPa
 p96bwFmz2nXbDdZ4jpaJO8VVrye+SGBkWPb2ncVBz06jMyIs+9+uXLOr/v2SfVN9y6JW9TyNO9V
 5iwEA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Rosen's binding v2 Krzysztof quoted the "onnn,pca9655",
"nxp,pca9555" form [1]. This series documents that form and adds its
first user, the expander on Kobol Helios64. Patch 1 is for the GPIO
tree, patch 2 for the Rockchip tree; they only meet in dtbs_check.

6dfda7947653 ("ARM: dts: marvell: armada-388: use onnn,pca9655
compatible") in linux-next lists "onnn,pca9655" alone on Clearfog and
Helios4; with this binding they would need the fallback as well.

Tested on Helios64 (7.3-rc6 with this DTB): pca953x binds at 2-0020,
all 16 lines read as inputs, and the interrupt on GPIO0_B1 is
registered and stays quiet. Interrupt delivery is not tested: nothing
is connected to the P5 header.

[1] https://lore.kernel.org/r/20261009-venomous-carmine-locust-f788ca@quoll

---
Igor Velkov (2):
      dt-bindings: gpio: pca95xx: add onnn,pca9655 with nxp,pca9555 fallback
      arm64: dts: rockchip: Add the GPIO expander to Kobol Helios64

 .../devicetree/bindings/gpio/gpio-pca95xx.yaml       |  3 +++
 .../boot/dts/rockchip/rk3399-kobol-helios64.dts      | 20 ++++++++++++++++++++
 2 files changed, 23 insertions(+)
---
base-commit: 36b190eca882ecd39b5354f7ee995f939dc6d885
change-id: 20261009-helios64-pca9655-39643c2acf4d

Best regards,
-- 
Igor Velkov <iav@iav.lv>

