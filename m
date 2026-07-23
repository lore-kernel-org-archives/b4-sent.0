From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:49 +0200
Subject: [PATCH 11/19] ARM: mvebu: adapt RN104 image support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-11-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=1003;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=sNCvOwcye+QHAYTnND2Fr5KWHRIURfKOjsHl8q4ianM=;
 b=eVhXxWDV+aQX5Vz/vHgDHt2ZvzLyJltfqnu0EN2PeTIaypvUBFwNmK9/dcO6ObUV54VC4D3Ku
 iUxdnciVH0qBNcrK9Nbcsh4Vchj/wb2xHfj+Ni5AmrhFbM5XHucKPvw
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 images/Makefile.mvebu | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/images/Makefile.mvebu b/images/Makefile.mvebu
index 1741f0e9a5..106a302cfa 100644
--- a/images/Makefile.mvebu
+++ b/images/Makefile.mvebu
@@ -37,10 +37,9 @@ image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102.img
 FILE_barebox-netgear-rn102-2nd.img = start_netgear_rn102.pblb
 image-$(CONFIG_MACH_NETGEAR_RN102) += barebox-netgear-rn102-2nd.img
 
-FLAGS_start_netgear_rn104.pblb.mvebu1img = -d 0x600000 -e 0x6e0000
 BOOTSRC_start_netgear_rn104.pblb.mvebu1img = nand
 BINHDR_start_netgear_rn104.pblb.mvebu1img = $(board)/netgear-rn104/binary.0
-FLAGS_start_netgear_rn104.pblb.mvebu1img = -B 0x20000:1
+FLAGS_start_netgear_rn104.pblb.mvebu1img = -B 0x20000:1 -d 0x0 -e 0x0
 FILE_barebox-netgear-rn104.img = start_netgear_rn104.pblb.mvebu1img
 pblb-$(CONFIG_MACH_NETGEAR_RN104) += start_netgear_rn104
 image-$(CONFIG_MACH_NETGEAR_RN104) += barebox-netgear-rn104.img

-- 
2.47.3

