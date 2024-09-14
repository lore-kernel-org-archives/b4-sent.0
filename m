From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v2 0/2] Add support for Amlogic C3 PWM
Date: Sat, 14 Sep 2024 13:48:57 +0800
Message-Id: <20240914-c3-pwm-v2-0-ac1f34c68ac2@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMkj5WYC/2XMyw6CMBCF4Vchs3ZMOyJVVr6HYdH0ApMIJa2pG
 tJ3t7J1+Z+cfBskF9kl6JsNosucOCw16NCAmfQyOmRbG0hQK66iQ3PC9TWjlUooOkt1oQ7qeY3
 O83uH7kPtidMzxM/uZvlb/4gsUaA22kvltaVW3fT8CCObowkzDKWUL1JwccueAAAA
To: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-pwm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, Kelvin Zhang <kelvin.zhang@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726293023; l=766;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=BKPsh9AbBCeenJYCPX7oX8WfRJvUle8s6ls3hVpCebU=;
 b=M7zDFQVH4PyRCBGJGwTRhqlW4fQuecrW1wLK8H6y9BcOuYuUtVd5HGbe86zO79gE02SLJlND8
 yNIw6/EESi2DZR9eTrgIF3YzxPLUsPArExC6VknPhKT7ly8i/8w49z9
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for Amlogic C3 PWM, including the DT binding document and DTS.

Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
Changes in v2:
- Rebase this patchset due to recent upstream changes.
- Link to v1: https://lore.kernel.org/r/20240906-c3-pwm-v1-0-acaf17fad247@amlogic.com

---
Kelvin Zhang (2):
      dt-bindings: pwm: amlogic: Document C3 PWM
      arm64: dts: amlogic: Add Amlogic C3 PWM

 .../devicetree/bindings/pwm/pwm-amlogic.yaml       |   1 +
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 364 +++++++++++++++++++++
 2 files changed, 365 insertions(+)
---
base-commit: 5acd9952f95fb4b7da6d09a3be39195a80845eb6
change-id: 20240906-c3-pwm-d17072517826

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

