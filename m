From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] Add PWM support Amlogic S7 S7D S6
Date: Thu, 26 Mar 2026 06:35:37 +0000
Message-Id: <20260326-s6-s7-pwm-v1-0-67e2f72b98bc@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALnTxGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDYyNT3WIz3WJz3YLyXF0jC0MzU4skCwtzYzMloPqCotS0zAqwWdGxtbU
 A5IPHXVsAAAA=
X-Change-ID: 20260325-s6-s7-pwm-281658b88736
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Junyi Zhao <junyi.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774506945; l=648;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=mXw+OnzMTg/llL26Q+CuSnTiRZOcs0RZPrPP1Kk4svA=;
 b=OKuOvNZb4cwcyMGkRCZPv7Lo3XaP6ugCt+rAwxMUC/RBELX+R+vk05Ud6A/aa/KMmrd7brkrb
 15QAhUmz6DYDQdl0VlL1R4Ir0jw8UGCNuyqUtL27raJ6dhJ2p/+1wE0
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings and driver support Amlogic S7/S7D/S6 SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Junyi Zhao (1):
      dt-bindings: pwm: amlogic: Add new bindings for S6 S7 S7D

Xianwei Zhao (1):
      pwm: meson: Add support for Amlogic S7

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       | 27 ++++++++++++++++++
 drivers/pwm/pwm-meson.c                            | 32 ++++++++++++++++++++--
 2 files changed, 57 insertions(+), 2 deletions(-)
---
base-commit: 8ab1fc9104158045f68fde2d0ae16f5fbcf8bfbd
change-id: 20260325-s6-s7-pwm-281658b88736

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

