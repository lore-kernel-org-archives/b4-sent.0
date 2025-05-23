From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Fri, 23 May 2025 14:51:47 +0200
Subject: [PATCH v4 4/5] arm64: defconfig: enable Maxim max1720x driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250523-b4-gs101_max77759_fg-v4-4-b49904e35a34@uclouvain.be>
References: <20250523-b4-gs101_max77759_fg-v4-0-b49904e35a34@uclouvain.be>
In-Reply-To: <20250523-b4-gs101_max77759_fg-v4-0-b49904e35a34@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748004727; l=716;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=yx0SuiaIbKa84b0oToxMe11+jBYaoqB6+UxBMxg24/I=;
 b=+HwIBAXAC8BjutDhA/xCZ5g4yO5J7kIk9EGyWOsMV/nIFWSshktuIfocSezpS24C1WhKv6M4N
 9TTFwiM+o1GBEtE/F+qBfAK56/7rMgHzMn80HZGV23/UnCEX0cHfY+t
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Maxim MAX1720x as it is used by the gs101-oriole
(Google Pixel 6) board.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 5bb8f09422a22116781169611482179b10798c14..4feaebca340b1bc613c4f4ea9f1ff3b6686b092d 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -687,6 +687,7 @@ CONFIG_BATTERY_QCOM_BATTMGR=m
 CONFIG_BATTERY_SBS=m
 CONFIG_BATTERY_BQ27XXX=y
 CONFIG_BATTERY_MAX17042=m
+CONFIG_BATTERY_MAX1720X=m
 CONFIG_CHARGER_MT6360=m
 CONFIG_CHARGER_BQ25890=m
 CONFIG_CHARGER_BQ25980=m

-- 
2.49.0

