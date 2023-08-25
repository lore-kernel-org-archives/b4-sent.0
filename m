From: Nikita Shubin <nikita.shubin@maquefel.me>
Subject: [PATCH v2 0/2] device tree support for ST M48T86
Date: Fri, 25 Aug 2023 11:43:24 +0300
Message-Id: <20230823-m48t86_device_tree-v2-0-21ff275f949d@maquefel.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKxp6GQC/32NTQ6CMBBGr0JmbU0pVYor72EIGcogTSzotBIN4
 e4WDuDyfT95CwRiRwEu2QJMswtuGhOoQwZ2wPFOwnWJQUlVSKMK4bWJ5tx0aWupiUwksFSEqCp
 dVgbSscVAomUc7bBdPYZIvBVPpt59dtutTjy4ECf+7vI539K/njkXUigt06TVxQnt1ePrTT09j
 p6gXtf1B2QIIJXPAAAA
To: Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linus.walleij@linaro.org>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692953023; l=1298;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=vnXQ9pNzSHGVvPmZJ7uQHNEZVNLQ05YRY8c7hb7Ravk=;
 b=UMK5u45Hw5yI/xg/NWbYvdUnHJhZO/nb7EBm0ZXilbIfLzsQ7FHSj56ClPW4RbRvESJW8o2cnqsk
 mlIGoqixDBVTcjor5QBif9BAnfX6kjz8V70snTLiYMQgzk7njo3W
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree support for ST M48T86.

The reason it can't go to trivial-rtc.yaml, is that it has 2 registers
instead of a single one. The registers are 1 byte wide.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
Changes in v2:
- add links to mailthreads where the actual tags were recieved:
  - dt-bindings: rtc: Add ST M48T86 was Reviewed-by Krzysztof in v3 "ep93xx device tree conversion"
  - rtc: m48t86: add DT support for m48t86:
     - Acked-by Arnd in very first "ep93xx device tree conversion"
     - Reviewed-by Linus in v1 "ep93xx device tree conversion"

Was asked by Krzysztof to send this part separately.

Link: https://lore.kernel.org/lkml/61b9e036-7864-65c6-d43b-463fff896ddc@linaro.org/
Link: https://lore.kernel.org/lkml/20230601054549.10843-12-nikita.shubin@maquefel.me/

---
Nikita Shubin (2):
      dt-bindings: rtc: Add ST M48T86
      rtc: m48t86: add DT support for m48t86

 .../devicetree/bindings/rtc/st,m48t86.yaml         | 38 ++++++++++++++++++++++
 drivers/rtc/rtc-m48t86.c                           |  8 +++++
 2 files changed, 46 insertions(+)
---
base-commit: 89bf6209cad66214d3774dac86b6bbf2aec6a30d
change-id: 20230823-m48t86_device_tree-a72eaa294798

Best regards,
-- 
Nikita Shubin <nikita.shubin@maquefel.me>

