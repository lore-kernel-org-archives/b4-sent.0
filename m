From: Ricardo Pardini <ricardo@pardini.net>
Date: Thu, 15 Jan 2026 18:52:46 +0100
Subject: [PATCH v2] arm64: dts: amlogic: add the type-c controller on Radxa
 Zero 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260115-arm64-dts-amlogic-radxa-zero2-additions-v2-1-948bb0479a45@pardini.net>
X-B4-Tracking: v=1; b=H4sIAG0paWkC/5WNSw6DIBQAr9Kw7msAP9Gueo/GBfoe+pIKBoixN
 d691Bt0ObOY2UWkwBTF/bKLQCtH9i6Dvl7EMBk3EjBmFlrqWipVgglzXQKmCGZ++ZEHCAY3Ax8
 KXoNB5JQTEVpZVWVre8KCRK4tgSxv5+nZZZ44Jh/e53hVP/v/Y1UgoemrAW2hG4v0WExAdnxzl
 ER3HMcX81QDj+AAAAA=
X-Change-ID: 20260114-arm64-dts-amlogic-radxa-zero2-additions-905549fbed3e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3379; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=o6AdblgGh5ZdlDwrmpT3OM+dmaO8Ys6WxijQzUk1YWc=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpaSlypZjIsZFbEWdFKZ7C9I9qk7XcIl/qzQUBa
 S+t3dWpDrOJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaWkpcgAKCRA7Xj/jnsft
 6ZGUCACHpy7luG8T/fuQ+ektuogyYcMdc9EJcgK8F2Yw6FKSqqUEOADHTiEY0VBQhhl5FXdmqEt
 ME1F0D1GKoQ/XfjtKNGwSZi9t2pstp4LkLIiLEcjBWjRFAkUcjN17AYOVuZr69Wnjj9M4bdKjT5
 rrkbFhXbzjIws3ayW2eZYVZxqSTRelFe3qdYDA4UBfbEn1w0XfRtG1WVKqmS81YzA4kPHvlTw6S
 gJfRZjREETuGIRtZXmPoQK7qsyEy4ZEK6UJOeCFdApVUyJ2DrLAdfBit08qghdDpGKLVf9aPr+t
 lIqJivTfrQGUU/klUmFoW820L0AWnNuNzE9MSzs0cBUeSgid
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Radxa Zero2 has an FUSB302 controller on i2c3 at address 0x22 and
INT# wired to GPIOA-13; include a minimal connector.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
This series adds a few things missing from the Radxa Zero 2:

1) NPU (etnaviv), just enable the node, similar to what was done for VIM3
   (dropped as was already picked up in [1])
2) i2c3 (also exposed on the 40-pin header) and the FUSB302 at 0x22.
   Describes it minimally, adding no functionality, but reserving the 0x22
   address since i2c3 is also exposed on user-accessible 40-pin header.

Krzysztof: v1 followed the node name I had found used in amlogic; I've
           looked around more broadly and found 'fusb0: typec-portc@22'
           to be quite popular, so went with this. Hope it is acceptable.

Neil: I've fixed the interrupts pin, and described the required connector
      even more minimally than you suggested, as to avoid including pd.h.
      It is also done this way in a few other boards, hope it's correct.
      I've rebased your/Christian's full-enablement patches on top of this,
      tested with an r8152 which then works both ways, it's available at [2]

[1] https://git.kernel.org/amlogic/c/29deec49146162d06b17739c627d062191e03814
[2] https://github.com/rpardini/linux/tree/radxa-zero2-fusb302-minimal-plus-full-impl-rebase
---
Changes in v2:
- npu: dropped NPU enablement patch as it was already picked up by Neil
- fusb302: dropped 'status = "okay"'
- fusb302: declare as 'fusb0: typec-portc@22' instead of 'fusb302@22'
- fusb302: use correct pin (74 -> gpioA13) for interrupts
- fusb302: add a (very minimal) connector so dtbs_check passes
- Link to v1: https://lore.kernel.org/r/20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net
---
 .../boot/dts/amlogic/meson-g12b-radxa-zero2.dts    | 34 ++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
index 1e5c6f9849456..5d32c04de938e 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
@@ -364,12 +364,46 @@ hdmi_tx_tmds_out: endpoint {
 	};
 };
 
+/* Also exposed on the 40-pin header: SDA pin 3, SCL pin 5 */
+&i2c3 {
+	pinctrl-0 = <&i2c3_sda_a_pins>, <&i2c3_sck_a_pins>;
+	pinctrl-names = "default";
+	status = "okay";
+
+	fusb0: typec-portc@22 {
+		compatible = "fcs,fusb302";
+		reg = <0x22>;
+
+		pinctrl-0 = <&fusb302_irq_pins>;
+		pinctrl-names = "default";
+		interrupt-parent = <&gpio_intc>;
+		interrupts = <74 IRQ_TYPE_LEVEL_LOW>;
+
+		vbus-supply = <&ao_5v>;
+
+		connector {
+			compatible = "usb-c-connector";
+		};
+	};
+};
+
 &ir {
 	status = "disabled";
 	pinctrl-0 = <&remote_input_ao_pins>;
 	pinctrl-names = "default";
 };
 
+&periphs_pinctrl {
+	fusb302_irq_pins: fusb302-irq {
+		mux {
+			groups = "GPIOA_13";
+			function = "gpio_periphs";
+			bias-pull-up;
+			output-disable;
+		};
+	};
+};
+
 &pwm_ab {
 	pinctrl-0 = <&pwm_a_e_pins>;
 	pinctrl-names = "default";

---
base-commit: 0f61b1860cc3f52aef9036d7235ed1f017632193
change-id: 20260114-arm64-dts-amlogic-radxa-zero2-additions-905549fbed3e

Best regards,
-- 
Ricardo Pardini <ricardo@pardini.net>

