From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] thermal: Support Amlogic C3 thermal
Date: Fri, 18 Jul 2025 14:37:40 +0800
Message-Id: <20250718-c3-thermal-v1-0-674f9a991690@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALTreWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDc0ML3WRj3ZKM1KLcxBzd5LSUNINEo6SkNFMjJaCGgqLUtMwKsGHRsbW
 1AKyiQAxcAAAA
To: Guillaume La Roque <glaroque@baylibre.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pm@vger.kernel.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Liming Xue <liming.xue@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752820661; l=796;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=zVwBnOBXZNVDZp8+mClSq+Wz1HDJCHk36NiLbL59xXk=;
 b=f2ZEHyZc0eY/iGCAhjC75mGOUf1dT5uPNYGLrZJlrqSW9d8wpn88WbDDKbX/o+Nu9e6sLvQQq
 mK90zlJfD/0CV/AGldhcGn9ZEozYGCwKlNAZwk2Ni0u2D/3Q0hccY20
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic C3 thermal compatible string, private_data
of driver and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: thermal: amlogic: Add compatible string for C3
      thermal: amlogic: Support C3 thermal controller driver
      arm64: dts: amlogic: c3: Add tempsensor controller node

 .../devicetree/bindings/thermal/amlogic,thermal.yaml          |  1 +
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi                   | 11 +++++++++++
 drivers/thermal/amlogic_thermal.c                             | 10 ++++++++++
 3 files changed, 22 insertions(+)
---
base-commit: 58abdca0eb653c1a2e755ba9ba406ee475d87636
change-id: 20250718-c3-thermal-cfdf0a2bbf52

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

