From: Nizat Mikayilli <nacht@dxdmail.cc>
Date: Wed, 04 Nov 2026 20:41:49 +0100
Subject: [PATCH] arm64: dts: qcom: sm8550: Add missing CPU7 3.36GHz OPP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-sm8550-prime-3p36ghz-v1-1-c72630265379@dxdmail.cc>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avIrBsY7cfoKtEibKpZaKIQUXT3p
 OW3eO+BzEk4w6AeSHxKliMU6EqB2+ewMcpSDIZMpzU1mH3ftoQxiWesY91t+43WsmOryTlaoKQ
 x8SrXvx2n9/0A62+GLWYAAAA=
X-Change-ID: 20261104-sm8550-prime-3p36ghz-77ece710cc0d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Aaron Kling <webgeek1234@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793821317; l=1185;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=qRT6IO1l358AuB03TLo/hQmXkRKy7jq10Y/5pck5sP0=;
 b=fd2Az2+Ro8NXmE0zpXmgAs+pC5T86WS/IBSuxIky2uQcQwEPzUZn85dQzT3DIEaqQQZ9X5TRB
 5i6gJL9v80jD1utEPeqkJ9OQN5kH+g1R9hhISmveR0sl47PGfbU0coa
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cpufreq LUT on the Samsung Galaxy Tab S9 Wi-Fi has a 3.36GHz boost
entry for CPU7 without a matching OPP, so the frequency is dropped:

cpu cpu7: Voltage update failed freq=3360000
cpu cpu7: failed to update OPP for freq=3360000

Fixes: 3f5dcc05cd33 ("arm64: dts: qcom: sm8550: add cpu OPP table with DDR, LLCC & L3 bandwidths")
Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
 arch/arm64/boot/dts/qcom/sm8550.dtsi | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sm8550.dtsi b/arch/arm64/boot/dts/qcom/sm8550.dtsi
index 03f6d40edea7..ed6e34ac8d56 100644
--- a/arch/arm64/boot/dts/qcom/sm8550.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8550.dtsi
@@ -752,6 +752,11 @@ opp-3187200000 {
 			opp-hz = /bits/ 64 <3187200000>;
 			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
 		};
+
+		opp-3360000000 {
+			opp-hz = /bits/ 64 <3360000000>;
+			opp-peak-kBps = <(933000 * 16) (3686000 * 4) (1689600 * 32)>;
+		};
 	};
 
 	pmu-a510 {

---
base-commit: f5672a3dff0291d6a45eb0c258b9d2baeb4dc577
change-id: 20261104-sm8550-prime-3p36ghz-77ece710cc0d

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

