From: Alexandre Messier <alex@me.ssier.org>
Date: Tue, 07 Oct 2025 01:55:44 -0400
Subject: [PATCH 3/4] ARM: dts: qcom: msm8974pro-htc-m8: add Bluetooth pins
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251007-m8-dts-additions-v1-3-53d7ab3594e7@me.ssier.org>
References: <20251007-m8-dts-additions-v1-0-53d7ab3594e7@me.ssier.org>
In-Reply-To: <20251007-m8-dts-additions-v1-0-53d7ab3594e7@me.ssier.org>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@lucaweiss.eu>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759816548; l=1058;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=0cC08gikvTy5BFUHETIstK9cv6Jxb/k0e5mDBRsGtzY=;
 b=5VQisWZuZSSDwAomDfZ0ayVYlEE0twKfTIhmKAuwlu0bDHKQXqPsQwv86sihrcKEsRr3BzdIt
 a9/jEQH50c2AbD0BUjmuzpYxxhOaIOxhQwH2IWswkQBZ4PJKEyk/pT0
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required pin configuration to enable Bluetooth.

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 17 +++++++++++++----
 1 file changed, 13 insertions(+), 4 deletions(-)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
index 4026d6fedfbe..36eb42f0f3d9 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts
@@ -359,10 +359,19 @@ cmd-data-pins {
 	};
 
 	wcnss_pin_a: wcnss-pin-active-state {
-		pins = "gpio36", "gpio37", "gpio38", "gpio39", "gpio40";
-		function = "wlan";
-		drive-strength = <6>;
-		bias-pull-down;
+		bt-pins {
+			pins = "gpio35", "gpio43", "gpio44";
+			function = "bt";
+			drive-strength = <2>;
+			bias-pull-down;
+		};
+
+		wlan-pins {
+			pins = "gpio36", "gpio37", "gpio38", "gpio39", "gpio40";
+			function = "wlan";
+			drive-strength = <6>;
+			bias-pull-down;
+		};
 	};
 };
 

-- 
2.51.0

