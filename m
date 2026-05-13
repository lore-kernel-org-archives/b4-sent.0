From: Ronald Claveau <linux-kernel-dev@aliel.fr>
Date: Wed, 13 May 2026 12:43:55 +0200
Subject: [PATCH v2 3/3] arm64: dts: amlogic: t7: khadas-vim4: add
 PWM-driven status LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-add-kvim4-sysled-v2-3-3ec9779e8875@aliel.fr>
References: <20260513-add-kvim4-sysled-v2-0-3ec9779e8875@aliel.fr>
In-Reply-To: <20260513-add-kvim4-sysled-v2-0-3ec9779e8875@aliel.fr>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ronald Claveau <linux-kernel-dev@aliel.fr>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1280;
 i=linux-kernel-dev@aliel.fr; h=from:subject:message-id;
 bh=2xdbcwmGmHmxRvinJQMTjDVB63/BF5fZ22AOjpf30NU=;
 b=owGbwMvMwCWm1SvKXP3cUInxtFoSQxZLGAe/2O2a+3P475ob7pLlVj5TH3PE96Vip/GKqam2/
 LtVTP53lLIwiHExyIopsvTPtTzx7vLRM1/3qKfAzGFlAhnCwMUpABOxZWb4H8rz9ZbCD4fdmnPv
 fm6YeX9D6AqvSVOr/7fvWzMjwq193XuG/26NkW8q47RFz+RJuS00FPyzrT+VY/eZGWc3+OzWeFQ
 3lR0A
X-Developer-Key: i=linux-kernel-dev@aliel.fr; a=openpgp;
 fpr=DFD863F61375BF917F0012173953305EF1D0EC3E
X-Endpoint-Received: by B4 Relay for linux-kernel-dev@aliel.fr/default with auth_id=744
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The VIM4 board exposes a status LED wired to the PWM_AO_C_D output.
Enable the pwm_ao_cd controller with its pinmux, and declare a
pwm-leds node with a heartbeat trigger.

Signed-off-by: Ronald Claveau <linux-kernel-dev@aliel.fr>
---
 .../boot/dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts   | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts b/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts
index fd1b983354a01..c41525a34b721 100644
--- a/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts
+++ b/arch/arm64/boot/dts/amlogic/amlogic-t7-a311d2-khadas-vim4.dts
@@ -53,6 +53,16 @@ dc_in: regulator-dc-in {
 		regulator-always-on;
 	};
 
+	pwm-leds {
+		compatible = "pwm-leds";
+
+		status {
+			linux,default-trigger="heartbeat";
+			max-brightness = <255>;
+			pwms = <&pwm_ao_cd 0 30040 0>;
+		};
+	};
+
 	sd_3v3: regulator-sdcard-3v3 {
 		compatible = "regulator-fixed";
 		regulator-name = "SD_3V3";
@@ -163,6 +173,12 @@ &pwm_ab {
 	pinctrl-names = "default";
 };
 
+&pwm_ao_cd {
+	status = "okay";
+	pinctrl-0 = <&pwm_ao_c_d_pins>;
+	pinctrl-names = "default";
+};
+
 /* SDIO */
 &sd_emmc_a {
 	status = "okay";

-- 
2.49.0

