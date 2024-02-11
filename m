From: Bjorn Andersson <quic_bjorande@quicinc.com>
Subject: [PATCH 0/2] arm64: dts: qcom: sc8280xp: Make pmic thermal-zones
 report temperature
Date: Sat, 10 Feb 2024 20:41:58 -0800
Message-Id: <20240210-sc8280xp-pmic-thermal-v1-0-a1c215a17d10@quicinc.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABZQyGUC/x3MTQqAIBBA4avErBsYpSy6SrQwG2ugH9GIILp70
 vJbvPdA4iicoCseiHxJkmPPUGUBbrH7zChTNmjSFWlFmFyrW7oDhk0cngvHza7ox9qwMqamhiG
 3IbKX+//2w/t+FUXF02cAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Bjorn Andersson <quic_bjorande@quicinc.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=openpgp-sha256; l=696;
 i=quic_bjorande@quicinc.com; h=from:subject:message-id;
 bh=p8UKy0GQ+pILMVAt3l0Cq9hdX0ZMkXzGj+SrMELt91k=;
 b=owEBgwJ8/ZANAwAIAQsfOT8Nma3FAcsmYgBlyFAXCdaUKkvSlYAd8UArJS3UMUBxKul4YaUtl
 v/e5SGNKu6JAkkEAAEIADMWIQQF3gPMXzXqTwlm1SULHzk/DZmtxQUCZchQFxUcYW5kZXJzc29u
 QGtlcm5lbC5vcmcACgkQCx85Pw2ZrcVzhxAAuFeGH9kv7BHw+9K4B68KMl+qBPdajShULMrA8DL
 ZiRtjUGa5CPBdEXQMBSuDvamE8MwgaR6ErYYPISnHyQw50NXKaJxxjcQIs4s5N92dS+sljPh9ay
 7GetTcoYcHvm7JxhPNrNrXrT+bgjFej5d636q5WXgfpTQg6vb1shdbSF2X1cwKgQECNowbVJmUW
 WPqpkWQrpqWA2kAVygcN/UynSJc60s35v3CZ7HwRVL8GGvEgOruHy3atAc6uH4W5TcHVkQE/szv
 QP7WPHDpIyccZ5QUwB6yIb0wFpXbszWdanlHx6ireEa74cu+797l2WTNbZtJkZ66VFjMSRejAMa
 nJx1HTDw1ppvIxDQwt65K371eYHBlV2r7dnSuMoemH/y1+qcmgm7OklK6fga829F+vOW8uWh+sQ
 dKZ4uzvvBg8ySNLoEOSCWlvew92OZOUo7qE2FnYGwCSc2GlgSz/TlgIkB/YpGpeSzR8tywcQPkK
 EOKJ5eVqrqnq5AiZgtO+QxKIJYwrdBbl4DUxVoBorOSxnCXQtmg7in0fL9wWGPkoBfPwyDhTDMl
 6YGWLcbIvrRO7C2x63qXneL1gEgeah4FGAbwo9RQoFyAXqSwuly5fvp/KrtMNHzBGtWATmW2kZE
 W0gmWSaHp5pXIBBELJwz6Wl7c5ByYRJqlYlQguUi4sY8=
X-Developer-Key: i=quic_bjorande@quicinc.com; a=openpgp;
 fpr=05DE03CC5F35EA4F0966D5250B1F393F0D99ADC5
X-Endpoint-Received: by B4 Relay for quic_bjorande@quicinc.com/default with auth_id=118
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The "pm8280-[12]-thermal" thermal zones always report 37C, fix this.

Signed-off-by: Bjorn Andersson <quic_bjorande@quicinc.com>
---
Bjorn Andersson (2):
      arm64: dts: qcom: sc8280xp-crd: Add PMIC die-temp vadc channels
      arm64: dts: qcom: sc8280xp-pmics: Define adc for temp-alarms

 .../dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts     | 37 +-------------------
 arch/arm64/boot/dts/qcom/sc8280xp-pmics.dtsi       | 39 +++++++++++++++++++++-
 2 files changed, 39 insertions(+), 37 deletions(-)
---
base-commit: 445a555e0623387fa9b94e68e61681717e70200a
change-id: 20240210-sc8280xp-pmic-thermal-fb56e166507e

Best regards,
-- 
Bjorn Andersson <quic_bjorande@quicinc.com>

