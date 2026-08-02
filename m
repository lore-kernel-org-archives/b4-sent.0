From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:18 +0200
Subject: [PATCH v3 02/15] ARM: mvebu: enable RN102 in mvebu_defconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-2-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=550;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=seD/gFydukKnJDD7V1GwLtTGZdYR6KcS8BRuLYyWVbU=;
 b=4aLvGBLtDFVmg0qtiFJyr6YGxtMMourr2aCGkgMhYB/Ibk68k3DHsTLMspPcgkLodlQ1udgYa
 UzRP2XdsDc9D+YvURvdS5DR5dHBtjQ6o3ddg0My3TN+McO8wn7aSaXl
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 arch/arm/configs/mvebu_defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/configs/mvebu_defconfig b/arch/arm/configs/mvebu_defconfig
index 91dd23e1c8..a13b153f9f 100644
--- a/arch/arm/configs/mvebu_defconfig
+++ b/arch/arm/configs/mvebu_defconfig
@@ -1,5 +1,6 @@
 CONFIG_ARCH_MVEBU=y
 CONFIG_MACH_GLOBALSCALE_MIRABOX=y
+CONFIG_MACH_NETGEAR_RN102=y
 CONFIG_MACH_NETGEAR_RN104=y
 CONFIG_MACH_LENOVO_IX4_300D=y
 CONFIG_MACH_MARVELL_ARMADA_XP_DB=y

-- 
2.47.3

