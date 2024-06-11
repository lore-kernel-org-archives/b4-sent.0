From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 11 Jun 2024 13:10:59 +0800
Subject: [PATCH 3/3] arm64: dts: amlogic: a4: add pinctrl node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240611-a4_pinctrl-v1-3-dc487b1977b3@amlogic.com>
References: <20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com>
In-Reply-To: <20240611-a4_pinctrl-v1-0-dc487b1977b3@amlogic.com>
To: Linus Walleij <linus.walleij@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Bartosz Golaszewski <brgl@bgdev.pl>
Cc: linux-gpio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718082658; l=1392;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=dK1sBro4y44HxdZ7xq97Zu8WXKXsyY0hjnlhV/Rfko0=;
 b=fPWr6+NYpqH9T8KWCXZZwBxdMkk0QoKEll2gzJAqwC8lX8rYr4earPV3u9ulD3JKWLmCCM0Er
 J/t1A1E3N49DhS0Sn5+Kwlpv/+j4TTt7DWisWrT3bHqlHN9cgK+8iQa
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add pinctrl device to support Amlogic A4.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi | 36 +++++++++++++++++++++++++++++
 1 file changed, 36 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
index de10e7aebf21..5d858bb93eb7 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
+++ b/arch/arm64/boot/dts/amlogic/amlogic-a4.dtsi
@@ -47,4 +47,40 @@ pwrc: power-controller {
 			#power-domain-cells = <1>;
 		};
 	};
+
+	soc {
+		aobus_pinctrl: pinctrl@fe08e700 {
+			compatible = "amlogic,a4-aobus-pinctrl";
+			#address-cells = <2>;
+			#size-cells = <2>;
+			ranges;
+
+			ao_gpio: bank@fe08e700 {
+				reg = <0x0 0xfe08e700 0x0 0x04>,
+				      <0x0 0xfe08e704 0x0 0x60>;
+				reg-names = "mux", "gpio";
+				gpio-controller;
+				#gpio-cells = <2>;
+				gpio-ranges = <&aobus_pinctrl 0 0 8>;
+			};
+		};
+	};
+};
+
+&apb {
+	periphs_pinctrl: pinctrl@4000 {
+		compatible = "amlogic,a4-periphs-pinctrl";
+		#address-cells = <2>;
+		#size-cells = <2>;
+		ranges;
+
+		gpio: bank@4000 {
+			reg = <0x0 0x4000 0x0 0x0050>,
+			      <0x0 0x40c0 0x0 0x0220>;
+			reg-names = "mux", "gpio";
+			gpio-controller;
+			#gpio-cells = <2>;
+			gpio-ranges = <&periphs_pinctrl 0 0 73>;
+		};
+	};
 };

-- 
2.37.1

