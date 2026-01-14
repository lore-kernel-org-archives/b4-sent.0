From: Ricardo Pardini <ricardo@pardini.net>
Date: Wed, 14 Jan 2026 23:48:36 +0100
Subject: [PATCH 1/2] arm64: dts: amlogic: Enable the npu node on Radxa Zero
 2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-1-8b5cdf328fde@pardini.net>
References: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net>
In-Reply-To: <20260114-arm64-dts-amlogic-radxa-zero2-additions-v1-0-8b5cdf328fde@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=698; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=eqdmMp6peidn3J71/h9AkydpMOUtj1mRqpWe52feB/s=;
 b=owEBbQGS/pANAwAIATteP+Oex+3pAcsmYgBpaB1KmaU5bBjHFVtHlQhR+8JD0BxN6RL1k4sP5
 pT7lMOYuIiJATMEAAEIAB0WIQSsGCMM9q/qytxIiJM7Xj/jnsft6QUCaWgdSgAKCRA7Xj/jnsft
 6T9zB/4sWp2MYpPyk50RQWXJ4TUCNsIX3h+AVX/rZKZ3m2cQtlN5RZLgg9WWc8KuRrxv+SwJxkf
 IefNO+MBh3Kg5nwI7Qjd6cPhIPN19r7zMtpyxpnqA17SSsDvkX+Z2LazVfSnMqq44a5VbrBGLPG
 NODCO/yFwkHSBEXLSeCtFl17WGxFJC7zZDQQrP2JkpeepmeayNSfSiYxhpa9LELUCMBYvV8nLyK
 VCo+gr4BEh5DUXAblkt4ySzT6J5utQXzciKNt4oY071YZ+ga09PPZKgxWaisWAKKIOGH/JGII4n
 GjvFSzc3xNPbcEaVMUomsn5wO19pKLCfEpBFL89p64xrwO5C
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Zero2 is also an A311D just like the VIM3, enable its npu.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
---
 arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
index 1e5c6f9849456..a37776d22b09e 100644
--- a/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-g12b-radxa-zero2.dts
@@ -394,6 +394,10 @@ &pwm_AO_cd {
 	status = "okay";
 };
 
+&npu {
+	status = "okay";
+};
+
 &saradc {
 	status = "okay";
 	vref-supply = <&vddao_1v8>;

-- 
2.52.0

