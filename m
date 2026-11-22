From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/4] arm64: dts: qcom: qcs8550-retroidpocket: Enable
 displays
Date: Sun, 22 Nov 2026 15:46:15 -0600
Message-Id: <20261122-rp-qcs8550-display-v1-0-d513d9819a34@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqAMAwA0atI1gZMsf6uIi6KjRoQrQ2IIt7d4
 vItZh5QjsIKXfZA5FNU9i2B8gzGxW0zo/hkMIWpiAxhDHiM2lhboBcNq7vR123LhprSOwspDJE
 nuf5pP7zvB+gfyFtkAAAA
X-Change-ID: 20261121-rp-qcs8550-display-d799e2184da5
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795383979; l=788;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=UFvaZtlmbK3x3++gaX4C0nDXh3A1k4gRmCkgGdqnpQQ=;
 b=H4xkYsRP8yGDCMsqsSuE56jB94upcwQstyYQc3y8KFK/Ot/5fRg3f+T9EbyVDTCQkqzwix5i6
 YBo7VibGPlpB6x64qg1yRXULZuytc5+qXY3xt8h9akSXoPMDhcf7rWd
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This first cleans up unused / invalid backlight nodes, then enables the
panel for each device.

---
Aaron Kling (4):
      arm64: dts: qcom: qcs8550-retroidpocket-nova: Remove pwm backlight
      arm64: dts: qcom: qcs8550-retroidpocket-nova: Enable panel
      arm64: dts: qcom: qcs8550-retroidpocket-rp6: Remove pwm backlight
      arm64: dts: qcom: qcs8550-retroidpocket-rp6: Enable panel

 .../boot/dts/qcom/qcs8550-retroidpocket-nova.dts   | 49 ++++++++++++++++-----
 .../boot/dts/qcom/qcs8550-retroidpocket-rp6.dts    | 51 +++++++++++++++++-----
 2 files changed, 76 insertions(+), 24 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261121-rp-qcs8550-display-d799e2184da5

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

