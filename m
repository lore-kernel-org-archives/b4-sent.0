From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/4] phy: hisi-inno-phy: add support for
 hi3798mv200-usb2-phy
Date: Fri, 16 Feb 2024 23:21:00 +0800
Message-Id: <20240216-inno-phy-v1-0-1ab912f0533f@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFx9z2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0Mz3cy8vHzdgoxK3USjFAtzozSzJHOTJCWg8oKi1LTMCrBR0UpBbs5
 KsbW1AO6AnyJfAAAA
To: Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Pengcheng Li <lpc.li@hisilicon.com>, Shawn Guo <shawn.guo@linaro.org>
Cc: linux-phy@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Kishon Vijay Abraham I <kishon@ti.com>, 
 David Yang <mmyangfl@gmail.com>, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708096886; l=1304;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=IxnSWTB2sBXQF0390u8a976PN+j85jvd6/lGGofC8VY=;
 b=jVZPCURmpgkvsGh4pmLptz411OscyhZfFOxAAmB4AKycoTJpCK24CwzaBAjfCCKBgjM8qYArr
 uVTzXRcqYHvCIgzGWjYN3cP73jcSNBzIRH0pfkqv/yg6MlQsD8aC2Eo
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
Yang Xiwen (4):
      dt-binding: phy: hisi-inno-usb2: convert to YAML
      phy: hisilicon: enable clocks for every ports
      phy: hisi-inno-usb2: add support for direct MMIO
      dt-binding: phy: hisi-inno-usb2: add compatible of hisilicon,hi3798mv200-usb2-phy

 .../bindings/phy/hisilicon,inno-usb2-phy.yaml      | 125 +++++++++++++++++++++
 .../devicetree/bindings/phy/phy-hisi-inno-usb2.txt |  71 ------------
 drivers/phy/hisilicon/phy-hisi-inno-usb2.c         |  57 ++++++----
 3 files changed, 161 insertions(+), 92 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-inno-phy-a2d872f6b74b

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

