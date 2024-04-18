From: Janne Grunau <j@jannau.net>
Date: Thu, 18 Apr 2024 21:00:27 +0200
Subject: [PATCH v2 3/5] configs: apple: Enable CMD_SELECT_FONT and
 FONT_16X32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240418-apple_config-v2-3-7e5c6b9a9db3@jannau.net>
References: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
In-Reply-To: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1093; i=j@jannau.net;
 h=from:subject:message-id; bh=awJWiiYi0FEsQZBJtjQjML0mQJ6lEXedBk0qLMAtjDs=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NMrFm359vPJ7aVBhwSEe54zS5uduCxY9PPnnPuuc
 2YpFrkpd5SyMIhxMciKKbIkab/sYFhdoxhT+yAMZg4rE8gQBi5OAZjI9G6G/7EyW5TPzDad39Z4
 /UrIDs/uqBmRGoJHjl74es6wTkAy+BrDf7fr0z4EHhL/9nPDTgth6TmCv6cXMyg6sjLk7d4QkpV
 +iA0A
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple devices have high DPI displays so the larger fonts are preferable
for improved readability. This does not yet change the used font based
on the display's pixel density so the standard 8x16 font is still used
by default.

Reviewed-by: Mark Kettenis <kettenis@openbsd.org>
Reviewed-by: Neal Gompa <neal@gompa.dev>
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

