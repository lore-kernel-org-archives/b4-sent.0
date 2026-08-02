From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:20 +0200
Subject: [PATCH v3 04/15] ARM: mvebu: rename PUTC_LL to MVEBU_PUTC_LL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-4-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=1088;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=/5V7fuKugqpi3D+fGP52vhlNoamQA7hEofVWrbSmDoo=;
 b=fXiJsyOAfwyUScWz8NvaLVW0yuIxCc/+q3ZIp6HQaLaFT/V30qnKOO0XtbUzYpzAxzEXHZJyN
 myKAbb6qEXuBa56cgDV7MI/o3MJ2TB7QSRdOLodOJjWPFj3uQihHr8m
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The name PUTC_LL is used by multiple architectures in barebox for their
early low-level UART output helpers. Since these functions differ between
SoCs and are defined in architecture-specific debug_ll headers, using the
same global name can lead to collisions or accidental overrides when
including multiple debug_ll headers.

To avoid such namespace conflicts and to make the origin of the function
explicit, rename the mvebu-specific PUTC_LL to MVEBU_PUTC_LL.

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 include/mach/mvebu/debug_ll.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/mach/mvebu/debug_ll.h b/include/mach/mvebu/debug_ll.h
index cf08776d4f..cd81b27e39 100644
--- a/include/mach/mvebu/debug_ll.h
+++ b/include/mach/mvebu/debug_ll.h
@@ -15,7 +15,7 @@
 
 #define EARLY_UART	UARTn_BASE(CONFIG_MVEBU_CONSOLE_UART)
 
-static inline void PUTC_LL(char c)
+static inline void MVEBU_PUTC_LL(char c)
 {
 	/* Wait until there is space in the FIFO */
 	while (!(readl(EARLY_UART + UART_LSR) & LSR_THRE))

-- 
2.47.3

