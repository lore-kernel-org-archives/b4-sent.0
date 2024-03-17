From: Janne Grunau <j@jannau.net>
Date: Sun, 17 Mar 2024 15:54:49 +0100
Subject: [PATCH 3/4] configs: apple: Enable CMD_SELECT_FONT and FONT_16X32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240317-apple_config-v1-3-1b862bc140a9@jannau.net>
References: <20240317-apple_config-v1-0-1b862bc140a9@jannau.net>
In-Reply-To: <20240317-apple_config-v1-0-1b862bc140a9@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1000; i=j@jannau.net;
 h=from:subject:message-id; bh=efBW9m/mjVxxFme0pO4/bQ8IJkWzsIngZn6mrb/lwgQ=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtTvLBa9V3Zy/5YRKpim0BLYFKu5dt/mlUa7W09O/PYy1
 uirjV13RykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIn072NkWPd/T50ry6QpsfP9
 2V/1+XGtZ2DkUK6blTe1XG3nIrm+IkaG2b3TFs+/wPRGSjPE2dz0ddCCOLMLnbLTqo7m6twLU1X
 mAAA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple devices have high DPI displays so the larger fonts are preferable
for improved readability. This does not yet change the used font based
on the display's pixel density so the standard 8x16 font is still used
by default.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 configs/apple_m1_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/configs/apple_m1_defconfig b/configs/apple_m1_defconfig
index 31d966f0ab..c30aec7c55 100644
--- a/configs/apple_m1_defconfig
+++ b/configs/apple_m1_defconfig
@@ -9,6 +9,7 @@ CONFIG_SYS_PBSIZE=276
 # CONFIG_DISPLAY_CPUINFO is not set
 CONFIG_DISPLAY_BOARDINFO_LATE=y
 CONFIG_BOARD_LATE_INIT=y
+CONFIG_CMD_SELECT_FONT=y
 # CONFIG_NET is not set
 CONFIG_SYS_64BIT_LBA=y
 CONFIG_APPLE_SPI_KEYB=y
@@ -19,6 +20,7 @@ CONFIG_USB_XHCI_DWC3=y
 CONFIG_USB_XHCI_PCI=y
 CONFIG_USB_DWC3=y
 CONFIG_USB_KEYBOARD=y
+CONFIG_VIDEO_FONT_16X32=y
 CONFIG_SYS_WHITE_ON_BLACK=y
 CONFIG_NO_FB_CLEAR=y
 CONFIG_VIDEO_SIMPLE=y

-- 
2.44.0

