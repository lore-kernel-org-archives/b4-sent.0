From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH v3 0/5] Document ASUS RT-AC3200 and ASUS RT-AC5300 and add
 device trees
Date: Tue, 23 Apr 2024 12:50:44 +0300
Message-Id: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-0-23d33cfafe7a@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAHSEJ2YC/4XNsQ7CIBDG8VcxzJ45KNTi5HsYB3oFy2AxUImm6
 btLGwedOn353/C7iSUbvU3stJtYtNknH4YS1X7HqDfDzYLvSjOBQqLEBlyIkAKBSc8EcQRDlUA
 so6oyqqutI0FSH1tWjEe0zr9W/3It3fs0hvhe32W+XL8ylxty5oDAeUMaW2Nrq84m+oH0gcKdL
 XQWv5ze4kThnFbOKSRhZPfHzfP8AXFbRjwaAQAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, Rafal Milecki <zajec5@gmail.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713865858; l=2295;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=FQLt1hmXPP3cDkvy4rTvlY0mMo/XhlZ354mwI3by6iM=;
 b=qMdw1MUc3Tww2iXeIs464rNvG05CzXQzzZhWOaRk5Z6RaRjyuPZMdIWfOSsX9zQnfrtgh6GSp
 Pc6+aAB53vfA14d6V+9kO2Fps6t46d9OGKpOk3YewVhmrbw3EybzSTX
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This patch series documents the compatible strings for ASUS RT-AC3200 and
ASUS RT-AC5300, and adds the device trees for them. The last patch makes
the device tree files for ASUS RT-AC3100 and ASUS RT-AC88U conform to the
Devicetree Sources (DTS) Coding Style.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v3:
- Add a new patch to the end.
- Patch 3
  - Reorder the nodes and properties to conform to the Devicetree Sources
    (DTS) Coding Style.
- Patch 4
  - Same as above.
- Link to v2: https://lore.kernel.org/r/20240419-for-soc-asus-rt-ac3200-ac5300-v2-0-f95ff50c2a4d@arinc9.com

Changes in v2:
- Patch 3
  - Remove the chosen node as earlycon is not for mainline use, and the
    stdout-path property which should be used instead of bootargs =
    "console=" is already described in bcm4708.dtsi with the same value.
  - Remove MAC address assignment to switch ports. To explain why shortly,
    on the switch with CPU port architecture, the LLC Entity associated
    with each port can be accessed without a distinct MAC address assigned
    to each port. Therefore, it is unnecessary.
- Patch 4
  - Same as above.
- Link to v1: https://lore.kernel.org/r/20240414-for-soc-asus-rt-ac3200-ac5300-v1-0-118c90bae6e5@arinc9.com

---
Arınç ÜNAL (5):
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC3200
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC5300
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC3200
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC5300
      ARM: dts: BCM5301X: Conform to DTS Coding Style on ASUS RT-AC3100 & AC88U

 .../devicetree/bindings/arm/bcm/brcm,bcm4708.yaml  |   2 +
 arch/arm/boot/dts/broadcom/Makefile                |   2 +
 .../boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts   | 150 ++++++++++++++++++++
 .../boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi |  92 ++++++------
 .../boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts  | 156 +++++++++++++++++++++
 .../boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts   |  69 +++++----
 6 files changed, 390 insertions(+), 81 deletions(-)
---
base-commit: dd5c56cd065e6f7ac5f87b939e8a3c499a62d463
change-id: 20240408-for-soc-asus-rt-ac3200-ac5300-5d6efc2c497b

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

