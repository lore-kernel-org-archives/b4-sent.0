From: Michael Riesch <michael.riesch@collabora.com>
Date: Tue, 18 Nov 2025 12:12:27 +0100
Subject: [PATCH v2 3/3] arm64: defconfig: enable rockchip mipi csi-2
 receiver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251114-rockchip-mipi-receiver-v2-3-eb9b43377fc4@collabora.com>
References: <20251114-rockchip-mipi-receiver-v2-0-eb9b43377fc4@collabora.com>
In-Reply-To: <20251114-rockchip-mipi-receiver-v2-0-eb9b43377fc4@collabora.com>
To: Michael Riesch <michael.riesch@collabora.com>, 
 Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763464345; l=775;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=QnSDQN2WWfjs2EWe+e6kdAB9fFyLYhe37xUo+h6vPgM=;
 b=XeLsfJxVtIS8ozuzcmT1zTnkjSz5Yf2qGGwwLGRIxHjZ6cBA6BS/mf738D8ICgTQWu15nX4ss
 J0UOq+plGVWAC5GU1WU4jPL5DUd3E/asiExml3igaqeZAZ1EtAiKboF
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Rockchip MIPI CSI-2 Receiver is integrated into recent Rockchip
SoCs, such as the RK3568 and the RK3588.
Enable the driver for it in the default configuration.

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index e3a2d37bd104..a161666f2894 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -883,6 +883,7 @@ CONFIG_VIDEO_RENESAS_FCP=m
 CONFIG_VIDEO_RENESAS_FDP1=m
 CONFIG_VIDEO_RENESAS_VSP1=m
 CONFIG_VIDEO_RCAR_DRIF=m
+CONFIG_VIDEO_ROCKCHIP_CSI=m
 CONFIG_VIDEO_ROCKCHIP_RGA=m
 CONFIG_VIDEO_SAMSUNG_EXYNOS_GSC=m
 CONFIG_VIDEO_SAMSUNG_S5P_JPEG=m

-- 
2.39.5

