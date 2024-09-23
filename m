From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:42 +0100
Subject: [PATCH v2 14/16] copy-firmware.sh: remove no longer reachable test
 -f
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-14-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=911;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=QDN2msaWLL4LMcQJGzGJJiag3JpIJ1uFyJ088OvH4r0=;
 b=XIgTk6QKrn6w+5hKNEhbgsFxrrg2KuPEdZZVTCgytjnBagik3pmNDBADo68IUcr/KYXvGOyL0
 cJGShjpFVUXCImF42B0DU1uM72HPOR1KQXYug2+2PFhcFDXBR6IPjy7
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With previous commit we call check_whence.py, which ensures that all files
listed are available. Drop the now dead code.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 1 -
 1 file changed, 1 deletion(-)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 12322530e5e155f77829f0d070d173ab5bfbab5b..bdc20d596ef5f9d99b17e9cea74a0358f0f4de09 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -76,7 +76,6 @@ $verbose "Checking that WHENCE file is formatted properly"
 
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
-    test -f "$f" || continue
     install -d "$destdir/$(dirname "$f")"
     $verbose "copying/compressing file $f$compext"
     if test "$compress" != "cat" && test "$k" = "RawFile"; then

-- 
2.46.1

