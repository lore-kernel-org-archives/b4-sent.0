From: Paul Adam <adamp@posteo.de>
Subject: [PATCH v4 0/3] Add wiko-chuppito devictree
Date: Sat, 07 Mar 2026 18:23:09 +0100
Message-Id: <20260307-wiko-chuppito-v4-0-325ac66ae338@posteo.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAP1erGkC/3XNQQ6CMBCF4auQrq1pO1DAlfcwLloYpDGhTYtVQ
 7i7hY0E4/JN8v0zkYDeYCCnbCIeownGDmnkh4w0vRpuSE2bNhFMSCZ4QZ/mbmnTP5wzo6UKK9X
 lVQ4oS5KM89iZ19q7XNPuTRitf6/5yJfrv1LklNEaUeqqlkwqdnY2jGiPLZKlFMVGC77XImkJI
 DXXXEBV7zV8NbAfDctvDVIJVSpsi62e5/kD4rPwlCYBAAA=
X-Change-ID: 20260215-wiko-chuppito-ae8af4843e67
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, Paul Adam <adamp@posteo.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772904201; l=2195;
 i=adamp@posteo.de; s=20260215; h=from:subject:message-id;
 bh=a9ls+v/+QJk8NhP8s3/9fbDXfdhed/Uibw76bzXyEzc=;
 b=TtCKMDg+AMc3VlGEWCyh8lrT7v0hs4Rzhdxm5mh0c2x6XRBqlppX5Iqdbmot2o/17BX6JAkk8
 UQTund7t2veAHiWH+8UiuPce8p9vojtifO/ghh9iuymQM40949a18TC
X-Developer-Key: i=adamp@posteo.de; a=ed25519;
 pk=mtrPhSn7htywc4S5zrKNrWM6laAdfnaJzIs0BDiCyAs=
X-Endpoint-Received: by B4 Relay for adamp@posteo.de/20260215 with auth_id=640
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings vor Wiko SAS and wiko-chuppito
which are used in the devicetree.

Then introduce an initial device tree for Wiko PULP 4G.
Includes support for:
- UART
- USB (no OTG)
- Internal storage
- MicroSD
- Volume keys + Power button
- Touchscreen
- Backlight
- Accelerometer: Invensense MPU6880
- Magnetometer: Asahi Kasei AK09911
- Hall sensor: Rohm BU52021HFV
- Proximity sensor
- Vibrator
- Earpiece
- Microphone 1
- Headphones
- Wifi
- Bluetooth
- GPU

Signed-off-by: Paul Adam <adamp@posteo.de>
---
Changes in v4:
- remove unused suspend pinctrl states
- remove regulator-always-on for l6
- Link to v3:
https://lore.kernel.org/r/20260301-wiko-chuppito-v3-0-9b36a2a7aed5@posteo.de

Changes in v3:
- add a short description of the device to the patch adding the binding
- removed unused backlight pinctrl state
- readd gpio prefix for some nodes, instead remove it from the labels
- add newline before status properties
- reorder nodes alphabetically
- rename rmi4 node to touchscreen
- Link to v2:
https://lore.kernel.org/r/20260221-wiko-chuppito-v2-0-6336b1b12389@posteo.de

Changes in v2:
- changed company website link to wiko.com (which is just the chinese
version, changing the language redirects to wikomobile.com)
- fix minor dts styling issues
- drop gpio prefix for some nodes
- confirmed stk3310 to be correct
- remove l6: regulator-always-on
- remove gcc node
- Link to v1:
https://lore.kernel.org/r/20260215-wiko-chuppito-v1-0-9ee6b89606a0@posteo.de

---
Paul Adam (3):
      dt-bindings: vendor-prefixes: add WIKO SAS
      dt-bindings: arm: qcom: add wiko,chuppito compatible string
      arm64: dts: qcom: msm8916-wiko-chuppito: add initial devicetree

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 arch/arm64/boot/dts/qcom/msm8916-wiko-chuppito.dts | 315 +++++++++++++++++++++
 4 files changed, 319 insertions(+)
---
base-commit: cee73b1e840c154f64ace682cb477c1ae2e29cc4
change-id: 20260215-wiko-chuppito-ae8af4843e67

Best regards,
-- 
Paul Adam <adamp@posteo.de>

