From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/4] Document ASUS RT-AC3200 and ASUS RT-AC5300 and add
 device trees
Date: Sun, 14 Apr 2024 14:45:59 +0300
Message-Id: <20240414-for-soc-asus-rt-ac3200-ac5300-v1-0-118c90bae6e5@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPfBG2YC/x3MTQrCQAxA4auUrA3E6dS/q4iLaZrRbDqSVBFK7
 27o6vFt3goupuJw61Yw+aprmwPHQwf8KvNTUKcwJEqZMl2wNkNvjMU/jrZg4T4RRYY+MkwnqZw
 4X88jxONtUvW3/++PbfsD8bV2/m8AAAA=
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, Rafal Milecki <zajec5@gmail.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713095170; l=956;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=33wdznBHcrNrNHH/FVF4hi5/RJGXD7RBWwqYcSqj5MY=;
 b=sIZCGgog3BeSnH4dfJhskcNWfY+9MZ+GaltlVyK4WmiTPZgTD5KZzwskCoUa3Axu/fzj0yKoh
 bxQtN2AQbQeCd/1QX8/jRVtc0VExaoehdw6zmaPjZC4Ou2pKWpfVjaA
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This patch series documents the compatible strings for ASUS RT-AC3200 and
ASUS RT-AC5300, and adds the device trees for them.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (4):
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC3200
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC5300
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC3200
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC5300

 .../devicetree/bindings/arm/bcm/brcm,bcm4708.yaml  |   2 +
 arch/arm/boot/dts/broadcom/Makefile                |   2 +
 .../boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts   | 164 ++++++++++++++++++++
 .../boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts  | 170 +++++++++++++++++++++
 4 files changed, 338 insertions(+)
---
base-commit: 011d79ef1cfad701c2d8e7e80d8c77523af9c771
change-id: 20240408-for-soc-asus-rt-ac3200-ac5300-5d6efc2c497b

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

