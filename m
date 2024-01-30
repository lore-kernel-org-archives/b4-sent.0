From: Rudraksha Gupta <guptarud@gmail.com>
Subject: [PATCH 0/2] Add the mXT224S touchscreen to expressatt
Date: Mon, 29 Jan 2024 18:43:05 -0800
Message-Id: <20240129-expressatt_mxt224s_touchscreen-v1-0-fb8552e1c32c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADliuGUC/x2NQQrDIBAAvxL2HEEXSWm+UkoIm7XuoSa4JgiSv
 1d6HBhmGihnYYV5aJD5EpU9dXDjABTX9GEjW2dAi946fBquR2bVtZTlWwui16XsJ0WlzJxMcMF
 vZN00PQh6pMtB6n/wet/3D217oCpwAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706582586; l=938;
 i=guptarud@gmail.com; s=20240120; h=from:subject:message-id;
 bh=Ec2wu2Eb+SbRpFarJY9POIEuVo7aDUTNt5tJXUsZudo=;
 b=x1r1rsoZWsL3KI6uJy16fmS0CZWmNxiKmzz2HPlKieu65pTlQb9+cyzS2NmNtVxiAXy+kqdDz
 HKBa2Kb1p4uAD5N7fg1Wkt5y1CiUSwIjdM71ghR3F1U00As2tAsn65t
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=RGmug3GRHS4XYTXDcT2VrlTGXlEF2gY4L9/swGIU1ko=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240120 with auth_id=114
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adds support for the Atmel touchscreen to the Samsung Galaxy Express 
SGH-I437. Copies the gsbi3 node from apq8064, which is a similar SoC,
and sets appropriate properties.

Applies successfully on top of my previous patch:
https://lkml.org/lkml/2024/1/20/56

Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
Rudraksha Gupta (2):
      ARM: dts: qcom: msm8960: Add gsbi3 node
      ARM: dts: qcom: msm8960: expressatt: Add mXT224S touchscreen

 arch/arm/boot/dts/qcom/qcom-msm8960-pins.dtsi      | 29 ++++++++++++++++++++
 .../dts/qcom/qcom-msm8960-samsung-expressatt.dts   | 31 +++++++++++++++++++++-
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           | 27 +++++++++++++++++++
 3 files changed, 86 insertions(+), 1 deletion(-)
---
base-commit: df2fa93a6956fcd03da4c251150aa9cc3c88c74d
change-id: 20240129-expressatt_mxt224s_touchscreen-f1f4dc01667c

Best regards,
-- 
Rudraksha Gupta <guptarud@gmail.com>

