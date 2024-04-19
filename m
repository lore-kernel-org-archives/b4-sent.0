From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH v2 0/4] Document ASUS RT-AC3200 and ASUS RT-AC5300 and add
 device trees
Date: Fri, 19 Apr 2024 10:22:47 +0300
Message-Id: <20240419-for-soc-asus-rt-ac3200-ac5300-v2-0-f95ff50c2a4d@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAMcbImYC/4WNQQ6CMBBFr0K6dkxbCoIr72FYlGGQWUjNFImG9
 O5W4t7Vy/uL9zcVSZiiOhebElo5cpiz2EOhcPLzjYCH7Mpq67TTDYxBIAYEH58RZAGPpdU6oyo
 zqqGmES269tSr3HgIjfza+9cu+8RxCfLe71bzXX9l4/6UVwMajGmw1b2nmqqLF56xPWK4qy6l9
 AHn3XUsywAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713511367; l=1620;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=fTx2/kEZ6vQTQyJpDG0BPTHimKj4QlyE9Zlf2maFXRA=;
 b=C40LCsSt9mET0CXsjILLPq6IXlS0AybUsb2BeYFICsFynLdE0SO7mdqsOlMvr3tcFf/4cJsOY
 GgZ4YnNYIbTCPQ0bKX25EA+BoYK22mAnlotZ3VmQjyzf6Kb031zpCXW
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This patch series documents the compatible strings for ASUS RT-AC3200 and
ASUS RT-AC5300, and adds the device trees for them.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
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
Arınç ÜNAL (4):
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC3200
      dt-bindings: arm: bcm: add bindings for ASUS RT-AC5300
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC3200
      ARM: dts: BCM5301X: Add DT for ASUS RT-AC5300

 .../devicetree/bindings/arm/bcm/brcm,bcm4708.yaml  |   2 +
 arch/arm/boot/dts/broadcom/Makefile                |   2 +
 .../boot/dts/broadcom/bcm4709-asus-rt-ac3200.dts   | 150 ++++++++++++++++++++
 .../boot/dts/broadcom/bcm47094-asus-rt-ac5300.dts  | 156 +++++++++++++++++++++
 4 files changed, 310 insertions(+)
---
base-commit: 011d79ef1cfad701c2d8e7e80d8c77523af9c771
change-id: 20240408-for-soc-asus-rt-ac3200-ac5300-5d6efc2c497b

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

