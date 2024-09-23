From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 23 Sep 2024 14:09:41 +0100
Subject: [PATCH v2 13/16] copy-firmware.sh: call ./check_whence.py before
 parsing the file
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240923-misc-fixes-v2-13-397f23443628@gmail.com>
References: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
In-Reply-To: <20240923-misc-fixes-v2-0-397f23443628@gmail.com>
To: linux-firmware@kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1727096979; l=1318;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=epSgfa8es9kJaFPzd3/t8MH8sbvov5s3daxLlc4Grlc=;
 b=5UqTS4n7j2Az6CXtr3yU4rkHD7w1pAtTJC62/8GA5PaDB+HJGYAtfOLYXLMFemz8BrLC4aN7u
 JHJkUUIQ7B/CTgRL4+j5bNcBPBbIciYQCwfVG96cvbYHlD2GeEGIVe7
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently ./check_whence.py is used when submitting new firmware, while
copy-firmware.sh when the firmware is to be consumed.

Since the latter does (very little) validation, having a malformed WHENCE file
can lead to all sorted of problems. From the obvious, where it errors out, to
more serious one where it overwrites or executes something it should not have.

Just call check_whence.py and error out. It takes 0.2s on my 5 year old
mid-range laptop, so the overhead is negligible.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 copy-firmware.sh | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/copy-firmware.sh b/copy-firmware.sh
index 12b97ae32f953c96a1c7612ccd14b1991a8687bf..12322530e5e155f77829f0d070d173ab5bfbab5b 100755
--- a/copy-firmware.sh
+++ b/copy-firmware.sh
@@ -71,6 +71,9 @@ if test -d "$destdir"; then
     find "$destdir" -type d -empty >/dev/null || warn "destination folder is not empty."
 fi
 
+$verbose "Checking that WHENCE file is formatted properly"
+./check_whence.py || err "check_whence.py has detected errors."
+
 # shellcheck disable=SC2162 # file/folder name can include escaped symbols
 grep -E '^(RawFile|File):' WHENCE | sed -E -e 's/^(RawFile|File): */\1 /;s/"//g' | while read k f; do
     test -f "$f" || continue

-- 
2.46.1

