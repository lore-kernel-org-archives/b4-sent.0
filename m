From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/5] arm64: dts: qcom: Support AYN QCS8550 Devices
Date: Wed, 11 Mar 2026 12:44:36 -0500
Message-Id: <20260311-ayn-qcs8550-v2-0-e66986e0f0cb@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WPzW6DMBCEXwXtua68C9jAqe9R5eCfdWKpQGJT1
 Cji3es4l/Y4I83MNw/InCJnmJoHJN5jjutSBL014C5mObOIvmggSUoSamHui7i5PPS9FKic1Fa
 1nklBSVwTh/hT2z5PL5349l1Kt5cJ1mQWbp3nuE1NGKUxPqBT2g22G9XokXtWvgteE2njreLOa
 /gLU9gqCsmKsvPi1yQM9i2qwdFoadoRnuuXmLc13eu1Yj3na7RF/PdiRyFF4MFSKDjI5uM8m/j
 1XjDhdBzHL56r29gkAQAA
X-Change-ID: 20260217-ayn-qcs8550-16c07b63de26
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773251087; l=2199;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=DHrlRUrGIAsGAgBu1A4lPkHX7PV0jeBMaHF4PfPMRP8=;
 b=cE91nB4s1qND9l9JvQ+bXa4SZqjDNCqWkN7H5CqHMAwaxWYhzWxGrRhx9dI3xba66K/jZcb7X
 KsFqFfSIj9nC+3gCeMHBHfUmcP6wgIuD8Fd5P4hzL2/8n/2c2mS7TsB
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

This series depends on one other series as described in b4 deps. Namely,
the one adding the AYN vendor [1]. This must be merged first for schema
checks to succeed.

[0] https://github.com/AYNTechnologies/linux/commits/sm8550/v6.17.5/
[1] https://lore.kernel.org/all/20260220-ayn-vendor-v1-1-292cbbb682b3@gmail.com/

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Drop awinic bindings dep as a duplicated patch already exists
- Change Co-authored-by tags to Co-developed-by
- Drop alias to currently unused uart15 in patch 2
- Link to v1: https://lore.kernel.org/r/20260311-ayn-qcs8550-v1-0-fe8b2faad1ea@gmail.com

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
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-common.dts | 1777 ++++++++++++++++++++
 .../boot/dts/qcom/qcs8550-ayntec-odin2mini.dtso    |  147 ++
 .../boot/dts/qcom/qcs8550-ayntec-odin2portal.dtso  |   79 +
 arch/arm64/boot/dts/qcom/qcs8550-ayntec-thor.dtso  |  223 +++
 6 files changed, 2243 insertions(+)
---
base-commit: f90aadf1c67c8b4969d1e5e6d4fd7227adb6e4d7
change-id: 20260217-ayn-qcs8550-16c07b63de26
prerequisite-change-id: 20260220-ayn-vendor-a153168c29b2:v1
prerequisite-patch-id: 042cab8f04748207ba5395dd0f23c445955aaa2b

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

