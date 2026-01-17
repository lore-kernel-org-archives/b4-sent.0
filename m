From: Eric Neulight <Eric.Neulight@linuxdev.slmail.me>
Date: Fri, 16 Jan 2026 23:02:20 -0500
Subject: [PATCH] Eliminate Odroid HC4 power glitches during boot.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260116-odroid-hc4-dts-v1-1-459b601cd5cf@linuxdev.slmail.me>
X-B4-Tracking: v=1; b=H4sIAMsJa2kC/x3MMQqAMAxA0atIZgNtSUW8ijhIk2qWVloRQby7x
 fEN/z9QpahUmLoHilxaNacG23cQ9jVtgsrN4IwbjLUDZi5ZGfdAyGdFT5GcJx69J2jRUSTq/Q/
 n5X0/vDgxLGAAAAA=
X-Change-ID: 20260116-odroid-hc4-dts-54f4254d8554
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Eric Neulight <Eric.Neulight@linuxdev.slmail.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4323;
 i=Eric.Neulight@linuxdev.slmail.me; h=from:subject:message-id;
 bh=D6GTcwhfX7GFqFVPwCE7THDsRVZibUMqyLB6SBdfMzo=;
 b=owGbwMvMwCX22yMi/F2X5g7G02pJDJnZnB8enpnGXpJYs7jxUr1Do5TgrreOtnuYrpx221HuN
 VXAb/HfjlIWBjEuBlkxRZaPK29Nn6k9Ta3o5frVMHNYmUCGMHBxCsBEMqcy/OHf9XHK1h/+L0r0
 b7JEbVJ8ffiJZs7ChQ5GLzak/j50r3IKw1/hswYaNlEiNcxbN0ibTuCw2i7Zl3JRq9XkRlZihHH
 gCx4A
X-Developer-Key: i=Eric.Neulight@linuxdev.slmail.me; a=openpgp;
 fpr=F1A9DA97992B962672E9AFABFB485857EE8A29B8
X-Endpoint-Received: by B4 Relay for Eric.Neulight@linuxdev.slmail.me/default with auth_id=606
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix issue with Odroid HC4 (and all meson-sm1-odroid) DTS that causes
regulator power to momentarily glitch OFF-ON during boot.  Add
regulator-boot-on to all regulator-fixed and regulator-gpio entries
that (1) define a gpio AND (2) define regulator-always-on.

U-boot powers on devices necessary for boot then hands off the DTB to
the kernel.  During probe, linux drivers/regulator/fixed.c and
gpio-regulator.c both first set the regulator control gpio (that U-boot
already turned ON) to default OFF before then setting it to the defined
(ON) state. This glitches the power to the affected devices, unless
regulator-boot-on is specified with it.  In fact, U-boot has the same
behavior.  So, during reboot, a power glitch can actually happen twice:
once when U-boot reads the DTB and probes the gpio and again when the
kernel reads the DTB and probes the gpio.

Problem this fixes: On the Odroid HC4, power to the SATA ports glitches
during boot and causes some HDDs to do emergency head retract, which
should be avoided.  On the HC4, power glitches to the SD card, USB,
SATA, and HDMI interfaces during boot.  These are all boot devices.
A power glitch can potentially cause a problem for any sensitive devices
during boot.

NOTE: This is not limited to just the HC4, likely an issue with ALL DTS
with regulator-fixed or regulator-gpio entries that (1) define a gpio
AND (2) define regulator-always-on.  All such entries should also
include regulator-boot-on in order to avoid potential power glitches.
At worst, adding regulator-boot-on in such cases is harmless because of
regulator-always-on, and, at best, it eliminates detrimental power
glitches during boot.  So, this is best-practice.

Fixes: 164147f094ec5d0fc2c2098a888f4b50cf3096a7 ("arm64: dts: meson-sm1-odroid-hc4: add regulators controlled by GPIOH_8")
Fixes: 45d736ab17b44257e15e75e0dba364139fdb0983 ("arm64: dts: meson-sm1-odroid: add 5v regulator gpio")
Fixes: 1f80a5cf74a60997b92d2cde772edec093bec4d9 ("arm64: dts: meson-sm1-odroid: add missing enable gpio and supply for tf_io regulator")
Fixes: 88d537bc92ca035e2a9920b0abc750dd62146520 ("arm64: dts: meson: convert meson-sm1-odroid-c4 to dtsi")

Signed-off-by: Eric Neulight <Eric.Neulight@linuxdev.slmail.me>
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 2 ++
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi    | 3 +++
 2 files changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 0170139b8d32f4274ad991b0f3d9a0f6c67969ce..3ece30a0a1fff736c544cf89ed0a8cca0890f128 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -52,6 +52,7 @@ p12v_0: regulator-p12v-0 {
 
 		gpio = <&gpio GPIOH_8 GPIO_OPEN_DRAIN>;
 		enable-active-high;
+		regulator-boot-on;
 		regulator-always-on;
 	};
 
@@ -65,6 +66,7 @@ p12v_1: regulator-p12v-1 {
 
 		gpio = <&gpio GPIOH_8 GPIO_OPEN_DRAIN>;
 		enable-active-high;
+		regulator-boot-on;
 		regulator-always-on;
 	};
 
diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
index c4524eb4f0996dfbccec16ca5b936a5c3b2663a5..0bce4e8d965f2c83e6ba677fef2ede2726de6ed1 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid.dtsi
@@ -37,6 +37,7 @@ tflash_vdd: regulator-tflash-vdd {
 
 		gpio = <&gpio_ao GPIOAO_3 GPIO_OPEN_DRAIN>;
 		enable-active-high;
+		regulator-boot-on;
 		regulator-always-on;
 	};
 
@@ -50,6 +51,7 @@ tf_io: gpio-regulator-tf-io {
 
 		enable-gpios = <&gpio_ao GPIOE_2 GPIO_OPEN_DRAIN>;
 		enable-active-high;
+		regulator-boot-on;
 		regulator-always-on;
 
 		gpios = <&gpio_ao GPIOAO_6 GPIO_OPEN_SOURCE>;
@@ -81,6 +83,7 @@ vcc_5v: regulator-vcc-5v {
 		regulator-name = "5V";
 		regulator-min-microvolt = <5000000>;
 		regulator-max-microvolt = <5000000>;
+		regulator-boot-on;
 		regulator-always-on;
 		vin-supply = <&main_12v>;
 		gpio = <&gpio GPIOH_8 GPIO_OPEN_DRAIN>;

---
base-commit: b71e635feefc852405b14620a7fc58c4c80c0f73
change-id: 20260116-odroid-hc4-dts-54f4254d8554

Best regards,
-- 
Eric Neulight <Eric.Neulight@linuxdev.slmail.me>

