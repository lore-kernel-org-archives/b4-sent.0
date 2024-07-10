From: Pieterjan Camerlynck <pieterjanca@gmail.com>
Subject: [PATCH v2 0/2] leds: leds-pca995x: Add support for NXP PCA9956B
Date: Wed, 10 Jul 2024 16:32:40 +0200
Message-Id: <20240710-pca995x-v2-0-8fafb6e4b7d5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIibjmYC/z3MQQrDIBCF4auEWdcy2hixq96jZGGNJgNNDFokJ
 Xj32lC6/B+Pb4fkIrkE12aH6DIlCksNcWrATmYZHaOhNggULSrUbLVGa7mxQVnptfKde1io7zU
 6T9sh3fvaE6VXiO8Dzvy7/gyOfyNzhky2Erns8IKIt3E29DzbMENfSvkAr1tInZ4AAAA=
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Isai Gaspar <isaiezequiel.gaspar@nxp.com>, Marek Vasut <marex@denx.de>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pieterjan Camerlynck <pieterjanca@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720622068; l=1042;
 i=pieterjanca@gmail.com; s=20240709; h=from:subject:message-id;
 bh=HQPU+5jS7G7Dj8KsEuC+g6jBNrSexrUpV+05g1CQqTo=;
 b=+7OE7Srtgo57fzZtzKrAvZxDoLui0UX7KXjIQnCXh1pkUl52uBwoU2xRri3g4xXm0Ee7J7pir
 7GH18tfGxjDDSA2OE+snIK9QgVcFUFm7nmNCBnR9/gIIPmy8cr4PzsO
X-Developer-Key: i=pieterjanca@gmail.com; a=ed25519;
 pk=gSAHfvqQjVhNa1MhUClqbt7d3S+fviKz6FdQVaWFRyM=
X-Endpoint-Received: by B4 Relay for pieterjanca@gmail.com/20240709 with auth_id=182
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for NXP PCA9956B to the pca995x driver. This
chip is similar to the others but has 24 instead of 16 outputs and a
slightly different register layout. Datasheet available at [1].

[1]: https://www.nxp.com/docs/en/data-sheet/PCA9956B.pdf

Signed-off-by: Pieterjan Camerlynck <pieterjanca@gmail.com>
---
Changes in v2:
- define seperate const struct pca995x_chipdef for each chip
- remove chip enum
- Link to v1: https://lore.kernel.org/r/20240710-pca995x-v1-0-545015603000@gmail.com

---
Pieterjan Camerlynck (2):
      dt-bindings: leds: pca995x: Add new nxp,pca9956b compatible
      leds: leds-pca995x: Add support for NXP PCA9956B

 .../devicetree/bindings/leds/nxp,pca995x.yaml      |  6 +-
 drivers/leds/leds-pca995x.c                        | 82 ++++++++++++----------
 2 files changed, 50 insertions(+), 38 deletions(-)
---
base-commit: 82d01fe6ee52086035b201cfa1410a3b04384257
change-id: 20240709-pca995x-d7c5f97f6ebc

Best regards,
-- 
Pieterjan Camerlynck <pieterjanca@gmail.com>

