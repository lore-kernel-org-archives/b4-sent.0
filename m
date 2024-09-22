From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Sun, 22 Sep 2024 21:17:43 +0100
Subject: [PATCH 08/16] Revert "copy-firmware: Support additional compressor
 options"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240922-misc-fixes-v1-8-8c6e52997c94@gmail.com>
References: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
In-Reply-To: <20240922-misc-fixes-v1-0-8c6e52997c94@gmail.com>
To: linux-firmware@kernel.org
Cc: Juerg Haefliger <juerg.haefliger@canonical.com>, 
 Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727036271; l=1377;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=uKcSV4YdwVinyW5T4fyiK7n8r68VrubCm2yqPycfyws=;
 b=RqIF9CxL42ZSNoIrDqUlv3LPcGB7/BO/Pqvq0xEqQl8ubU49BbboYBQE595X4TIjuqmLY3Ydp
 8MBWFK3tvp4BEtt6cSR6nve48KdpcOMhTm9ZQlrsA9Uv5mrtahyCknZ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 2bad80e7edd3c0f84718545d9338c8edfed16513.

The commit effectively added accidental command injection, while it was aiming
to control the compression flags.

In practise you'd want to use ZSTD_CLEVEL and ZSTD_NBTHREADS for zstd as
documented in man(1)zstd it allows for up-to level 19, which is fined since the
kernel does not support higher levels.

Arch, Alpine and likely other distributions have been using this since day one.

The other compressors like xz have equivalent environment variables.

Cc: Juerg Haefliger <juerg.haefliger@canonical.com>
Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 344f478db74a7080b34c264645d6bcd9a80384a8..21ed20d5886fe71588b923914265f992cf5c29b0 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -44,14 +44,6 @@ while test $# -gt 0; do
             shift
             ;;
 
-        -*)
-            if test "$compress" = "cat"; then
-                echo "ERROR: unknown command-line option: $1"
-                exit 1
-            fi
-            compress="$compress $1"
-            shift
-            ;;
         *)
             if test "x$destdir" != "x"; then
                 echo "ERROR: unknown command-line options: $*"

-- 
2.46.1

