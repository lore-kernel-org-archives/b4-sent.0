From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 28 May 2024 16:39:30 +0800
Subject: [PATCH 3/3] arm64: dts: amlogic: a4: add power domain controller
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240528-a4_secpowerdomain-v1-3-2a9d7df9b128@amlogic.com>
References: <20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com>
In-Reply-To: <20240528-a4_secpowerdomain-v1-0-2a9d7df9b128@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716885570; l=1210;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=nbykAnIJ2GCD2WnAPtjMU24T/l4oTV2riXHYjP6paJ4=;
 b=FdbPTyKbc+thp9uswV6KRGymTZOcdUZfBsO4rleZ34pKhtz7H21eiq5madq8Vko4zKXFmJmT7
 LDb0D2hwFMVC1K2zczPowHbHIIkPqRNAI1G/s0o4LEHtMW0ptT2gc5N
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power domain controller node for Amlogic A4 SoC

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi | 4 ++++
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi        | 5 +++++
 2 files changed, 9 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
index b6106ad4a072..eebde77ae5b4 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi
@@ -27,6 +27,10 @@ xtal: xtal-clk {
 		#clock-cells = <0>;
 	};
 
+	sm: secure-monitor {
+		compatible = "amlogic,meson-gxbb-sm";
+	};
+
 	soc {
 		compatible = "simple-bus";
 		#address-cells = <2>;
diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index 73ca1d7eed81..917c05219b9c 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -37,4 +37,9 @@ cpu3: cpu@3 {
 			enable-method = "psci";
 		};
 	};
+
+	pwrc: power-controller {
+		compatible = "amlogic,a4-pwrc";
+		#power-domain-cells = <1>;
+	};
 };

-- 
2.37.1

