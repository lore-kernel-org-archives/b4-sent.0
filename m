From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/2] Add the download mode support for IPQ5018
Date: Mon, 12 May 2025 18:36:45 +0400
Message-Id: <20250512-ipq5018-syscon-v1-0-eb1ad2414c3c@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH0HImgC/x3MQQqAIBBA0avIrBN0UqiuEi3KppqNlQNRSHdPW
 r7F/xmEEpNApzIkulh4jwW2UhC2Ma6keS4GNOiNt6j5OL2xjZZHwh61pdq1ZCZEt0CJjkQL3/+
 wH973A+Wa8HtgAAAA
X-Change-ID: 20250512-ipq5018-syscon-1e349e0b224f
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747060624; l=688;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=FRmP3zLT6FTZhFpt8JSH7YRQTJkpK8mvEacJW0127co=;
 b=7mdpqeObKkJaAt9nkPLr/duLkUQjbUXO55r4rKC7MnLxbjeWHV1sQU4E9i12e1UULN0MHRg0i
 Ht4fIDzdmiIBy3ryICDE+BXcqBh5cdreqpysu2HP3zaJBgXU1l5bAhR
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable support for download mode to collect the RAM dumps in case of
system crashes, to perform post mortem analysis.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (2):
      dt-bindings: mfd: qcom,tcsr: Add compatible for ipq5018
      arm64: dts: qcom: ipq5018: enable the download mode support

 Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml | 1 +
 arch/arm64/boot/dts/qcom/ipq5018.dtsi                | 6 ++++++
 2 files changed, 7 insertions(+)
---
base-commit: edef457004774e598fc4c1b7d1d4f0bcd9d0bb30
change-id: 20250512-ipq5018-syscon-1e349e0b224f

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

