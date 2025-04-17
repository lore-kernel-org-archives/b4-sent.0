From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 18 Apr 2025 01:32:49 +0200
Subject: [PATCH] ARM: dts: allwinner: orangepi-zero: Enable audio codec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250418-opz-audio-v1-1-4e86bb5bc734@posteo.net>
X-B4-Tracking: v=1; b=H4sIAKCPAWgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDE0Nz3fyCKt3E0pTMfF0LSwMLE8tki6Qko1QloPqCotS0zAqwWdGxtbU
 AXPuJz1sAAAA=
X-Change-ID: 20250417-opz-audio-890849c8bb2e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744932771; l=1299;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=k/eQQFQjUWyBWBOWbfy/ABZzzwLp3ynUUvGy69783PQ=;
 b=XFDURnfsrz3fEywg3lhFqDKzoRTAi/FcZG9XBdQ96YdDa7CZFBotwe5QPeCWFtnsRKebQD/SK
 u4ZHjkpmgcCB6noff2Vt0VoZe7aulUZBUyOZs83ORW4NTGoV7Puxm/G
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Line out playback and microphone capture work, after enabling the
corresponding ALSA controls. Tested with the Orange Pi Zero interface
board, which is a (mostly) passive adapter from the 13-pin header to
standard connectors (2x USB A, 1x Audio/Video output, 1x built-in
microphone).

  https://orangepi.com/index.php?route=product/product&product_id=871

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts b/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
index 1b001f2ad0efd2e77218742efe6d8edfdd18a816..d65ede3dd6ed1206248a39c91e46065684e7ba29 100644
--- a/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
+++ b/arch/arm/boot/dts/allwinner/sun8i-h2-plus-orangepi-zero.dts
@@ -112,6 +112,14 @@ wifi_pwrseq: pwrseq {
 	};
 };
 
+&codec {
+	allwinner,audio-routing =
+		"Line Out", "LINEOUT",
+		"MIC1", "Mic",
+		"Mic",  "MBIAS";
+	status = "okay";
+};
+
 &cpu0 {
 	cpu-supply = <&reg_vdd_cpux>;
 };

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250417-opz-audio-890849c8bb2e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

