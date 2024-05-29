From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] Power: A4: add power domain driver
Date: Wed, 29 May 2024 11:10:32 +0800
Message-Id: <20240529-a4_secpowerdomain-v2-0-47502fc0eaf3@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKicVmYC/32NQQ7CIBBFr9LMWgwg1bYr72EaQ2HaTiLQgKmah
 ruLPYDL95L//gYJI2GCrtog4kqJgi8gDxWYWfsJGdnCILlUvJYN0+qe0CzhhdEGp8mzGgfO67N
 q2hOHslsijvTem7e+8EzpGeJnv1jFz/6rrYJxJnVrL3ZsByGbq3aPMJE5muCgzzl/AZKJC2S0A
 AAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716952234; l=1048;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=IgTEkVYd46Ru6As3hGpXvTy9hURuoQjJ4M75ryPeIBQ=;
 b=NG8/Fqi40DTnl0o5BZrocIxFVchLkBPLoaxBqkwU1c+QmRw1GofHLrZpide+starD0xgZ4tj8
 Zw/S3CC56lyAm7+MtKdIyrDDYx5Z2i6Gxtjne3EEM8NHZ1PdjdFaSsW
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power controller driver support for Amlogic A4 SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- dts: Move power-controller node to be a child of secure-monitor.
- dts: Include power head file.
- Link to v1: https://lore.kernel.org/r/20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: power: add Amlogic A4 power domains
      pmdomain: amlogic: Add support for A4 power domains controller
      arm64: dts: amlogic: a4: add power domain controller node

 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  1 +
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 10 ++++++++
 drivers/pmdomain/amlogic/meson-secure-pwrc.c       | 28 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,a4-pwrc.h        | 21 ++++++++++++++++
 4 files changed, 60 insertions(+)
---
base-commit: 456f4f5e6e6d3a2228501068a37ce13fe0b333d4
change-id: 20240528-a4_secpowerdomain-5eb005648930

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

