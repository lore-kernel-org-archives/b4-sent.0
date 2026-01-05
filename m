From: Louis Rannou <louis.rannou@non.se.com>
Date: Mon, 05 Jan 2026 11:49:26 +0100
Subject: [PATCH 1/4] oeqa/selftests: fitimage: fix missing spaces
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-fitimage-v1-1-e319258c4c4f@non.se.com>
References: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
In-Reply-To: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, adrian.freihofer@siemens.com, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767610172; l=794;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=rQ1nbHMPOK4AhgGS7auVgedREqGsY8ykUKHeGJ0VQSU=;
 b=4AZYV5+0A9nXX7Rdm4FYKxt2Tj2/U3hNKmps8EiSGEIM1dYZAziZR2a85TzRGJUekOPvuAfvd
 YSgQMQrHTErD6aHnluJSW5RRZCiBS4zflgLZYbP6lIXObgTX/1SBwpf
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Spaces missing around '='

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
 meta/lib/oeqa/selftest/cases/fitimage.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/meta/lib/oeqa/selftest/cases/fitimage.py b/meta/lib/oeqa/selftest/cases/fitimage.py
index 8df5e92a34..008687f9d1 100644
--- a/meta/lib/oeqa/selftest/cases/fitimage.py
+++ b/meta/lib/oeqa/selftest/cases/fitimage.py
@@ -1722,7 +1722,7 @@ UBOOT_SIGN_ENABLE = "1"
 UBOOT_SIGN_KEYDIR = "${TOPDIR}/signing-keys"
 UBOOT_SIGN_KEYNAME = "the-kernel-config-key"
 UBOOT_SIGN_IMG_KEYNAME = "the-kernel-image-key"
-UBOOT_MKIMAGE_DTCOPTS="-I dts -O dtb -p 2000"
+UBOOT_MKIMAGE_DTCOPTS = "-I dts -O dtb -p 2000"
 FIT_SIGN_INDIVIDUAL = "1"
 """
         self.write_config(config)

-- 
2.43.0

