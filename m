From: Thomas Antoine <t.antoine@uclouvain.be>
Date: Mon, 04 Aug 2025 16:26:40 +0200
Subject: [PATCH v5 3/4] arm64: defconfig: enable Maxim MAX77759 fuel-gauge
 driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250804-b4-gs101_max77759_fg-v5-3-03a40e6c0e3d@uclouvain.be>
References: <20250804-b4-gs101_max77759_fg-v5-0-03a40e6c0e3d@uclouvain.be>
In-Reply-To: <20250804-b4-gs101_max77759_fg-v5-0-03a40e6c0e3d@uclouvain.be>
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-samsung-soc@vger.kernel.org, Thomas Antoine <t.antoine@uclouvain.be>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754317658; l=764;
 i=t.antoine@uclouvain.be; s=20241202; h=from:subject:message-id;
 bh=gaoSugHRAz5fOiJGPTrSTYl8U3fwbJdk2k1I718EDsY=;
 b=ZG9Xmwog66bZ8cSUspq6GfK/PeRmbJru5wn9agjtUDDP6k3RzK0VaZzzaMfkTbctuK/5+YMlv
 VGOddOKH0rrDFrORISbF19f5WBqEmXuzmboc/ROIKMOnvlmk2PA+mSb
X-Developer-Key: i=t.antoine@uclouvain.be; a=ed25519;
 pk=sw7UYl31W1LTpgWRiX4xIF5x6ok7YWZ6XZnHqy/d3dY=
X-Endpoint-Received: by B4 Relay for t.antoine@uclouvain.be/20241202 with auth_id=289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Maxim MAX77759 fuel gauge as it is used by the gs101-oriole
(Google Pixel 6) and gs101-raven (Google Pixe 6 Pro) boards.

Signed-off-by: Thomas Antoine <t.antoine@uclouvain.be>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 7e04a2905ce4ec71e8263a85f20398f702917390..dd90e72e71dfd45c62942f83db6814f263517a0c 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -691,6 +691,7 @@ CONFIG_BATTERY_QCOM_BATTMGR=m
 CONFIG_BATTERY_SBS=m
 CONFIG_BATTERY_BQ27XXX=y
 CONFIG_BATTERY_MAX17042=m
+CONFIG_BATTERY_MAX77759=m
 CONFIG_CHARGER_MT6360=m
 CONFIG_CHARGER_BQ25890=m
 CONFIG_CHARGER_BQ25980=m

-- 
2.50.1

