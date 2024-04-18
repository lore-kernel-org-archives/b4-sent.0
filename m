From: Janne Grunau <j@jannau.net>
Date: Thu, 18 Apr 2024 21:00:29 +0200
Subject: [PATCH v2 5/5] arm: apple: Do not list bootflows on boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240418-apple_config-v2-5-7e5c6b9a9db3@jannau.net>
References: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
In-Reply-To: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=652; i=j@jannau.net;
 h=from:subject:message-id; bh=aKmGZalIZA4d3jN5L9yo43E4OSWpBFF1+lCA1zAzZAU=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NNdt+0OSJ1iF1Cav3DTObVAQVcOQ7V5RSo55pWtH
 2YVn3HtKGVhEONikBVTZEnSftnBsLpGMab2QRjMHFYmkCEMXJwCMBGeKYwMXTf227KazXKKWiRr
 k+ZnkFEc9u73dRMF1Xs7/Ey3rTsiyvA/eZYF75yw8xxmRg7uGVEN8yRniFR+U//0Y7dX//2C/i8
 cAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The bootflow list is only seen briefly and is probably more confusing
than helpful.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 configs/apple_m1_defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/configs/apple_m1_defconfig b/configs/apple_m1_defconfig
index c30aec7c55..4eac1a9e2d 100644
--- a/configs/apple_m1_defconfig
+++ b/configs/apple_m1_defconfig
@@ -8,6 +8,7 @@ CONFIG_SYS_CBSIZE=256
 CONFIG_SYS_PBSIZE=276
 # CONFIG_DISPLAY_CPUINFO is not set
 CONFIG_DISPLAY_BOARDINFO_LATE=y
+CONFIG_BOOTCOMMAND="bootflow scan -b"
 CONFIG_BOARD_LATE_INIT=y
 CONFIG_CMD_SELECT_FONT=y
 # CONFIG_NET is not set

-- 
2.44.0

