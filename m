From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Thu, 04 Jun 2026 18:18:39 +0200
Subject: [PATCH v3 03/10] arm64: dts: qcom: sc8280xp-arcata: add USB-C
 orientation GPIOs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260604-surface-sp9-5g-for-next-v3-3-6aa6f6612c10@gmail.com>
References: <20260604-surface-sp9-5g-for-next-v3-0-6aa6f6612c10@gmail.com>
In-Reply-To: <20260604-surface-sp9-5g-for-next-v3-0-6aa6f6612c10@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780589927; l=936;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=G99UBcbrZwtaqeqPJRUSaHBYDMjBAma4TMxJ7Y0s0tA=;
 b=odZyReNdb99FgoeqjyM6fIvUCH6gHpn51nnSK4wb/npORtUWhHaBsdredYAVtZtuUzc6hmoyo
 xgGwfI3EzcVD6jfrnyBx5G3rIpaExZJC/SSGnsJ2EDf4XE4rVwPLPkJ
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define the USB-C orientation GPIOs so that the orientation is known
for the two USB-C ports on the left-side.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
index 476e17415da273330e3638e040db9cd4ed408bf1..c3b143ed11c73b7c1bedc576c10af8db30effc36 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-microsoft-arcata.dts
@@ -60,6 +60,8 @@ pmic-glink {
 
 		#address-cells = <1>;
 		#size-cells = <0>;
+		orientation-gpios = <&tlmm 166 GPIO_ACTIVE_HIGH>,
+				    <&tlmm 49 GPIO_ACTIVE_HIGH>;
 
 		/* Left-side top port */
 		connector@0 {

-- 
2.47.3

