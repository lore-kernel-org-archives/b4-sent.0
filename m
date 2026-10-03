From: Fabricio Akio <fabricioakio@gmail.com>
Date: Sat, 03 Oct 2026 16:45:24 -0300
Subject: [PATCH 4/4] arm64: dts: qcom: pmi8998: Add the charger state
 change interrupt
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261003-qcom-smbx-chg-state-change-v1-4-fffaef446932@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791056720; l=1071;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=7C77VJn5h1hHh/I/VZZaiNv4WEPYvSZpJOqhhjqRqHc=;
 b=0exrXWpGGiWrGFNj6VZv5rb5FFi3oEO9R9FhA38JvxlNknm4uAx73x2StdvgjRHBaFwqQcy2U
 E5Yh9gFzZNMCxsvBiC7f1jgm+L6wIE/O/8hD7zkoPbE4Sa9XwkoY0hB
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the charger's chg-state-change interrupt, as the vendor device
tree does.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 arch/arm64/boot/dts/qcom/pmi8998.dtsi | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/pmi8998.dtsi b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
index cd3f0790fd42..bd07ff137947 100644
--- a/arch/arm64/boot/dts/qcom/pmi8998.dtsi
+++ b/arch/arm64/boot/dts/qcom/pmi8998.dtsi
@@ -16,11 +16,13 @@ pmi8998_charger: charger@1000 {
 			interrupts = <0x2 0x13 0x4 IRQ_TYPE_EDGE_BOTH>,
 				     <0x2 0x12 0x2 IRQ_TYPE_EDGE_BOTH>,
 				     <0x2 0x16 0x1 IRQ_TYPE_EDGE_RISING>,
-				     <0x2 0x13 0x6 IRQ_TYPE_EDGE_RISING>;
+				     <0x2 0x13 0x6 IRQ_TYPE_EDGE_RISING>,
+				     <0x2 0x10 0x1 IRQ_TYPE_EDGE_RISING>;
 			interrupt-names = "usb-plugin",
 					  "bat-ov",
 					  "wdog-bark",
-					  "usbin-icl-change";
+					  "usbin-icl-change",
+					  "chg-state-change";
 
 			io-channels = <&pmi8998_rradc 3>,
 				      <&pmi8998_rradc 4>;

-- 
2.55.0

