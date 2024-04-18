From: Janne Grunau <j@jannau.net>
Date: Thu, 18 Apr 2024 21:00:26 +0200
Subject: [PATCH v2 2/5] configs: apple: Use "vidconsole,serial" as
 stdout/stderr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240418-apple_config-v2-2-7e5c6b9a9db3@jannau.net>
References: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
In-Reply-To: <20240418-apple_config-v2-0-7e5c6b9a9db3@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=904; i=j@jannau.net;
 h=from:subject:message-id; bh=pYGw3Rvsr83Yc8ZaQ99xyUt7JbaiOW2b/6U7j6EjC9k=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhjTF3NN9cRuTa14bdceZaN24ns2/uiDgYl3kvf/l1bt/S
 Su1mWzuKGVhEONikBVTZEnSftnBsLpGMab2QRjMHFYmkCEMXJwCMBHTZoZ/Wl/vbTHY+N97ktKW
 A49nJcXWXhU3inaeXSO1OWfnxnlM/Az/HVcyff0xST79Y8lHowUrmWoc9RaJ1zPJPJ2n1Vrxw1G
 EBwA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The display size querying in efi_console relies on this order. The
display should be the primary output device and should be used to
display more than 80x25 chars.

Reviewed-by: Mark Kettenis <kettenis@openbsd.org>
Reviewed-by: Neal Gompa <neal@gompa.dev>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/configs/apple.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/include/configs/apple.h b/include/configs/apple.h
index 0576bc04c9..a70440b3ad 100644
--- a/include/configs/apple.h
+++ b/include/configs/apple.h
@@ -6,8 +6,8 @@
 /* Environment */
 #define ENV_DEVICE_SETTINGS \
 	"stdin=serial,usbkbd,spikbd\0" \
-	"stdout=serial,vidconsole\0" \
-	"stderr=serial,vidconsole\0"
+	"stdout=vidconsole,serial\0" \
+	"stderr=vidconsole,serial\0"
 
 #if IS_ENABLED(CONFIG_CMD_NVME)
 	#define BOOT_TARGET_NVME(func) func(NVME, nvme, 0)

-- 
2.44.0

