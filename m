From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Thu, 19 Nov 2026 23:40:08 +0100
Subject: [PATCH 5/6] arm64: dts: qcom: sm8550-samsung-gts9wifi: Enable
 PM8550VS-C
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-gts9wifi-followups-v1-5-2e2388589a62@dxdmail.cc>
References: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
In-Reply-To: <20261119-b4-gts9wifi-followups-v1-0-2e2388589a62@dxdmail.cc>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795128013; l=687;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=euutEXnvvtMe/+gu763/D4wM9tSHPXBePYkghrhgKWA=;
 b=iqF0RUUWMRzsVz0FHsGRx+CEJ+Z0fN32987dHWQBjv1wEquvza99qmUNlb0LuPtAowCpxS7mp
 Y5JlmH6m8oLCN5HAV9omlX32uUrTMzttsHNw1+aozfbD9kDxKteHTEy
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The board has a fourth PM8550VS, at SID 2. Enable it like the other
three.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
index 4dc0b7e29db3..8323eb837710 100644
--- a/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
+++ b/arch/arm64/boot/dts/qcom/sm8550-samsung-gts9wifi.dts
@@ -724,6 +724,10 @@ volume_up_n: volume-up-n-state {
 	};
 };
 
+&pm8550vs_c {
+	status = "okay";
+};
+
 &pm8550vs_d {
 	status = "okay";
 };

-- 
2.56.1

