From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sat, 09 Aug 2025 18:18:07 +0200
Subject: [PATCH v2 2/3] ARM: dts: allwinner: orangepi-zero2: Add default
 audio routing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250809-opz-audio-v2-2-f4fd15552a82@posteo.net>
References: <20250809-opz-audio-v2-0-f4fd15552a82@posteo.net>
In-Reply-To: <20250809-opz-audio-v2-0-f4fd15552a82@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754756302; l=1692;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=MNIFx+OhapBMs8FasylcBkObgSQEZMhAy+EBWCVQkAk=;
 b=wHIiYEunlGpmpYxfLe/S8ow0gBeBtJYtg7Np+1pF7G8x0teIiBYaUY11k1CQ+rGiTA3kz1Bk2
 W0koQwJWCQ0CHuiazLSiYbvQzJlyo+hyPbscDKkuOyIVvIS3OCK9on1
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Orange Pi Zero Plus 2 has the same pinout[1] as the Orange Pi
Zero[2] (with the possible exception of line-out left/right being
swapped), and the Orange Pi Zero Interface Board is sold[3] as
compatible with both of them. We can thus use the same audio routing.

[1]: http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-Plus-2.html
[2]: https://linux-sunxi.org/Xunlong_Orange_Pi_Zero#Expansion_Port
[3]: https://orangepi.com/index.php?route=product/product&product_id=871

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

v2:
- new patch
---
 .../boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts    | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts b/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts
index 7a6444a10e2534458b7380882ea4fd42bd54fea8..97a3565ac7a819be6b18d324fa6f65d0d1d2b2ad 100644
--- a/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts
+++ b/arch/arm/boot/dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts
@@ -99,6 +99,20 @@ wifi_pwrseq: pwrseq {
 	};
 };
 
+/*
+ * Audio input/output is exposed on the 13-pin header and can't be used for
+ * anything else. However, adapter boards may use different audio routing.
+ * - http://www.orangepi.org/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-Plus-2.html
+ * - Allwinner H3 Datasheet, section 3.1. Pin Characteristics
+ */
+&codec {
+	allwinner,audio-routing =
+		"Line Out", "LINEOUT",
+		"MIC1", "Mic",
+		"Mic",  "MBIAS";
+	status = "disabled";
+};
+
 &de {
 	status = "okay";
 };

-- 
2.48.0.rc1.219.gb6b6757d772

