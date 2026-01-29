From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/3] arm64: dts: qcom: sm8550: Fix DTBO boot failure
Date: Thu, 29 Jan 2026 01:46:29 -0600
Message-Id: <20260129-sm8550-abl-dtbo-v1-0-abca3be14024@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQyML3eJcC1NTA93EpBzdlJKkfF1LMyMLCzNjkzQDgxQloK6CotS0zAq
 widGxtbUAhh2jlmEAAAA=
X-Change-ID: 20260128-sm8550-abl-dtbo-96288634f00d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Kumar Sharma <quic_vksharma@quicinc.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>, 
 Kuldeep Singh <quic_kuldsing@quicinc.com>, 
 Lei Chen <quic_chenlei@quicinc.com>, 
 Pavan Kondeti <pavan.kondeti@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769672821; l=1080;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=QCEkSPxVReljpWVHzeTwyyJ/ekN3C9+uC4x+BSUR/9s=;
 b=KdzPsRU0OdcLrvu4utlDS5UjyAisqfNnJHbsM10Y7LMe4aaxbh/foFYb3QgMNDQFMEQG5+bLP
 CftXj5WlQj1Bcors8XCQ7NoLX30wup2gZZ9qCuj/M96sTLUbk3eDVye
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With a current mainline sm8550 base dtb, ABL will fail to apply any dtbo
and fail back to the bootloader menu. There are three changes needed:

* Add the tz-log node and a label named qcom_tzlog
* Rename the scm node to qcom_scm
* Add a label named arch_timer to the timer node

The tz-log binding doc and node are sourced from CLO commits. The other
changes are sourced from a lkml message and attributed to the author of
the message.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Kuldeep Singh (1):
      dt-bindings: firmware: Add tz-log doc

Lei Chen (1):
      arm64: dts: qcom: sm8550: Add tz-log node

Pavan Kondeti (1):
      arm64: dts: qcom: sm8550: Fix DTBO boot failure

 .../devicetree/bindings/firmware/qcom,tz-log.yaml  | 66 ++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8550.dtsi               | 12 +++-
 2 files changed, 76 insertions(+), 2 deletions(-)
---
base-commit: 3f24e4edcd1b8981c6b448ea2680726dedd87279
change-id: 20260128-sm8550-abl-dtbo-96288634f00d

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

