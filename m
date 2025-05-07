From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Wed, 07 May 2025 13:16:41 +0800
Subject: [PATCH 1/2] MAINTAINERS: update filter of FUSE documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-fuse-passthrough-doc-v1-1-cc06af79c722@uniontech.com>
References: <20250507-fuse-passthrough-doc-v1-0-cc06af79c722@uniontech.com>
In-Reply-To: <20250507-fuse-passthrough-doc-v1-0-cc06af79c722@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=765;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=P4ex4ef6eoPig/ZnjlaXABq/hCbg/0h544yo4BjXjlo=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoGuzZSHEV6MyFNTei3rnABGWONK5m6STtjTshr
 jQKp2xUFKKJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBrs2QAKCRB2HuYUOZmu
 i6/UEACcakG+wlHZWpeHpcX3EraI3QxJN9nqyfzFLNBcPL1UaaSiD/z/lm/ar++ujtxTLKwASrV
 jL9iduRXWt5WdTc/I97Ssrs+d35LbS+7ehacMBZUOow78d6JHtWTrZL/Y5gpMc62EcE+bEkunyF
 VGePbYz8BMQxB7c2pvQSY7aFUomtLa6aXgizf5FOvcfL3WnmwYT/GOsUl2Kch4sG2ctSlFeOs5c
 YhN1bxeunBBwVC3JZ4ixaTr9cQqherl8rXk0GvSZSalfN5em1bofUWIg0U5lH0ag3CGjOTlMJrJ
 t01yrpFE7jv3S0aAZ2HgiDyqs2hVSBH5JeLo7gSht8Hbkpw3uKA4kmhcPtkaSFreGPsUjfE0JvQ
 iPuPd48C+MBjpD+yICwhjwBm1PpqPUewXmS2c3cM4cePwxExoS+MFBuLEwz7rZziejhWqjFQF3E
 hK0D6hQM1UrQ+XbBTFqgBskaWAU6WqoplI6rf+vpPDVwkOpNCPlNshW+oJSD1ORbRgL6kqVHH1n
 ZV8IE1mQc2Oejb1s/Ps+u37/lFNEIK+u8b/IKQMRYwjidNE9dtpRx1tGOc1/OF12CC/LJ/jNYiA
 I/0IGCLfjv0LZjq/SPynk6w80NJQPLXbOvOwZuSAgH8mnYrGtcC0pkH4jAtB4DurObI7u42w/6K
 rlh0YdSKuLsvlFQ==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are some fuse-*.rst files in Documentation directory,
let's make get_mantainers.pl work on those file instead of only
fuse.rst.

Signed-off-by: Chen Linxuan <chenlinxuan@uniontech.com>
---
 MAINTAINERS | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 5f8688630c014d2639ed9023ba5a256bc1c28e25..08cedaa87eb3f7047ca49d0e6f946dbd8e7ad793 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -9736,7 +9736,7 @@ L:	linux-fsdevel@vger.kernel.org
 S:	Maintained
 W:	https://github.com/libfuse/
 T:	git git://git.kernel.org/pub/scm/linux/kernel/git/mszeredi/fuse.git
-F:	Documentation/filesystems/fuse.rst
+F:	Documentation/filesystems/fuse*
 F:	fs/fuse/
 F:	include/uapi/linux/fuse.h
 

-- 
2.43.0

