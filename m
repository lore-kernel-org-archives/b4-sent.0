From: Daniel Gomez <da.gomez@samsung.com>
Date: Sun, 30 Jun 2024 23:52:42 +0200
Subject: [PATCH v2 3/5] common/config: enable section parsing when
 recreation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240630-common-fixes-v2-3-16d26fb1dee0@samsung.com>
References: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
In-Reply-To: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=1040;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=CweM8hFKTR+/uaj1ksPTKot0K1j7X/HoaXPstHW9eK4=;
 b=6B4XAtAkwHvME4dbL0MLn062ggfwvqLlTfHhmwrkYArXkq0Z1VSXywhzAgot9Og3yTpusGlzi
 toGbeazCZlSDITOlIZ/XOzyUtbxL9Bat7VKDLKhx9wt5RWb3S0elUla
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When RECREATE_TEST_DEV is enabled, specific fs mount options such as
TMPFS_MOUNT_OPTIONS are ignored during section parsing unless the FSTYP
is modified. This allows the filesystem type to remain the same while
only specific fs mount options are changed during the parsing of section
parameters for test device recreation or when the section with speciic
fs mount options are different from the default.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 common/config | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/common/config b/common/config
index 43b32b93d..c739c4578 100644
--- a/common/config
+++ b/common/config
@@ -802,7 +802,7 @@ get_next_config() {
 	fi
 
 	parse_config_section $1
-	if [ ! -z "$OLD_FSTYP" ] && [ $OLD_FSTYP != $FSTYP ]; then
+	if $RECREATE_TEST_DEV || ([ ! -z "$OLD_FSTYP" ] && [ $OLD_FSTYP != $FSTYP ]); then
 		[ -z "$MOUNT_OPTIONS" ] && _mount_opts
 		[ -z "$TEST_FS_MOUNT_OPTS" ] && _test_mount_opts
 		[ -z "$MKFS_OPTIONS" ] && _mkfs_opts

-- 
2.43.0

