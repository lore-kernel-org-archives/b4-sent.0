From: Janne Grunau <j@jannau.net>
Date: Wed, 16 Apr 2025 20:06:18 +0200
Subject: [PATCH] arm64: dts: apple: touchbar: Mark ps_dispdfr_be as
 always-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250416-arm64_dts_apple_touchbar-v1-1-e1c0b53b9125@jannau.net>
X-B4-Tracking: v=1; b=H4sIAJnx/2cC/x3MywqAIBBA0V+JWSdUmD1+JUJMpxroIWNFEP170
 vIs7n0gIBMGaJMHGC8KtG8ReZqAnc02oSAXDUVWlJnMlTC8KqndEbTxfkF97KedB8NClbV1TSU
 dNhXE3DOOdP/rrn/fD/MfiopqAAAA
X-Change-ID: 20250416-arm64_dts_apple_touchbar-658cd974de97
To: Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Nick Chan <towinchenmi@gmail.com>, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2090; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=vW+HnwVsI6HKFCWS8Ni6G5ezcLgPyLTobLTnqE3VCiY=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhvT/H+dWvp50jXemd5qQ38RFF3hTijMsYu7mde2Ydziu+
 KpFdK5BRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIkY+zH8z965537Wq0sasRts
 wlRYNmew7NDQK/Cxvlme92LpL6YWXoY/PILfNx+xaZGRT/UpC81uWrzrNUvCNpd5TLmLLgRUvLj
 MAQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver depends on boot loader initialized state which resets when the
ps_dispdfr_be power-domain is powered off. This happens on suspend or
when the driver is missing during boot.
Mark the domain as always on until the driver can handle this.

Fixes: 7275e795e520 ("arm64: dts: apple: Add touchbar screen nodes")
Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm64/boot/dts/apple/t8103-j293.dts | 10 ++++++++++
 arch/arm64/boot/dts/apple/t8112-j493.dts | 10 ++++++++++
 2 files changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103-j293.dts b/arch/arm64/boot/dts/apple/t8103-j293.dts
index 2dfe7b895b2bc0a913e73141e558fa5124a13b2e..e2d9439397f71a93c28b75a7eea589f4bcb3e374 100644
--- a/arch/arm64/boot/dts/apple/t8103-j293.dts
+++ b/arch/arm64/boot/dts/apple/t8103-j293.dts
@@ -77,6 +77,16 @@ touchbar0: touchbar@0 {
 	};
 };
 
+/*
+ * The driver depends on boot loader initialized state which resets when this
+ * power-domain is powered off. This happens on suspend or when the driver is
+ * missing during boot. Mark the domain as always on until the driver can
+ * handle this.
+ */
+&ps_dispdfr_be {
+	apple,always-on;
+};
+
 &display_dfr {
 	status = "okay";
 };
diff --git a/arch/arm64/boot/dts/apple/t8112-j493.dts b/arch/arm64/boot/dts/apple/t8112-j493.dts
index 3d73f9ee2f46a35a3b23da5b233ef316c7372ef7..be86d34c6696cb47d31696541266e504cee8ce10 100644
--- a/arch/arm64/boot/dts/apple/t8112-j493.dts
+++ b/arch/arm64/boot/dts/apple/t8112-j493.dts
@@ -40,6 +40,16 @@ led-0 {
 	};
 };
 
+/*
+ * The driver depends on boot loader initialized state which resets when this
+ * power-domain is powered off. This happens on suspend or when the driver is
+ * missing during boot. Mark the domain as always on until the driver can
+ * handle this.
+ */
+&ps_dispdfr_be {
+	apple,always-on;
+};
+
 &display_dfr {
 	status = "okay";
 };

---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250416-arm64_dts_apple_touchbar-658cd974de97

Best regards,
-- 
Janne Grunau <j@jannau.net>

