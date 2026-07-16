From: Selby Mashiki <mashikiselby@gmail.com>
Date: Thu, 16 Jul 2026 13:08:33 +0200
Subject: [PATCH] staging: fbtft: fb_ra8875: replace udelay with
 usleep_range
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260716-staging-testing-v1-1-2ebc0c6bb27a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMzQqCIRCF4VuRWX+CY2DRrUQLfyabFhaORSDee
 9q3OjyL83YQqkwCZ9Wh0oeFn2UCNwXx7ksmzWkarLHOHNFpaT5zybqRtLUBwwmTOySTEObrVen
 G33/xct0t7/Cg2FYGxvgB5ulh2HMAAAA=
X-Change-ID: 20260716-staging-testing-b1b81d63d0d1
To: Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: dri-devel@lists.freedesktop.org, linux-fbdev@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Selby Mashiki <mashikiselby@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784200113; l=1339;
 i=mashikiselby@gmail.com; s=20260716; h=from:subject:message-id;
 bh=Kw+oD1A3+MZuZjRR0K6KD78XW22TnMscyBb1Nk+0T4w=;
 b=+XPtQJi1tekVKGVbfuhRY+B22fbiiusYW8TIqcCqQ4iPZ2931p+OWTAgL0WeT9DfelBFQd/9T
 PeId6DNZnE7BgpJEDPyRCWLDoFaoaVkKJyNgYYFevuEBf03PbzXTZ28
X-Developer-Key: i=mashikiselby@gmail.com; a=ed25519;
 pk=pdu1PfyliHcDzX9YL6q+8PseyTQ5vDHYAsHmrqMp/BQ=
X-Endpoint-Received: by B4 Relay for mashikiselby@gmail.com/20260716 with auth_id=875
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

udelay() busy-waits for the specified duration, consuming CPU cycles
unnecessarily. usleep_range() is preferred for delays that can sleep,
as it allows the scheduler to run other tasks during the wait.

Replace two instances of udelay(100) with usleep_range(100, 200) to
use the preferred sleeping delay function.

Signed-off-by: Selby Mashiki <mashikiselby@gmail.com>
---
 drivers/staging/fbtft/fb_ra8875.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/staging/fbtft/fb_ra8875.c b/drivers/staging/fbtft/fb_ra8875.c
index 0ab1de664..d2400bb44 100644
--- a/drivers/staging/fbtft/fb_ra8875.c
+++ b/drivers/staging/fbtft/fb_ra8875.c
@@ -210,7 +210,7 @@ static void write_reg8_bus8(struct fbtft_par *par, int len, ...)
 	}
 	len--;
 
-	udelay(100);
+	usleep_range(100, 200);
 
 	if (len) {
 		buf = (u8 *)par->buf;
@@ -231,7 +231,7 @@ static void write_reg8_bus8(struct fbtft_par *par, int len, ...)
 
 	/* restore user spi-speed */
 	par->fbtftops.write = fbtft_write_spi;
-	udelay(100);
+	usleep_range(100, 200);
 }
 
 static int write_vmem16_bus8(struct fbtft_par *par, size_t offset, size_t len)

---
base-commit: 64276d9bfe4d1fdd5cf2636f1065f7ea55c2defb
change-id: 20260716-staging-testing-b1b81d63d0d1

Best regards,
--  
Selby Mashiki <mashikiselby@gmail.com>

