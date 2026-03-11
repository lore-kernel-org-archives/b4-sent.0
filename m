From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/5] arm64: dts: qcom: Support AYN QCS8550 Devices
Date: Wed, 11 Mar 2026 01:46:03 -0500
Message-Id: <20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OO27DMBAFryKwDgHuUruidJXABT/LhIWlmHTkB
 IbvHsZqUqScB8zD3FWTWqSpZbirKntpZVs7wMug4rtf30SX1FmhQTYIk/bfq77E5oiMBo5mCmy
 TIKtufFTJ5ev59no6uMrls59ej1EF30TH7Xwu12XIMouVFNgjEAElgNEli57iOFKkkNI0A2f1N
 2YZjhQ0z5Rd1rRV7YEssIs4B1x2+M+w0I2bc8Cs803PxobMkxhG+DVOj8cPDPGoHA0BAAA=
X-Change-ID: 20260217-ayn-qcs8550-16c07b63de26
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773211585; l=2253;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=rB99ecEotGCkphZ8eWraRpsWMoAZ5MBKddrud5VAW7I=;
 b=NxlmJvOo8WdRXKVhPcg8tIJKmIFRzNKf6kTs/g7eXdiuDaB9xshDw0lJG5TRliqEAa7BwyqRL
 8PfMYTksVFaAWEAA70jZA1zdbmw5+zamS0z8mHkADLEtLpBYm4m1YnK
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This specifically includes:
* Odin 2 Mini
* Odin 2 Portal
* Thor

The original Odin 2 dtso is not currently included as it has not yet
been verified.

The initial port was done by Teguh Sobirin for ROCKNIX and was made
available on the AYN github [0].

Support has been removed for things not yet supported by the upstream
kernel, these will be added later when the related drivers are submitted
and picked up. Such includes:

* All panels
* The Odin 2 Mini backlight and touch
* All rgb leds
* The built-in uart gamepad

This series depends on two other series as described in b4 deps. Namely,
one adding the AYN vendor [1] and one adding bindings for firmware-name
in aw88166 nodes [2]. Both must be merged first for schema checks to
succeed.

[0] https://github.com/AYNTechnologies/linux/commits/sm8550/v6.17.5/
[1] https://lore.kernel.org/all/20260220-ayn-vendor-v1-1-292cbbb682b3@gmail.com/
[2] https://lore.kernel.org/all/20260310-aw88166-fw-v1-1-2777563bb673@gmail.com/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (1):
      dt-bindings: arm: qcom: Add AYN QCS8550 Devices

Teguh Sobirin (4):
      arm64: dts: qcom: Add AYN QCS8550 Common
      arm64: dts: qcom: Add AYN Odin 2 Mini
      arm64: dts: qcom: Add AYN Odin 2 Portal
      arm64: dts: qcom: Add AYN Thor

 Documentation/devicetree/bindings/arm/qcom.yaml    |   10 +
 arch/arm64/boot/dts/qcom/Makefile                  |    7 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-common.dts | 1778 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso    |  147 ++
 .../boot/dts/qcom/qcs8550-ayntec-odin2portal.dtso  |   79 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso  |  223 +++
 6 files changed, 2244 insertions(+)
---
base-commit: fe9e3edb6a215515d1148d32a5c445c5bdd7916f
change-id: 20260217-ayn-qcs8550-16c07b63de26
prerequisite-change-id: 20260220-ayn-vendor-a153168c29b2:v1
prerequisite-patch-id: 042cab8f04748207ba5395dd0f23c445955aaa2b
prerequisite-change-id: 20260310-aw88166-fw-903bf67e0621:v1
prerequisite-patch-id: 07d4bb3f77ef2c2ab22b4c2875761e440156e241
prerequisite-patch-id: 0a9b339adadf6fd550bb9b74c163dc68dd2573d2

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

