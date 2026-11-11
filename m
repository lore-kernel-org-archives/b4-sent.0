From: Mizuno Miotsuki <founder@crepuse.com>
To: heiko@sntech.de
Cc: conor+dt@kernel.org, devicetree@vger.kernel.org, krzk+dt@kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, robh@kernel.org
Subject: [PATCH v2 RESEND 1/1] arm64: dts: rockchip: Enable I2C2 on
 UNIHIKER M10 V1.2
Date: Wed, 11 Nov 2026 12:14:34 +0000
Message-ID: <179439927406.86676.11920437995901310527.i2c2-v2-resend-1@crepuse.com>
In-Reply-To: <179439927405.86676.18160135777424812496.i2c2-v2-resend-0@crepuse.com>
References: <179439927405.86676.18160135777424812496.i2c2-v2-resend-0@crepuse.com>
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
Content-Type: text/plain; charset="utf-8"
X-Developer-Signature: v=1; a=openpgp-sha256; l=1123; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=ZUtHtXwG3cfnbIn8yg59s0s/+r9OqLaGzwAjtw4eQks=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFlfYrQ0J3SINtxUleIvMLlUMEeUafGP0Brbf5UrTitVT
 L1jcuh5xwQWBjEuBksxRZbZouzlh5pXXJs7ockOZg4rE8gQaZEGBiBgYeDLTcwrNdIx0jPVNtQz
 NNIx0DFm4OIUgKm242X4sZqvb7HRJqZmXcmA3ht7wiIfVmpIq+V+T85f9veLQ/I7hj+cLavPzN7
 KURlzuLPiYqypb5faB12+7vCOAy1XV189sYIdAA==
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mizuno Miotsuki <founder@crepuse.com>

The onboard resistive touchscreen controller is connected to I2C2.
Enable the controller at the tested 400 kHz bus frequency. Its GPIO2_A2
and GPIO2_A3 pinmux is provided by rk3308.dtsi.

Keep the bus enablement separate from the touchscreen device node so
it can be reviewed without depending on the pending NS2009 binding
and driver. The controller-only configuration was booted on M10 V1.2
with no NS2009 device instantiated.

Signed-off-by: Mizuno Miotsuki <founder@crepuse.com>
---
 arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
index 270ea970c95a..0c03f118378a 100644
--- a/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
+++ b/arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts
@@ -131,6 +131,11 @@ &emmc {
 	status = "okay";
 };
 
+&i2c2 {
+	clock-frequency = <400000>;
+	status = "okay";
+};
+
 &io_domains {
 	vccio0-supply = <&vcc_io>;
 	vccio1-supply = <&vcc_io>;
-- 
2.56.0

