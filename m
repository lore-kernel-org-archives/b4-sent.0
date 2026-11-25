From: Igor Velkov <iav@iav.lv>
Date: Wed, 25 Nov 2026 08:17:43 +0200
Subject: [PATCH] arm64: dts: amlogic: meson-g12b-odroid-n2-plus: enable SD
 UHS modes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-n2plus-sd-uhs-v1-1-cc2019e68da8@iav.lv>
X-B4-Tracking: v=1; b=H4sIAIZ9BmsC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNT3TyjgpzSYt3iFN3SjGJd8zQTUwPzJFNTYzMTJaCegqLUtMwKsHn
 RsbW1AMWaA5xfAAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Valerio Setti <vsetti@baylibre.com>, Dongjin Kim <tobetter@gmail.com>, 
 Christian Hewitt <christianshewitt@gmail.com>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1880; i=iav@iav.lv;
 h=from:subject:message-id; bh=QFes7H4ehieglLItkfgr4kYTQK7rp6WUcLDiwVP/k2s=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNlstR1RXhcXX5uev6Fur7Ks5LLQgykv7evK2TVvv6m45
 VOc1i7XUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACbSGM7IcP1e8CrDSHebFxZ2
 p/o4v3Gu+Ht7ftHltVGLpqaXCfA97mH47/h32bzrcd4bPn/Yc8cw6271txDD+RpJ9n6/2rT/vdh
 7lQMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ODROID-N2+ (board rev 0.5 and later) feeds the SD I/O rail from an
FC8731 LDO that a GPIO switches between 3.3 V and 1.8 V, so the card can
switch to UHS-I signalling. Enable SDR12 to SDR104 and raise
max-frequency to 200 MHz, as meson-sm1-odroid.dtsi already does for the
ODROID-C4/HC4.

Tested on an ODROID-N2+ with a SanDisk 256 GB card and a v7.3-rc6 based
kernel: SDR104 at 200 MHz, reads at 86 MB/s instead of 23 MB/s in
high-speed mode. 20 warm reboots, 10 of them with the BootROM loading
the bootloader from the SD card, and 4 watchdog resets with the card
left in SDR104 at 1.8 V all booted from the SD card again. That is the
case for which commit 663bfe77b6f7 ("arm64: dts: amlogic:
gxbb-odroidc2: remove UHS capability for SD card") dropped UHS on the
ODROID-C2.

The ODROID-N2 (rev 0.4) uses an RT9179 with other divider resistors; by
the schematic its 1.8 V setting is about 1.9 V. This is not tested, so
the ODROID-N2 keeps high-speed.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/amlogic/meson-g12b-odroid-n2-plus.dts | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12b-odroid-n2-plus.dts b/arch/arm64/boot/dts/amlogic/meson-g12b-odroid-n2-plus.dts
index ce1198ad34e4..1f49686f359d 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12b-odroid-n2-plus.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-g12b-odroid-n2-plus.dts
@@ -15,6 +15,14 @@ / {
 	model = "Hardkernel ODROID-N2Plus";
 };
 
+&sd_emmc_b {
+	max-frequency = <200000000>;
+	sd-uhs-sdr12;
+	sd-uhs-sdr25;
+	sd-uhs-sdr50;
+	sd-uhs-sdr104;
+};
+
 &vddcpu_a {
 	regulator-min-microvolt = <680000>;
 	regulator-max-microvolt = <1040000>;

---
base-commit: 36f28822232ae35d36ccd2587e333db1ac961ff7
change-id: 20261125-n2plus-sd-uhs-7f4507b55364

Best regards,
-- 
Igor Velkov <iav@iav.lv>

