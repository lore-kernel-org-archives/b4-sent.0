From: Daniel Gomez <da.gomez@samsung.com>
Date: Sun, 30 Jun 2024 23:52:43 +0200
Subject: [PATCH v2 4/5] common/rc: read config section mount options for
 scratch devs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240630-common-fixes-v2-4-16d26fb1dee0@samsung.com>
References: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
In-Reply-To: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=921;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=MX1imlIj5wPkWMzNR8hoaaX8VaXzFw2Asr5Fz/o5nGY=;
 b=sZz/YXpGLXnqglUBlMLprRd857skhUZFF4h9qsrcaP+g8raHaTR9bt4iBvhYEgIxZCvS59uth
 pkBi6FswA49D0EMaHHpSQBne5q53TZiFolBkHIWsIRNf5foPlcuI5lx
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MOUNT_OPTIONS for scratch devices do not have specific fs mount options
values (such as TMPFS_MOUNT_OPTIONS) from the config section. So, allow
the scratch mount options to inherit section config values by reading
them from _common_mount_opts().

Move $* to the end so scratch device can be umount/mount. Otherwise, we
end up with multiple mounts in the same scratch directory.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 common/rc | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/common/rc b/common/rc
index 51827119c..627dbaaaa 100644
--- a/common/rc
+++ b/common/rc
@@ -231,8 +231,8 @@ _scratch_mount_options()
 {
 	_scratch_options mount
 
-	echo `_common_dev_mount_options $*` $SCRATCH_OPTIONS \
-					$SCRATCH_DEV $SCRATCH_MNT
+	echo `_common_mount_opts` $SCRATCH_OPTIONS \
+					$SCRATCH_DEV $SCRATCH_MNT $*
 }
 
 _supports_filetype()

-- 
2.43.0

