From: Chen Linxuan <chenlinxuan@uniontech.com>
Date: Wed, 07 May 2025 16:42:16 +0800
Subject: [PATCH v2 1/2] MAINTAINERS: update filter of FUSE documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250507-fuse-passthrough-doc-v2-1-ae7c0dd8bba6@uniontech.com>
References: <20250507-fuse-passthrough-doc-v2-0-ae7c0dd8bba6@uniontech.com>
In-Reply-To: <20250507-fuse-passthrough-doc-v2-0-ae7c0dd8bba6@uniontech.com>
To: Miklos Szeredi <miklos@szeredi.hu>, Jonathan Corbet <corbet@lwn.net>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, Chen Linxuan <chenlinxuan@uniontech.com>, 
 Amir Goldstein <amir73il@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=815;
 i=chenlinxuan@uniontech.com; h=from:subject:message-id;
 bh=y42qoLgQli2vjKWNdl397i8EcidQOg+VhEWweGEDgMQ=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBoGx0D4Lng+/PWfbuRBECYjR3GOdxRrrem5npZO
 RxvyFHnioKJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaBsdAwAKCRB2HuYUOZmu
 i4WEEACEiCfgkn/+Uh4aJp1ZgralHr+/z3NAEsQiarUZgLTRWT47ShbUYw603AdA8FOb8x8b9LV
 bWnDA5t5gM85bpgMpnjxi7lR6cQJwGKuhU3e4ErM3q2vm0Ab2xxMOw4tOo+X9zcXWSB4gBCpz3u
 cnVGkp6qxUgcpNY4Wicg5v3D3IBSOjWWDMaH3i1GU7TSs842ixqTeXM0E9wUCanN4eRm1LGDzm+
 cOxIFyKKyXuEP4pbmuCnvZRCMJdEpodgmhBWIKicMf8ggWd2KwF7gL0o611KFMnv4FGWWFWJjxm
 7SwvyekAaFhhvoNvxnHNNwUvAPak2PPtWBVa5R7adp8Tg/AwohX5grOy3dqNSVntRVsaTl07iBZ
 aleSnassOaKzJzl13tHELjK2iRBw0G3QZn1/CjfKWVV5XLaa39GxSu1PsY/kUxdLI6UYk/ZDoCL
 8X1UdYfp/jsbtfd1c+I2aQbBvTFqqXLaAq9uaN8LeP3Fgwm28ib28xkxdf1Og2rX1ZUrjHNEyxC
 Wt58ChOL7v6FGBHo30wZzpolwMOl4RCC4FF4r2d+ok1W1bUKlrWJQxrLuN3GH12lNIeHJqALezX
 shJDQcNX+vPRCGLIHouni2aplzsGMHbgKP/nU3ZHDaTwJp6HZKlojYMBf2NHLlj4N/i1zlXUuSG
 HJqUX3M9koNMynQ==
X-Developer-Key: i=chenlinxuan@uniontech.com; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for chenlinxuan@uniontech.com/default with auth_id=380
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are some fuse-*.rst files in Documentation directory,
let's make get_mantainers.pl work on those file instead of only
fuse.rst.

Reviewed-by: Amir Goldstein <amir73il@gmail.com>
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

