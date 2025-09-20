From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Sat, 20 Sep 2025 20:23:26 +0200
Subject: [PATCH 01/10] ARM: mediatek: add board_dt_compat entry for the
 MT6582 SoC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250920-mt6582-v1-1-b887720f577d@protonmail.com>
References: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
In-Reply-To: <20250920-mt6582-v1-0-b887720f577d@protonmail.com>
To: Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Russell King <linux@armlinux.org.uk>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sean Wang <sean.wang@mediatek.com>
Cc: linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758392693; l=726;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=rPW5X0dJhrkjRCNNcYv6faj1inNTS9fRmw61VUQKL+w=;
 b=sk3kgTpc2Yx2+z5wdsgMX0XRjqoO+k8vc8osDkRpQFyJa/JHqcBSNo/vrm8lBDnIOJq4DyTco
 DiaGwpso9ZNBl0PDGiYXz4Q63P8uiDz5rqVgpgW0C9YVonlimW/SX20
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible string for the MT6582 SoC.

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 arch/arm/mach-mediatek/mediatek.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/mach-mediatek/mediatek.c b/arch/arm/mach-mediatek/mediatek.c
index 5c28124bd0078b31665fef647e496f4131b82c8d..fd3a8834fc4fd47adcc91c0d9371d4a1e9c0a7e6 100644
--- a/arch/arm/mach-mediatek/mediatek.c
+++ b/arch/arm/mach-mediatek/mediatek.c
@@ -39,6 +39,7 @@ static void __init mediatek_timer_init(void)
 static const char * const mediatek_board_dt_compat[] = {
 	"mediatek,mt2701",
 	"mediatek,mt6572",
+	"mediatek,mt6582",
 	"mediatek,mt6589",
 	"mediatek,mt6592",
 	"mediatek,mt7623",

-- 
2.49.0

