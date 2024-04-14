From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/4] ASUS RT-AC3100 and ASUS RT-AC88U device tree
 improvements
Date: Sun, 14 Apr 2024 20:01:20 +0300
Message-Id: <20240414-for-soc-asus-rt-ac3100-improvements-v1-0-0e40caf1a70a@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAOALHGYC/x3NMQ6DMAxA0asgz7XkkLRDr1J1CK6hHkiQTRES4
 u6NGN/y/wEupuLw7A4w2dS1loZw64C/uUyC+mmGnvpEKUQcq6FXxuw/R1sxcwxEqPNidZNZyur
 INOSUHvc4cIRWWkxG3a/L632efx6rFFR1AAAA
To: Florian Fainelli <florian.fainelli@broadcom.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, 
 =?utf-8?q?Rafa=C5=82_Mi=C5=82ecki?= <zajec5@gmail.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713114081; l=974;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=ted2EB6/3rRPIS/bCEaZLR50/zdj+pHcSxe+25yLhvg=;
 b=xmIWfBZS6gMIuWyH9ZufjaesZaWHkmSMkBS50irEp196eawGCZbnHq6O2mvwKIJCHQgjkD1O/
 jp4QXiYPBQlCBldgqjh4o1DhT/+Hlu90jOHeY2SvkzpQ2ACxmfiyEKJ
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello.

This patch series introduces small improvements to the device trees of ASUS
RT-AC3100 and ASUS RT-AC88U.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (4):
      ARM: dts: BCM5301X: use color and function on ASUS RT-AC3100 and RT-AC88U
      ARM: dts: BCM5301X: provide address for SoC MACs on ASUS RT-AC3100 & AC88U
      ARM: dts: BCM5301X: remove duplicate compatible on ASUS RT-AC3100 & AC88U
      ARM: dts: BCM5301X: remove earlycon on ASUS RT-AC3100 and ASUS RT-AC88U

 .../boot/dts/broadcom/bcm47094-asus-rt-ac3100.dts  | 13 ++++-
 .../boot/dts/broadcom/bcm47094-asus-rt-ac3100.dtsi | 59 ++++++++++++----------
 .../boot/dts/broadcom/bcm47094-asus-rt-ac88u.dts   |  8 ++-
 3 files changed, 51 insertions(+), 29 deletions(-)
---
base-commit: 011d79ef1cfad701c2d8e7e80d8c77523af9c771
change-id: 20240413-for-soc-asus-rt-ac3100-improvements-c0ba44653bc3

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

