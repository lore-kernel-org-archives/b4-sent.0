From: Janne Grunau <j@jannau.net>
Date: Sun, 17 Mar 2024 15:54:48 +0100
Subject: [PATCH 2/4] configs: apple: Use "vidconsole,serial" as
 stdout/stderr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240317-apple_config-v1-2-1b862bc140a9@jannau.net>
References: <20240317-apple_config-v1-0-1b862bc140a9@jannau.net>
In-Reply-To: <20240317-apple_config-v1-0-1b862bc140a9@jannau.net>
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: Simon Glass <sjg@chromium.org>, u-boot@lists.denx.de, 
 asahi@lists.linux.dev, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=811; i=j@jannau.net;
 h=from:subject:message-id; bh=xRd+NgmurhsE0y/QsMQndq65xM1784gn3CH0uS+KJcY=;
 b=kA0DAAoWoRs8240vZWYByyZiAGX3BDejycIr/yrWDpJuXUDTC/BljVdi36A6LPw2o2iz/Hibq
 Ih1BAAWCgAdFiEEYivpiACrfCFcfeBWoRs8240vZWYFAmX3BDcACgkQoRs8240vZWbhqAEAuXlN
 GmRMlrTBtvWerMAtw5s8j5l5JoPezYtNXWRU/QIBAMeW7g+GDDAe42V3LBn2Hl6ioFiofc9Y0IY
 G6O0dQOUJ
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The display size querying in efi_console relies on this order. The
display should be the primary output device and should be used to
display more than 80x25 chars.

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

