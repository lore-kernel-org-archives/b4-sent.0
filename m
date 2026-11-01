From: Joachim Eastwood <joachim.eastwood@gmail.com>
Date: Sun, 01 Nov 2026 22:55:21 +0100
Subject: [PATCH v2 3/9] arm64: dts: rockchip: rk3588s-nanopi: add voltage
 iio-hwmon device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-nanopi-m6-improvements-v2-3-a24769efda23@gmail.com>
References: <20261101-nanopi-m6-improvements-v2-0-a24769efda23@gmail.com>
In-Reply-To: <20261101-nanopi-m6-improvements-v2-0-a24769efda23@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Shawn Lin <Shawn.lin@rock-chips.com>, 
 Diederik de Haas <diederik@cknow-tech.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Joachim Eastwood <joachim.eastwood@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793570136; l=1215;
 i=joachim.eastwood@gmail.com; s=20260701; h=from:subject:message-id;
 bh=i3iFfPZU2WxhmVkZIvHfCb/RWokszUBojNZ0FW7VOk8=;
 b=JAvL53JzX0I1Co7WG0zOaUTjrPTQOUaDG95NzjcESdHDMOwSkxQryZOqgWBmeDx7xOTKh5m5e
 bX6ZfYnqHzZAD8o7okqHFzemxxCmaYRL3PzHRddYkxARSLGIng9PElg
X-Developer-Key: i=joachim.eastwood@gmail.com; a=ed25519;
 pk=ZN/8xWtdYaSd5oEfloYSZ1a+/ri0n0VZqjlEeHlbXFU=
X-Endpoint-Received: by B4 Relay for joachim.eastwood@gmail.com/20260701 with auth_id=846
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The NanoPi 6 series have a resistor divider on the main input supply to
support voltage measurements. Hook this up as a hwmon device so it is
possible to monitor the voltage.

Output from sensors on NanoPi-M6:
vdd_usbc_iio_hwmon-isa-0000
Adapter: ISA adapter
in1:     19.80 V

Signed-off-by: Joachim Eastwood <joachim.eastwood@gmail.com>
---
 arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
index 8c77ee71ebf85..a47677926a59b 100644
--- a/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
+++ b/arch/arm64/boot/dts/rockchip/rk3588s-nanopi.dtsi
@@ -95,6 +95,19 @@ vcc5v0_host_20: regulator-vcc5v0-host-20 {
 		regulator-max-microvolt = <5000000>;
 		vin-supply = <&vcc5v0_sys>;
 	};
+
+	vdiv_vdd_usbc: voltage-divider-vdd-usbc {
+		compatible = "voltage-divider";
+		#io-channel-cells = <1>;
+		io-channels = <&saradc 2>;
+		output-ohms = <10000>;
+		full-ohms = <110000>;
+	};
+
+	vdd-usbc-iio-hwmon {
+		compatible = "iio-hwmon";
+		io-channels = <&vdiv_vdd_usbc 0>;
+	};
 };
 
 &combphy0_ps {

-- 
2.56.0

