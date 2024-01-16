From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 13:52:03 +0000
Subject: [PATCH BlueZ 09/10] build: enable gc/dead code removal
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-autofoo-v1-9-626f6b54bd06@gmail.com>
References: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
In-Reply-To: <20240116-autofoo-v1-0-626f6b54bd06@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413116; l=776;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=tXVcdUfXETqQpcM+wIkv5sahEbGpnPS14+ukiFkfzcc=;
 b=YJpXGBb1WaXwi5eDQsIi0UBhNBBbCzabSiP2A+Ct6xRvyDikxhZReDeIqGsTqS3CZMg822lFX
 hzIFEZpe69ZBwYlIena8ier+Ae0HsGw5DkNWFGE3L+rUCBKisSKUy+G
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

Currently, there's plenty of unused code in most binaries. Enable
-fdata/function-sections, which allows the linker garbage collection to
do its job.

On a maintainer build, this reduces the (unstriped) binaries from 117 to
114MiB.
---
 acinclude.m4 | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/acinclude.m4 b/acinclude.m4
index c5d6de7b3..4b73a5bfc 100644
--- a/acinclude.m4
+++ b/acinclude.m4
@@ -134,6 +134,8 @@ AC_DEFUN([MISC_FLAGS], [
 		misc_cflags="$misc_cflags --coverage"
 		misc_ldflags="$misc_ldflags --coverage"
 	fi
+	misc_cflags="$misc_cflags -ffunction-sections -fdata-sections"
+	misc_ldflags="$misc_ldflags -Wl,--gc-sections"
 	AC_SUBST([MISC_CFLAGS], $misc_cflags)
 	AC_SUBST([MISC_LDFLAGS], $misc_ldflags)
 ])

-- 
2.43.0

