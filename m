From: Christian DREHER <christian.dreher@nanoxplore.com>
Date: Tue, 28 Apr 2026 20:04:06 +0200
Subject: [PATCH 2/4] net: macb: use SA1 for MAC filtering on GEM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-net-macb-support-for-feature-lite-instances-v1-2-480e4cecac01@nanoxplore.com>
References: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
In-Reply-To: <20260428-net-macb-support-for-feature-lite-instances-v1-0-480e4cecac01@nanoxplore.com>
To: u-boot@lists.denx.de
Cc: Jerome Forissier <jerome.forissier@arm.com>, 
 Tom Rini <trini@konsulko.com>, 
 Christian DREHER <christian.dreher@nanoxplore.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777399485; l=1382;
 i=christian.dreher@nanoxplore.com; s=20260428; h=from:subject:message-id;
 bh=lhvo8U12ACbhoHnNc4Pv7TnDPkFRxIQ2KNLPjDefG30=;
 b=BwHnmEZ8CvAXem3DEBgw3uWYyzZAWfm5pabVGPkuCncL8rTDVgS/khodoWP6PojF+3pnmPRuR
 nyoxjbcZt5ZCT871FaU1P2Yy19ZkkbLhWJPWA6Kf4H1MV+p0m1ussLl
X-Developer-Key: i=christian.dreher@nanoxplore.com; a=ed25519;
 pk=id7EcKmXLV2xNgNiCIcsPjkoMQHM/qxTYqEqMhidSAU=
X-Endpoint-Received: by B4 Relay for christian.dreher@nanoxplore.com/20260428 with auth_id=760
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MACB uses specific address registers (SA Top and Bottom) to
filter source or destination MAC addresses.
On the Gigabit Ethernet version, SA1B is @0x88.
On the non-GEM version, SA1B is @0x98.

Before this commit, the code was always writing 0x98. By chance,
on GEM, this is the address of SA3B, allowing the driver to work
anyway.

The motivation for this change is to be able to use the driver on
an instance of the GEM with less than 4 SA registers.

Signed-off-by: Christian DREHER <christian.dreher@nanoxplore.com>
---
 drivers/net/macb.c | 9 +++++++--
 1 file changed, 7 insertions(+), 2 deletions(-)

diff --git a/drivers/net/macb.c b/drivers/net/macb.c
index 719aef39a3f..807a038e071 100644
--- a/drivers/net/macb.c
+++ b/drivers/net/macb.c
@@ -1007,9 +1007,14 @@ static int _macb_write_hwaddr(struct macb_device *macb, unsigned char *enetaddr)
 	/* set hardware address */
 	hwaddr_bottom = enetaddr[0] | enetaddr[1] << 8 |
 			enetaddr[2] << 16 | enetaddr[3] << 24;
-	macb_writel(macb, SA1B, hwaddr_bottom);
 	hwaddr_top = enetaddr[4] | enetaddr[5] << 8;
-	macb_writel(macb, SA1T, hwaddr_top);
+	if (macb_is_gem(macb)) {
+		gem_writel(macb, SA1B, hwaddr_bottom);
+		gem_writel(macb, SA1T, hwaddr_top);
+	} else {
+		macb_writel(macb, SA1B, hwaddr_bottom);
+		macb_writel(macb, SA1T, hwaddr_top);
+	}
 	return 0;
 }
 

-- 
2.47.3

