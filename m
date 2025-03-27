From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/2] Pinctrl: add amlogic a5 pinctrl node
Date: Thu, 27 Mar 2025 17:26:34 +0800
Message-Id: <20250327-a5-pinctrl-v1-0-49320349c463@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMoZ5WcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDY0ML3URT3YLMvOSSohzdNONks2SzxESDVPM0JaCGgqLUtMwKsGHRsbW
 1AJ39vfxcAAAA
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743067595; l=623;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=MBw8/ACFWUtiSMTIE+tw97Aq8o3QGA5ONAcZtl4MtsE=;
 b=2r8IzIYkQPHPdhntWxW+/CTIGjNovPpbnjAweo/oqs2razhgvAfjqxIzYJhjniWECQa0hhn1+
 d8AovbPfI/BCiMloXLY3NdsgKc3BCiIgUxgK+PgkMHoxiEKYL2KDlDr
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add A5 pinctrl compatible string and device node.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (2):
      dt-bindings: pinctl: amlogic,pinctrl-a4: Add compatible string for A5
      dts: arm64: amlogic: add a5 pinctrl node

 .../bindings/pinctrl/amlogic,pinctrl-a4.yaml       |  9 ++-
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        | 90 ++++++++++++++++++++++
 2 files changed, 97 insertions(+), 2 deletions(-)
---
base-commit: 73a143e436311183186ab4b365a84c662f2c9651
change-id: 20250318-a5-pinctrl-f3c6c6aa0e7f

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

