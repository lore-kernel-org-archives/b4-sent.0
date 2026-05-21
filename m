From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v3 0/2] Add PWM support Amlogic S7 S7D S6
Date: Thu, 21 May 2026 08:26:57 +0000
Message-Id: <20260521-s6-s7-pwm-v3-0-57b073fbafef@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANHBDmoC/1WMzQ6CMBAGX4X07Jqy2B88+R7GA5QCmwglrakaw
 rtbSIx4nN1vZmbBerKBnbOZeRspkBsTFIeMmb4aOwvUJGbIUfICBQQJQcH0HAB1LoWutVaFZGk
 /edvSa2tdb4l7Cg/n31s65uv1W5G7SsyBg1QWW4V1qWtzqYa768gcjRvY2on4c08c9y6urlCNs
 elTCvnvLsvyARIbnMHgAAAA
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
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779352023; l=1053;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=bzdk7Kr97M8ZTKkR73nEt8S7smKlwLk3jyxCaislBCE=;
 b=fQiZzM/Lh8PPnpiLD5LGzPb/OkLEGlqImpKBfEDcs3FUg3JubOsnLumaApJU5vjcr4iZI7XYT
 stuhJIZ/1xGCaD7/XckedZzIBGzrxZzihsUTqgTQOjCd/oOqTvvpAOr
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings and driver support Amlogic S7/S7D/S6 SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
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

Xianwei Zhao (1):
      pwm: meson: Add support for Amlogic S7

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       | 19 ++++++++++
 drivers/pwm/pwm-meson.c                            | 41 ++++++++++++++++++++--
 2 files changed, 57 insertions(+), 3 deletions(-)
---
base-commit: b1385d0c7b7c633e55adcf4a7c1ef46c43a84a4a
change-id: 20260325-s6-s7-pwm-281658b88736

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

