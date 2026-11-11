From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 11 Nov 2026 06:00:14 +0000
Subject: [PATCH v2 8/8] arm64: dts: allwinner: orangepi-zero2: Add i2c
 aliases
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-h616-zero2-dt-v2-8-88d8030fc975@gmail.com>
References: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
In-Reply-To: <20261111-h616-zero2-dt-v2-0-88d8030fc975@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Ryan Walklin <ryan@testtoast.com>, 
 Andre Przywara <andre.przywara@arm.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794376807; l=1421;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=Iab2h5Ns40ufO6oTUc6or65fgVwB87DFnCvwebhE2a0=;
 b=MuO6b/d4vcn3cxElE63zppLAfL39s+IfQeufqI3/tff3t+6PLHMGd9ZdP71jf8sy1++Avko8U
 v01poRE8azNB6n9d7zpmfRT3ttBSeyWubuohvePTfbSzwzEPsoHQxnh
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The I2C core numbers adapters after the "i2cN" aliases and hands out
dynamic numbers, in probe order, to adapters without one. The Orange Pi
Zero2 DT has no i2c aliases, so a TWI controller enabled by an overlay
for the header pins gets whatever number is free when it probes: TWI3
on header pins 3 and 5 does not show up as /dev/i2c-3, and the number
changes with the set of enabled buses. The vendor manual and the
vendor BSP name the buses after the controller.

Pin the numbering as the vendor BSP does: i2c0 to i2c4 are TWI0 to
TWI4, i2c5 is R_TWI. Disabled controllers get no adapter, so nothing
changes for buses that stay off.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index d5d39bac5915..98fc83291dc8 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -12,6 +12,15 @@
 / {
 	model = "OrangePi Zero2";
 	compatible = "xunlong,orangepi-zero2", "allwinner,sun50i-h616";
+
+	aliases {
+		i2c0 = &i2c0;
+		i2c1 = &i2c1;
+		i2c2 = &i2c2;
+		i2c3 = &i2c3;
+		i2c4 = &i2c4;
+		i2c5 = &r_i2c;
+	};
 };
 
 &cpu0 {

-- 
2.55.0

