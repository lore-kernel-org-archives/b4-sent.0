From: Aaron Kling <webgeek1234@gmail.com>
Date: Tue, 13 May 2025 16:10:54 -0500
Subject: [PATCH] arm64: tegra: Remove otg id gpio from Jetson TX2 NX
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250513-tx2nx-role-switch-v1-1-d92ea1870ea5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF21I2gC/x3MTQqAIBBA4avErBtIZejnKtEibMqBsNAoQbp70
 vJbvJchchCOMFQZAt8S5fAFqq7AutlvjLIUg240NaQMXkn7hOHYGeMjl3VoWrZEiybV9VC6M/A
 q6X+O0/t+Swr4fWMAAAA=
X-Change-ID: 20250513-tx2nx-role-switch-37ec55d25189
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747170654; l=1050;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=dPLaQNFWwpMQQvgTs6w9ooCG/dAXAgLZi0Ofjn262Is=;
 b=nDqThMqWh8NwGliNuD0oqFzkcSF2nbocrM9K5SlN7Za/ys1VrdmEVOpaQD1t0XPMre3iuf/n7
 Id7O4ix5Wg6CTAqdF5KnF7hEvlZYCO0CbeyKrteqKhRP4oqu0G4ECJh
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The p3509 carrier board does not connect the id gpio. Prior to this, the
gpio role switch driver could not detect the mode of the otg port.

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts b/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
index 26f71651933d1d8ef32bbd1645cac1820bd2e104..81f204e456409df355bbcb691ef99b0d0c9d504e 100644
--- a/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
+++ b/arch/arm64/boot/dts/nvidia/tegra186-p3509-0000+p3636-0001.dts
@@ -669,7 +669,6 @@ connector {
 					vbus-gpios = <&gpio
 						      TEGRA186_MAIN_GPIO(L, 4)
 						      GPIO_ACTIVE_LOW>;
-					id-gpios = <&pmic 0 GPIO_ACTIVE_HIGH>;
 				};
 			};
 

---
base-commit: 405e6c37c89ef0df2bfc7a988820a3df22dacb1b
change-id: 20250513-tx2nx-role-switch-37ec55d25189

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

