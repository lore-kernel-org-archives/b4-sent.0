From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] Power: Add power domain for A9
Date: Wed, 22 Jul 2026 08:39:30 +0000
Message-Id: <20260722-a9-pm-v1-0-1fe20a44bf2d@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMKBYGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMj3URL3YJcXePUtCTjNKNEkxRzIyWg2oKi1LTMCrA50bG1tQDAyC7
 HVwAAAA==
X-Change-ID: 20260722-a9-pm-3efb3f2a4d72
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulfh@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784709572; l=814;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=QQCi8joyIQJkB/7W6FFWGEeP6YN+mclhm8poIQ026HY=;
 b=WLQ47soAxbaZK576/tY+iiZaJ+qwcSMeFxILfLIWBKgQ9gUpoJkMTVFTUiaU9RzgZsL9M+dAC
 J6phS4teZz6CL993sARjLs4UT/eYb9BYbCni9oX3A4iZJRMwX2xfUXU
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power controller driver support for Amlogic A9 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: power: Add Amlogic A9 power domains
      pmdomain: amlogic: Add support for A9 power domains controller
      arm64: dts: amlogic: a9: Add power domain controller node

 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  1 +
 arch/arm64/boot/dts/amlogic/amlogic-a9.dtsi        | 10 ++++
 drivers/pmdomain/amlogic/meson-secure-pwrc.c       | 69 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,a9-pwrc.h        | 61 +++++++++++++++++++
 4 files changed, 141 insertions(+)
---
base-commit: 544455a3a844edd6107b15cd0ab0b657399f2d49
change-id: 20260722-a9-pm-3efb3f2a4d72

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

