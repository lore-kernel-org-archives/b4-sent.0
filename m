From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/2] i2c: Add driver support Amlogic A9 I2C
Date: Thu, 22 Oct 2026 09:26:08 +0000
Message-Id: <20261022-a9-i2c-v2-0-45e3cef175bf@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALHW2WoC/zWNwQ6DIBAFf8VwLq1sicWe+h+NB8BVN6nQgCE2x
 n8vmPY4700yG4sYCCO7VxsLmCiSdxngVDE7aTcipz4zgxqauhWC65YTWA5S3hQCYKOuLMtGR+Q
 maGenomflUjSH61Lud8CB1qPz7DJPFBcfPkc2ibL+CiD/hSR4zY3SfWtkM0itHnp++ZHs2fqZd
 fu+fwFJiKgLvQAAAA==
X-Change-ID: 20260911-a9-i2c-24478e22e683
To: Junyi Zhao <junyi.zhao@amlogic.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Xianwei Zhao <xianwei.zhaol@amlogic.com>
Cc: Junyi Zhao <junyi.zhaol@amlogic.com>, linux-i2c@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792661171; l=1291;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=lgCx6iIhgtG4pBSTGFRd3faIm5dYhSgEQN1+ngpmI9g=;
 b=GSVpFUVXSp4fB7ZRpJvmq8UQN8H4ZLd0NQMr4Gtr53ZbLXBuWhrmygvL7Wg5j3PTif2T8TnXC
 XMdXiZuDbBsDW5X+EoBOK0xq7EDf/VP1p+y4VOYWi6xipQ9vqUAXWX4
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a Device Tree binding and driver for the I2C controller found on the
Amlogic A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- dtbinding: make some minor modifications, suggestted by Conor and robot.
- driver: Make some adjustments, including macro definitions, format adjustments,
          adding quirks, process optimization, and so on. According to Andi and robot's suggestion
- Give up MAINTAINERS file the separate submission, make it together with the driver.
- Link to v1: https://lore.kernel.org/r/20260924-a9-i2c-v1-0-b8ad9b46f4a8@amlogic.com

---
Junyi Zhao (1):
      i2c: amlogic: Add Amlogic A9 I2C controller driver

Xianwei Zhao (1):
      dt-bindings: i2c: add Amlogic A9 I2C controller

 .../devicetree/bindings/i2c/amlogic,a9-i2c.yaml    |  56 +++
 MAINTAINERS                                        |   9 +
 drivers/i2c/busses/Kconfig                         |   8 +
 drivers/i2c/busses/Makefile                        |   1 +
 drivers/i2c/busses/i2c-amlogic-a9.c                | 469 +++++++++++++++++++++
 5 files changed, 543 insertions(+)
---
base-commit: 4ec2365c08de306f52650d8736aef5862baedb8d
change-id: 20260911-a9-i2c-24478e22e683

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

