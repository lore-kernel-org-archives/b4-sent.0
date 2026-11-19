From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH 0/6] arm64: dts: qcom: sm8550-samsung-gts9wifi: Enable more
 peripherals
Date: Thu, 19 Nov 2026 23:40:03 +0100
Message-Id: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSQqAMAxA0atI1gaMiNNVxIW2qQbESuME4t0tL
 t/i/weUg7BCmzwQ+BQVv0ZQmoCZh3ViFBsNeZaXRNTgWOC0a3OJE3R+Wfx1bIq1saYyZGmoK4j
 tFtjJ/X+7/n0/Fm9C/mcAAAA=
X-Change-ID: 20261119-b4-gts9wifi-followups-8cdc7c1d1a87
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795128013; l=1145;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=l/rOmrHcrx0V4i+2/VhyNsiibsipwyDGfZ6M6/al5/w=;
 b=PZAwGtHU9digB4wAFO4X0dPvGGBnlE/p9BReLL1wtlbN2bC4jTii4Hoon6XOelm6JMQS4x/w8
 1gVvBWJkWtACO/dJi8CakEnBYJn5QjDbkUgbPQxeWpm++spSmHV5/9J
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the CDSP, the vibration motor, the rear flash LED, four board
thermistors, PM8550VS-C and the battery fuel gauge.

Patch 6 needs the fuel gauge binding, which is in power-supply for-next:
https://lore.kernel.org/r/20261108-b4-sm5714-fuel-gauge-v1-0-c659b6c0884a@dxdmail.cc

Tested on the tablet. The LED was only tested as a torch, not as a
flash.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Nizat Mikayilli (6):
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Enable CDSP
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Add GPIO vibrator
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Add rear flash LED
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Add board thermistors
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Enable PM8550VS-C
      arm64: dts: qcom: sm8550-samsung-gts9wifi: Add battery fuel gauge

 .../boot/dts/qcom/sm8550-samsung-gts9wifi.dts      | 145 +++++++++++++++++++++
 1 file changed, 145 insertions(+)
---
base-commit: dde0308a2f8867806a444df1fdd7e685b1c56d5b
change-id: 20261119-b4-gts9wifi-followups-8cdc7c1d1a87

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

