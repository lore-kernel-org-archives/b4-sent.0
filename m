From: Junhui Liu <liujh2818@outlook.com>
Date: Mon, 30 Dec 2024 11:30:18 +0800
Subject: [PATCH v2 3/8] USB: dwc2: Fix HBstLen setting for external DMA
 mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241230-dwc2-dev-v2-3-12cd9b8a2358@outlook.com>
References: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
In-Reply-To: <20241230-dwc2-dev-v2-0-12cd9b8a2358@outlook.com>
To: Tom Rini <trini@konsulko.com>, Marek Vasut <marex@denx.de>, 
 Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@baylibre.com>
Cc: u-boot@lists.denx.de, Kongyang Liu <seashell11234455@gmail.com>, 
 Junhui Liu <liujh2818@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735529447; l=1579;
 i=liujh2818@outlook.com; s=20241030; h=from:subject:message-id;
 bh=X2wPlAec1lTbhEc4kHMvFzI7dPaWHtgbyCFMMHoPHXM=;
 b=i59f4eY4FVgdY6MTwEtkEpQjYSIIdbLb8NUPjevDckfmhGN/NWErizUqKyw9uX0UOSeeIdkCu
 jlcu+bicvc+C7YOp7FBIMNz5K46UqWwRgiSBgh5UMPvnsGmXykeXF5q
X-Developer-Key: i=liujh2818@outlook.com; a=ed25519;
 pk=ApYwI6KD3EjynMw61RqGa6c5BGbStQnKSrbNN+aQqT4=
X-Endpoint-Received: by B4 Relay for liujh2818@outlook.com/20241030 with auth_id=259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kongyang Liu <seashell11234455@gmail.com>

The loop used to calculate HBstLen for extern DMA mode does not produce
the correct result according to the datasheet [1]. Replacing that loop
with a direct calculation using LOG2 to correctly assign the burst length
in the GAHBCFG register for external DMA mode.

[1] https://rockchip.fr/RK312X%20TRM/chapter-26-usb-otg-2-0.pdf#page=24

Signed-off-by: Kongyang Liu <seashell11234455@gmail.com>
Signed-off-by: Junhui Liu <liujh2818@outlook.com>

---
Additionally, the boards I have only use internal DMA mode, and it’s
unclear which chips employ external DMA. The testing was performed by
comparing against the datasheet, and the results are shown in [2].

[2] https://gist.github.com/Judehahh/34530da390b58728102778406e602cb1
---
 drivers/usb/host/dwc2.c | 7 ++-----
 1 file changed, 2 insertions(+), 5 deletions(-)

diff --git a/drivers/usb/host/dwc2.c b/drivers/usb/host/dwc2.c
index 609de18faa3abc5f4ecb0c23cf3590966bad7992..954650d856a4f2e95d74e1b5716c0ebe83fa9ba8 100644
--- a/drivers/usb/host/dwc2.c
+++ b/drivers/usb/host/dwc2.c
@@ -448,11 +448,8 @@ static void dwc_otg_core_init(struct udevice *dev)
 	case DWC2_HWCFG2_ARCHITECTURE_SLAVE_ONLY:
 		break;
 	case DWC2_HWCFG2_ARCHITECTURE_EXT_DMA:
-		while (brst_sz > 1) {
-			ahbcfg |= ahbcfg + (1 << DWC2_GAHBCFG_HBURSTLEN_OFFSET);
-			ahbcfg &= DWC2_GAHBCFG_HBURSTLEN_MASK;
-			brst_sz >>= 1;
-		}
+		ahbcfg |= (LOG2(brst_sz >> 1) << DWC2_GAHBCFG_HBURSTLEN_OFFSET) &
+			  DWC2_GAHBCFG_HBURSTLEN_MASK;
 
 #ifdef DWC2_DMA_ENABLE
 		ahbcfg |= DWC2_GAHBCFG_DMAENABLE;

-- 
2.39.2

