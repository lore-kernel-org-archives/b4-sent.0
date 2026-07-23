From: Luca Lauro <famlauro93l@gmail.com>
Date: Thu, 23 Jul 2026 15:57:43 +0200
Subject: [PATCH 05/19] ARM: mvebu: add Kconfig entry for Netgear RN102
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-rn102-rn104-series-v1-5-7698d25df866@gmail.com>
References: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
In-Reply-To: <20260723-rn102-rn104-series-v1-0-7698d25df866@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784815061; l=558;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=TLuAY12/MA/HJcEBU6wa/1CTEpaLf87o4fmALOnBLnI=;
 b=DkNhxKHV0REA+Nx3NN2fdWMslXzkIUYKCTy+4c7NoKX0F57cK7tTlFtt7EJ5fExZHUu0CI1A3
 uXedWTc4VWwAvGy75ruAeY/iJ0ehVzOf5tTnPtELV+d5Y6exbSvsQSV
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

---
 arch/arm/mach-mvebu/Kconfig | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm/mach-mvebu/Kconfig b/arch/arm/mach-mvebu/Kconfig
index ed1302af65..046d539656 100644
--- a/arch/arm/mach-mvebu/Kconfig
+++ b/arch/arm/mach-mvebu/Kconfig
@@ -37,6 +37,10 @@ config MACH_GLOBALSCALE_MIRABOX
 	bool "Globalscale Mirabox"
 	select ARCH_ARMADA_370
 
+config MACH_NETGEAR_RN102
+	bool "Netgear ReadyNAS 102"
+	select ARCH_ARMADA_370
+
 config MACH_NETGEAR_RN104
 	bool "Netgear ReadyNAS 104"
 	select ARCH_ARMADA_370

-- 
2.47.3

