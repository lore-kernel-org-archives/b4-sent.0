From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 03 Oct 2026 16:45:23 -0300
Subject: [PATCH 3/4] arm64: dts: qcom: pm660: Add the charger state change
 interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-qcom-smbx-chg-state-change-v1-3-fffaef446932@gmail.com>
References: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
In-Reply-To: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791056720; l=1108;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=fPok6iXSi+v6rT0DKKTD36U7EXn5qf9X9GpJo6/gwRU=;
 b=+eylQCsYjVqiQGl2wnWDuJwVDidnVbXqOw/1gBDHEaioEjV92Uhc0C66RtWqbmpoFNW66oIyU
 GBO0Kc3xk/mA9fkDXQQnz6pD1crX8DYEwHrcHJQ2oF2kPF1615+OauM
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the charger's chg-state-change interrupt, as the vendor device
tree does.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 arch/arm64/boot/dts/qcom/pm660.dtsi | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/pm660.dtsi b/arch/arm64/boot/dts/qcom/pm660.dtsi
index 156b2ddff0dc..9e84f16f4b06 100644
--- a/arch/arm64/boot/dts/qcom/pm660.dtsi
+++ b/arch/arm64/boot/dts/qcom/pm660.dtsi
@@ -80,8 +80,13 @@ pm660_charger: charger@1000 {
 			interrupts = <0x0 0x13 0x4 IRQ_TYPE_EDGE_BOTH>,
 				     <0x0 0x12 0x2 IRQ_TYPE_EDGE_BOTH>,
 				     <0x0 0x16 0x1 IRQ_TYPE_EDGE_RISING>,
-				     <0x0 0x13 0x6 IRQ_TYPE_EDGE_RISING>;
-			interrupt-names = "usb-plugin", "bat-ov", "wdog-bark", "usbin-icl-change";
+				     <0x0 0x13 0x6 IRQ_TYPE_EDGE_RISING>,
+				     <0x0 0x10 0x1 IRQ_TYPE_EDGE_RISING>;
+			interrupt-names = "usb-plugin",
+					  "bat-ov",
+					  "wdog-bark",
+					  "usbin-icl-change",
+					  "chg-state-change";
 
 			io-channels = <&pm660_rradc 3>,
 				      <&pm660_rradc 4>;

-- 
2.55.0

