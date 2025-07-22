From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] thermal: Support Amlogic C3 thermal
Date: Tue, 22 Jul 2025 19:26:26 +0800
Message-Id: <20250722-c3-thermal-v2-0-b2231b4be79e@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGJ1f2gC/23MQQ7CIBCF4as0sxYDaFtx5T1MF5QOZZJSDDRE0
 3B3sWuX/0vet0PCSJjg3uwQMVOisNaQpwaM0+uMjKbaILlseS9uzFzY5jB6vTBjJ8u1HEfbSqi
 HV0RL7wN7DrUdpS3Ez2Fn8Vv/Mlkwzrr+apVWSnSKP7RfwkzmbIKHoZTyBQq+Fg6mAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753183587; l=986;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=eHgEpwKuiJOxUGx+eQ4DDMrajmv56QJt7Ld7EdpIPc0=;
 b=LsAHDWE+cbFu9I6z5V+jNYNswC/DXYMymJ1Bs7O0kSRFhjliia+LLAEk1K/fy/MTeAsRAV8NO
 SbxVezFceXeDGYxfgV9HAbdUFhoftmYo1rrTRQ/XBqJ7ZZ5yYwIsKSW
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic C3 thermal compatible string, private_data
of driver and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Modify the binding file according to Rob's suggestion.
- Link to v1: https://lore.kernel.org/r/20250718-c3-thermal-v1-0-674f9a991690@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: thermal: amlogic: Add compatible string for C3
      thermal: amlogic: Support C3 thermal controller driver
      arm64: dts: amlogic: c3: Add tempsensor controller node

 .../devicetree/bindings/thermal/amlogic,thermal.yaml          |  4 +++-
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi                   | 11 +++++++++++
 drivers/thermal/amlogic_thermal.c                             | 10 ++++++++++
 3 files changed, 24 insertions(+), 1 deletion(-)
---
base-commit: 58abdca0eb653c1a2e755ba9ba406ee475d87636
change-id: 20250718-c3-thermal-cfdf0a2bbf52

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

