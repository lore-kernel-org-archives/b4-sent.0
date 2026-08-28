From: Maurycy Pawlowski-Wieronski <maurycy@maurycy.com>
Date: Fri, 28 Aug 2026 15:38:18 +0200
Subject: [PATCH] hfsplus: fix truncated xattr names in listxattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-hfsplus-copy_name-fix-v1-1-75ed9f0f378c@maurycy.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQrCMBCE4auUfXYhhlqCVxGRNU7tiqYh24pSe
 nejPn4D8y9kKAqjfbNQwVNNx1Sx3TQUB0lXsF6qyTvfueADD73l+2wcx/w+JXmAe32xdPDipG3
 DDlS/uaDOv+7h+LfN5xvi9I3Run4AK56TeXkAAAA=
X-Change-ID: 20260828-hfsplus-copy_name-fix-a6e2a0a4485e
To: Viacheslav Dubeyko <slava@dubeyko.com>, 
 John Paul Adrian Glaubitz <glaubitz@physik.fu-berlin.de>, 
 Yangtao Li <frank.li@vivo.com>, Kees Cook <kees@kernel.org>, 
 Justin Stitt <justinstitt@google.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Maurycy Pawlowski-Wieronski <maurycy@maurycy.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787924298; l=1797;
 i=maurycy@maurycy.com; s=20260828; h=from:subject:message-id;
 bh=IQcRwEprbEp3pKKBaOEYBUQJiRxQaoTwOUPdhNAlj1I=;
 b=KcE8oNk53vD38NezIG497FfmNiyzCJPCYtuzI0dy2SFvEjiWNpAhZl283vPZfwo6yGp39RBOD
 X3kCNlZskQ1DEEROGsjwU3ev4JIDLn460WlxnqGa+gmEQw9eLaGwy9p
X-Developer-Key: i=maurycy@maurycy.com; a=ed25519;
 pk=cK6zOi8RCOCUTWtJDER0YR5jWodFabZ1wH57I+KmldA=
X-Endpoint-Received: by B4 Relay for maurycy@maurycy.com/20260828 with auth_id=983
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 7dcbf17e3f91 ("hfsplus: refactor copy_name to not use strncpy")
changed copy_name() to build names in the osx. namespace with
scnprintf().

The supplied buffer size includes room for the prefix and the name, but
not for the terminating NUL:

  $ python3 -c "import os; print(os.listxattr('/mnt/tm/.DS_Store'))"
  ['osx.com.apple.FinderInf']

The truncated names cannot be passed back to getxattr(), so getfattr -d,
rsync -X, cp --preserve=xattr and tar --xattrs etc. seem to lose all
Apple attributes on hfsplus volumes.

Names in other namespaces go through the strscpy() branch, which already
sizes the buffer correctly. That's `why xfstests generic/377 does not
catch it.

Fixes: 7dcbf17e3f91 ("hfsplus: refactor copy_name to not use strncpy")
Cc: stable@vger.kernel.org # v6.10+
Signed-off-by: Maurycy Pawlowski-Wieronski <maurycy@maurycy.com>
---
 fs/hfsplus/xattr.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/fs/hfsplus/xattr.c b/fs/hfsplus/xattr.c
index 21a1c196c71f..4a3c97373682 100644
--- a/fs/hfsplus/xattr.c
+++ b/fs/hfsplus/xattr.c
@@ -515,8 +515,8 @@ static ssize_t copy_name(char *buffer, const char *xattr_name, size_t name_len)
 	memset(buffer, 0, name_len);
 
 	if (!is_known_namespace(xattr_name)) {
-		len = scnprintf(buffer, name_len + XATTR_MAC_OSX_PREFIX_LEN,
-				 "%s%s", XATTR_MAC_OSX_PREFIX, xattr_name);
+		len = scnprintf(buffer, name_len + XATTR_MAC_OSX_PREFIX_LEN + 1,
+				"%s%s", XATTR_MAC_OSX_PREFIX, xattr_name);
 	} else {
 		len = strscpy(buffer, xattr_name, name_len + 1);
 		if (len < 0) {

---
base-commit: 1b78070aaef63512688aebfbc82365ef9d6660f1
change-id: 20260828-hfsplus-copy_name-fix-a6e2a0a4485e

Best regards,
--  
Maurycy Pawlowski-Wieronski <maurycy@maurycy.com>

