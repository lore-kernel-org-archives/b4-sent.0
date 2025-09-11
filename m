From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 11 Sep 2025 22:23:55 +0200
Subject: [PATCH v3 1/3] ARM: dts: allwinner: orangepi-zero: Add default
 audio routing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250911-opz-audio-v3-1-9dfd317a8163@posteo.net>
References: <20250911-opz-audio-v3-0-9dfd317a8163@posteo.net>
In-Reply-To: <20250911-opz-audio-v3-0-9dfd317a8163@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757622235; l=1327;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=jlkkNRSXPvyKb7VkFE4rQa+2nclFteLVP/Fzwz7oW+A=;
 b=Z8C6IY54/f4oSOkqb/qp4iZvO2BDFKeNxw7f4oP0smdBBrUsLMOPexmO5cGlajmBQS//udCD7
 tabOi9+px2mBlP+zxypShC9lYgL2dP2II4X9n+YQnNYEq9z4d9CohaH
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Line out playback and microphone capture work, after enabling the
corresponding ALSA controls. Tested with the Orange Pi Zero interface
board.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
v3:
- no change

v2:
- Add an explanatory comment
---
 .../arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts b/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
index 1b001f2ad0efd2e77218742efe6d8edfdd18a816..b23cec5b89ebf61701e1d917929589eb6e884afd 100644
--- a/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
+++ b/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
@@ -112,6 +112,20 @@ wifi_pwrseq: pwrseq {
 	};
 };
 
+/*
+ * Audio input/output is exposed on the 13-pin header and can't be used for
+ * anything else. However, adapter boards may use different audio routing.
+ * - https://linux-sunxi.org/Xunlong_Orange_Pi_Zero#Expansion_Port
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
 &cpu0 {
 	cpu-supply = <&reg_vdd_cpux>;
 };

-- 
2.48.0.rc1.219.gb6b6757d772

