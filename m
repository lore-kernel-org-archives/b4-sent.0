From: Pieterjan Camerlynck <pieterjanca@gmail.com>
Subject: [PATCH 0/2] leds: leds-pca995x: Add support for NXP PCA9956B
Date: Wed, 10 Jul 2024 08:15:43 +0200
Message-Id: <20240710-pca995x-v1-0-545015603000@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA8njmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDcwNL3YLkREtL0wrdFPNk0zRL8zSz1KRkJaDqgqLUtMwKsEnRsbW1AIU
 h1oJZAAAA
To: Pavel Machek <pavel@ucw.cz>, Lee Jones <lee@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Isai Gaspar <isaiezequiel.gaspar@nxp.com>, Marek Vasut <marex@denx.de>
Cc: linux-leds@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Pieterjan Camerlynck <pieterjanca@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720592196; l=851;
 i=pieterjanca@gmail.com; s=20240709; h=from:subject:message-id;
 bh=pviwYWTgWw3NGArxYhhEFp+fozfsJBF9UBiIPePQypQ=;
 b=gN6PPOVhY6hcmCR6ePaNQo7jHDwWqhmkx7tGNyHg06AKjZ4k+cJdsEUy8EaLP+3JMZ6lf+ANk
 yNjDM/+TE/SCvLoefDlQCMrr8s0wXQMpaMLnRum5O8vuyBH5p3EkUP+
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
Pieterjan Camerlynck (2):
      dt-bindings: leds: pca995x: Add new nxp,pca9956b compatible
      leds: leds-pca995x: Add support for NXP PCA9956B

 .../devicetree/bindings/leds/nxp,pca995x.yaml      |  6 +-
 drivers/leds/leds-pca995x.c                        | 88 +++++++++++++---------
 2 files changed, 56 insertions(+), 38 deletions(-)
---
base-commit: 82d01fe6ee52086035b201cfa1410a3b04384257
change-id: 20240709-pca995x-d7c5f97f6ebc

Best regards,
-- 
Pieterjan Camerlynck <pieterjanca@gmail.com>

