From: Nikita Shubin <nikita.shubin@maquefel.me>
Subject: [PATCH 0/2] device tree support for ST M48T86
Date: Wed, 23 Aug 2023 12:03:13 +0300
Message-Id: <20230823-m48t86_device_tree-v1-0-240023b435ac@maquefel.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFHL5WQC/x2N0QqDMBAEf0XuuQEbRWN/pRQ547beg2m5C6Ug/
 nujj8PssBsZVGB0qzZSfMXknQpcLxXFhdMLTubC5Gvf1ME3bm1DDt04l23EmBVw3Hsw+6Hth0A
 lnNjgJuUUlyNd2TL0EB/FU37n2/2x73+1k/ArfQAAAA==
To: Alessandro Zummo <a.zummo@towertech.it>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-rtc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nikita Shubin <nikita.shubin@maquefel.me>, 
 Arnd Bergmann <arnd@arndb.de>, Linus Walleij <linus.walleij@linaro.org>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692781413; l=702;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=cBA8LS1Y1PWRmdPmwFWha1Slu8mL5WLDumH/lb3Wq00=;
 b=LXAbPcv1J0wekD7/fEVbVWnPffGhP0mOmiNjuWFhlj2AFOPjtkZNN/bX43+mISssLNFXFj0z4Ou7
 goLNQ4sQCyGjIKQFMnYzGxq5JuHMbCqGiM5FgElvV56j7TNIPedg
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add device tree support for ST M48T86.

The reason it can't go to trivial-rtc.yaml, is that it has 2 registers
instead of a single one. The registers are 1 byte wide.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
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

