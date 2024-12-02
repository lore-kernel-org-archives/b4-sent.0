From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 02 Dec 2024 14:07:18 +0100
Subject: [PATCH 4/4] arm64: dts: exynos: gs101-oriole: enable Maxim
 max77759 fuel gauge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-b4-gs101_max77759_fg-v1-4-98d2fa7bfe30@uclouvain.be>
References: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
In-Reply-To: <20241202-b4-gs101_max77759_fg-v1-0-98d2fa7bfe30@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733144859; l=1033;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=C6G2HNmCWsR7T7ZeSn//curscN+6Mz2Xd6Jnx+k56sQ=;
 b=fA9D6CBCX7gFNZtMJUgL0dFcwNCYI4mlMT8MAW2SwI7p3XgJFaWYEPyx7u68on+520i20JHid
 sicaCn2SzJGABlQm0g5TkuRvsBAZOKtxj5LMxDQNSbhwKrusQCJaTxs
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the node for the max77759 fuel gauge as a slave of the i2c.

The fuel gauge has been tested and seems to give coherent results.
Manual activation of the charger via i2cset shows that the sign of
the current does indicate charging/discharging status.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/boot/dts/exynos/google/gs101-oriole.dts | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
index 387fb779bd29ea3812331a7951f03b181c5fe659..4c45dd6fd0173889234b7b04d7abb4b382c7706c 100644
--- a/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
+++ b/arch/arm64/boot/dts/exynos/google/gs101-oriole.dts
@@ -90,6 +90,13 @@ eeprom: eeprom@50 {
 &hsi2c_12 {
 	status = "okay";
 	/* TODO: add the devices once drivers exist */
+
+	fuel-gauge@36 {
+		compatible = "maxim,max77759-fg";
+		reg = <0x36>;
+		reg-names = "m5";
+	};
+
 };
 
 &pinctrl_far_alive {

-- 
2.47.1

