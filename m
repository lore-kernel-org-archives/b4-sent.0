From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/4] Add PWM support Amlogic S7 S7D S6
Date: Thu, 27 Aug 2026 08:40:09 +0000
Message-Id: <20260827-s6-s7-pwm-v4-0-d28a2015177d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOn3j2oC/2XM3w6CIBiH4VtpHEfDD/ljR91H60AQlC3FQaOa8
 95Dt6atwx98zzuhaIIzEZ0PEwomuej8kEd5PCDd1UNrsGvyRkCAEwoMR46jwOOzxyALzqSSUlC
 O8v0YjHWvtXW95d25+PDhvaZTsbx+K3xXSQUmmAsDVoCqpNKXur/71umT9j1aOgk2WxLYW1gsE
 402+adi/N/SzTIo9pZmy4QiglpVW2N/7TzPH5JA1UscAQAA
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
 Junyi Zhao <junyi.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Alexandre Mergnat <amergnat@baylibre.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787820043; l=1421;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=ktpLGSlyRRlqw7auNzLNwbOhfx3Zng7gvl3lK1CmWIs=;
 b=1mluRuPLujAiR3pYWMwR9d/nxY/Xl2i8+db1I3eTojXLA+UvV9RemLT0/znYBS+HpudSEpHsx
 8m2SQN7OUFBA8QSNObT2Q2Cease9XiDpI6K5sA8P4vVgg3LKrZBzQas
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings and driver support Amlogic S7/S7D/S6 SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- It is divided into three submissions based on the function-driven part.
- Merge and modify functions for init clocks, According to Alexandre's suggestion.
- Link to v3: https://lore.kernel.org/r/20260521-s6-s7-pwm-v3-0-57b073fbafef@amlogic.com

Changes in v3:
- Use npwm instead of single_pwm in priv_data and format adjustments.
- Link to v2: https://lore.kernel.org/r/20260402-s6-s7-pwm-v2-0-657dce040956@amlogic.com

Changes in v2:
- Simpler s7 clock desc, and drop the example in bindings.
- Make minor changes to probe based on Martin's suggestion.
- Link to v1: https://lore.kernel.org/r/20260326-s6-s7-pwm-v1-0-67e2f72b98bc@amlogic.com

---
Junyi Zhao (1):
      dt-bindings: pwm: amlogic: Add new bindings for S6 S7 S7D

Xianwei Zhao (3):
      pwm: meson: add the PWM count driver data
      pwm: meson: use bulk API for per-channel clocks
      pwm: meson: Add support for Amlogic S7

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       | 19 ++++++
 drivers/pwm/pwm-meson.c                            | 73 +++++++++++++---------
 2 files changed, 63 insertions(+), 29 deletions(-)
---
base-commit: b1385d0c7b7c633e55adcf4a7c1ef46c43a84a4a
change-id: 20260325-s6-s7-pwm-281658b88736

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

