From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Subject: [PATCH v6 0/3] Add support for Amlogic A4/A5 Reset
Date: Fri, 11 Apr 2025 19:38:14 +0800
Message-Id: <20250411-a4-a5-reset-v6-0-89963278c686@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACb/+GcC/23OQQqDMBCF4atI1h1JNI5pV71HcZHGiQbUlESkr
 Xj3RqGLQjcD/2I+3soiBUeRXbKVBVpcdH5KgaeMmV5PHYFrU7OCFxUvRQlagq4gUKQZEM9I1V0
 oEpylj0cg656HdmtS2+BHmPtA+mtIfhaK17IQIlccaxDwpsFPXd6mc9Xj4DtncuPH3etdnH14H
 eMWuav/dywSOCQWLSrZorE/ULNt2wfGzFWx6AAAAA==
X-Change-ID: 20250313-a4-a5-reset-6696e5b18e10
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744371498; l=1852;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=/hQwt0vJTBvVhJE+lXTePELN6y6nrRJohz6/U3u5fL4=;
 b=PALP2scUtWnW+Qtp1sVaMJtTsv5qeOy3hkGeox/qrj4xg4vrZcvPaP3qvh042yeZALpns1XvE
 2F219edsTEPBnEK4V2DrF9EU7uu/SLOP/T9PwIdGDJQV0Ck0lMRL9jv
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add dt-binding compatibles and device nodes for Amlogic A4/A5 reset.

Imported from f20240918074211.8067-1-zelong.dong@amlogic.com

Changes in v6:
- Rebased onto the latest v6.16/arm64-dt.
- Link to v5: https://lore.kernel.org/r/20250320-a4-a5-reset-v5-0-296f83bf733d@amlogic.com

Changes in v5:
- Rebasing on top of the latest upstream changes.
- Link to v4: https://lore.kernel.org/r/20250313-a4-a5-reset-v4-0-8076f684d6cf@amlogic.com

Changes in v4:
- Remove the superfluous 'items' in the dt-binding.
- Rebasing due to recent upstream changes.
- Link to v3: https://lore.kernel.org/all/20240918074211.8067-1-zelong.dong@amlogic.com/

Changes in v3:
- rebase on 'amlogic,t7-reset' patchset
- Link to v2: https://lore.kernel.org/all/20240715051217.5286-1-zelong.dong@amlogic.com/

Changes in v2:
- remove 'amlogic,t7-reset'
- move 'amlogic,c3-reset' to the other enum list
- move reset node from amlogic-a4-common.dtsi to
  amlogic-a4.dtsi/amlogic-a5.dtsi
- Link to v1: https://lore.kernel.org/all/20240703061610.37217-1-zelong.dong@amlogic.com/

---
Zelong Dong (3):
      dt-bindings: reset: Add compatible for Amlogic A4/A5 Reset Controller
      arm64: dts: amlogic: Add A4 Reset Controller
      arm64: dts: amlogic: Add A5 Reset Controller

 .../bindings/reset/amlogic,meson-reset.yaml        | 22 +++--
 arch/arm64/boot/dts/amlogic/amlogic-a4-reset.h     | 93 +++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        |  8 ++
 arch/arm64/boot/dts/amlogic/amlogic-a5-reset.h     | 95 ++++++++++++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-a5.dtsi        |  8 ++
 5 files changed, 218 insertions(+), 8 deletions(-)
---
base-commit: 4bc28af2da876531e5183d25ae807e608c816d18
change-id: 20250313-a4-a5-reset-6696e5b18e10

Best regards,
-- 
Kelvin Zhang <kelvin.zhang@amlogic.com>

