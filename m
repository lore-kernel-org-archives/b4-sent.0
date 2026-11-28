From: Felix Huang <akafelixab@gmail.com>
Date: Fri, 27 Nov 2026 19:16:55 -0500
Subject: [PATCH] staging: fbtft: fb_tinylcd: align arguments with open
 parenthesis
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-fbtft-align-v1-1-92de6f92ebe8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyNz3bSkkrQS3cSczPQ8XdNks8TkZEtzY4ukJCWgjoKi1LTMCrBp0bE
 QfnFpUlZqcgnICKXaWgBeq9lObwAAAA==
X-Change-ID: 20261127-fbtft-align-5c6acc9738bb
To: Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: dri-devel@lists.freedesktop.org, linux-fbdev@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Felix Huang <akafelixab@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795825022; l=1084;
 i=akafelixab@gmail.com; s=20261128; h=from:subject:message-id;
 bh=I+0cYZeTLzqxiZSLHzV9PNt605lEdXdHOIenXaZROZ8=;
 b=JmL5hJ8fJbaXQJtTCdgX3n0mKDHm2kGaJuFYf4Oa/FIgQJFLQTK1Mgd97AahsOxXSa/QS/nvK
 lZUCN+x83s7AA+GfI4FqTaz/m1ZQyf/tPe4Bc4ogDfbSW8kAEgh1B2z
X-Developer-Key: i=akafelixab@gmail.com; a=ed25519;
 pk=Axl3BM1UWa+m0/AWcEhRIdIk/WY9FnY4wZkyQn64uVY=
X-Endpoint-Received: by B4 Relay for akafelixab@gmail.com/20261128 with auth_id=1670
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Align multi-line function call arguments with the opening parenthesis
to adhere to the Linux kernel coding style and fix checkpatch.pl
alignment checks.

Signed-off-by: Felix Huang <akafelixab@gmail.com>
---
 drivers/staging/fbtft/fb_tinylcd.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/staging/fbtft/fb_tinylcd.c b/drivers/staging/fbtft/fb_tinylcd.c
index afa8f1c74..d58b12472 100644
--- a/drivers/staging/fbtft/fb_tinylcd.c
+++ b/drivers/staging/fbtft/fb_tinylcd.c
@@ -38,7 +38,7 @@ static int init_display(struct fbtft_par *par)
 	write_reg(par, 0xE5, 0x00);
 	write_reg(par, 0xF0, 0x36, 0xA5, 0x53);
 	write_reg(par, 0xE0, 0x00, 0x35, 0x33, 0x00, 0x00, 0x00,
-		       0x00, 0x35, 0x33, 0x00, 0x00, 0x00);
+		  0x00, 0x35, 0x33, 0x00, 0x00, 0x00);
 	write_reg(par, MIPI_DCS_SET_PIXEL_FORMAT, 0x55);
 	write_reg(par, MIPI_DCS_EXIT_SLEEP_MODE);
 	fsleep(250);

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261127-fbtft-align-5c6acc9738bb

Best regards,
--  
Felix Huang <akafelixab@gmail.com>

