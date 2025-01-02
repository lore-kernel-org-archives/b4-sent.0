From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Thu, 02 Jan 2025 12:15:05 +0100
Subject: [PATCH v2 3/4] arm64: defconfig: enable Maxim max1720x driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250102-b4-gs101_max77759_fg-v2-3-87959abeb7ff@uclouvain.be>
References: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
In-Reply-To: <20250102-b4-gs101_max77759_fg-v2-0-87959abeb7ff@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735816515; l=716;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=4mcHoKDe8g9Cb02OHRiFohYMU9w9oiqZT1kzkWCs778=;
 b=u0MDFhtyvDcPVMHQuoWVOLHGPzXV3ocxbaOLiaQom2uPtJRuCPR0HfSqrffKvygn/k6OgR/84
 UQ452q5sO5HDwZZZ+qihb1/5ZRmhVbSBhf9AHV5ljOjW1yQ/N3jmcky
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Maxim max1720x as it is used by the gs101-oriole
(Google Pixel 6) board.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index d13218d0c30f458d9c555ab9771a1fd9139ce1aa..7161387d1ebfea0d363e9413ef4350d83b581d96 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -676,6 +676,7 @@ CONFIG_BATTERY_QCOM_BATTMGR=m
 CONFIG_BATTERY_SBS=m
 CONFIG_BATTERY_BQ27XXX=y
 CONFIG_BATTERY_MAX17042=m
+CONFIG_BATTERY_MAX1720X=m
 CONFIG_CHARGER_MT6360=m
 CONFIG_CHARGER_BQ25890=m
 CONFIG_CHARGER_BQ25980=m

-- 
2.47.1

