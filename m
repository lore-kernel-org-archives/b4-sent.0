From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC v2 0/4] phy: hisi-inno-phy: add support for
 hi3798mv200-usb2-phy
Date: Sat, 17 Feb 2024 22:02:44 +0800
Message-Id: <20240217-inno-phy-v2-0-3bf7e87b0e9e@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIS80GUC/2WMQQ6CMBBFr0JmbU07IKgrExMP4NawaKGVCdohL
 RIJ4e42bF2+/1/eAtEGshHO2QLBThSJfQLcZdB02j+toDYxoMRCoioFec9i6GahsT1W6EpTFQa
 SPgTr6LulHnC/XaFOY0dx5DBv+Ult139pUkIKpc1JoZOHPHcX/owv5n7f8BvqdV1/XYibgKcAA
 AA=
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Shawn Guo <shawn.guo@linaro.org>, Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kishon Vijay Abraham I <kishon@ti.com>, 
 David Yang <mmyangfl@gmail.com>, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708178566; l=1863;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=HB/UpB50BILuiF8CCfmMOQJkOn4bkGggnUNO1Au7/nE=;
 b=9VtvWJ4V8m6j4mczC2xd3BTH2B4ji+ttMI83t6mBEq3+QIfY/Z3xZyGrhV1q081YTkor8OFur
 RHlXOYnBjoGAmx9h+rnXOm3h7dPDjMMla2G0IUHmN9F61Y4Fb5cJIGK
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This should be considered a dirty hack. The proper solution would be
extracting write_reg logic to a separate regmap driver. Leaving only
"write BIT(2) to address 0x6" to the PHY driver.

The initial commit is already doing things wrong. The following patches
adding hi3798mv100 support is also very confusing. The name of the
enumeration "PHY_TYPE_x" is very misleading as if it's the phy which is
different across SoCs. But actually it's the bus (i.e. how to write to a
given address) which is different, not the PHY.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v2:
- rewrite commit msg to show why hisilicon,hi3798mv100-usb2-phy is added
  during YAML convertion.
- split required: to multiple line
- add allOf to wrap if:
- remove perictrl wrapper and the second phy in the example
- tested the binding both for mv200 and cv200 dts. fix some silly
  errors.
Above all are suggested by Krzysztof
- use reset_control_array_* APIs to ensure all resets are controlled
- Link to v1: https://lore.kernel.org/r/20240216-inno-phy-v1-0-1ab912f0533f@outlook.com

---
Yang Xiwen (4):
      dt-bindings: phy: hisi-inno-usb2: convert to YAML
      phy: hisilicon: hisi-inno-phy: enable clocks for every ports
      phy: hisilicon: hisi-inno-phy: add support for Hi3798MV200 INNO PHY
      dt-bindings: phy: hisi-inno-usb2: add compatible of hisilicon,hi3798mv200-usb2-phy

 .../bindings/phy/hisilicon,inno-usb2-phy.yaml      | 123 +++++++++++++++++++++
 .../devicetree/bindings/phy/phy-hisi-inno-usb2.txt |  71 ------------
 drivers/phy/hisilicon/phy-hisi-inno-usb2.c         |  69 +++++++-----
 3 files changed, 165 insertions(+), 98 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-inno-phy-a2d872f6b74b

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

