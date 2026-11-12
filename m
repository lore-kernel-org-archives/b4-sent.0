From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 12 Nov 2026 13:14:06 +0900
Subject: [PATCH v2] src/t_dir_offset2: do not check d_ino of a stale first
 entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-ovl077-stale-next-v2-1-6d3a691a92df@samsung.com>
X-B4-Tracking: v=1; b=H4sIAA099WoC/32NQQ6CMBBFr0Jm7RimgoAr72FYTHCAJtCaDjYYw
 t2tHMDle8l/fwOVYEXhlm0QJFq13iUwpwy6kd0gaJ+JweTmSkQ5+jjlVYW68CToZF2Qe+Km7qS
 ikiDtXkF6ux7NR5t4tLr48DkuIv3sv1okJGyKmksuLgWLuSvP+nbDufMztPu+fwFG8ZpatAAAA
 A==
To: fstests@vger.kernel.org
Cc: Zorro Lang <zlang@kernel.org>, Amir Goldstein <amir73il@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>, Hungyu Lin <dennylin0707@gmail.com>, 
 linux-unionfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794456845; l=3221;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=h8S3ePG03hCpC7eOjyZ1Cd5PwA2U9TzZrinNmJROrFY=;
 b=1iC8l7OV8nYQDnwtoE2Xryl2nyxJ2hX5ImPy9Hh6ebm0wARAKJRO11b8mSbeC7uWYnYEJJMeZ
 qTn8i/hDMpOBmGbDsS+s/PVzbwXnnFTmd1MZ8bfQRqV2uoGEohEdQSf
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

overlay/077 fails on ext4 with some directory hash seeds:

    entry o100 has inconsistent d_ino (131181 != 524491)

ext4 returns the entry that did not fit in a getdents buffer first in
the next call, even if it was unlinked in between. In an impure dir
overlayfs lists that stale entry with the upper inode number. POSIX
leaves it unspecified whether readdir() returns such an entry.

Do not check d_ino of that entry.

Reported-by: Hungyu Lin <dennylin0707@gmail.com>
Closes: https://lore.kernel.org/linux-unionfs/CAGEkeHcg06kHshHQ=9U6Yrs_wm8W9H28o9bcC2Qh3fw3tANbWA@mail.gmail.com/
Suggested-by: Amir Goldstein <amir73il@gmail.com>
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
On v7.4-rc2 with ext4, overlay/077 failed on hash seeds ...88bf,
...8863 and ...886e and passes now (3 runs each). generic/257 and
generic/637 pass on ext4 and on overlay. With the stale entry mark of
commit 9011c2791e63 removed, overlay/077 still reports m100 or f100 on
ext4 (seeds ...8812, ...884a, ...88bf and a random one) and on xfs.

Changes in v2:
- New subject. v1 was "overlay/077: check a stale entry in an impure
  dir on any hash seed".
- Dropped the "-" and "=" cases and the second impure dir.
- Relaxed the d_ino check instead (Amir), but only for the first
  entry of the first call after the unlink, where ext4 returns the
  stale entry. Relaxing the first entry of every buffer hid the
  regression that 9011c2791e63 fixed on some hash seeds.
- This no longer waits for a kernel change.
---
 src/t_dir_offset2.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/src/t_dir_offset2.c b/src/t_dir_offset2.c
index 026bc8f3..a6091f7a 100644
--- a/src/t_dir_offset2.c
+++ b/src/t_dir_offset2.c
@@ -46,6 +46,7 @@ int main(int argc, char *argv[])
 	struct linux_dirent64 *d;
 	struct stat st = {};
 	int bpos, total, i;
+	int ncalls = 0;
 	off_t lret;
 	int retval = EXIT_SUCCESS;
 	const char *filename = NULL;
@@ -96,6 +97,7 @@ int main(int argc, char *argv[])
 			perror("getdents");
 			exit(EXIT_FAILURE);
 		}
+		ncalls++;
 
 		if (modify && fd2 < 0 && total == 0) {
 			printf("getdents at offset 0 returned %d bytes\n", nread);
@@ -165,7 +167,18 @@ int main(int argc, char *argv[])
 					       (long long int)d->d_off);
 				if (!strcmp(filename, d->d_name)) {
 					found = 1;
-					if (st.st_ino && d->d_ino != st.st_ino) {
+					/*
+					 * The file is unlinked after the first
+					 * call. A filesystem may still return
+					 * the entry that did not fit in that
+					 * buffer first in the second call. In
+					 * an impure dir overlayfs lists such a
+					 * stale entry with the upper inode
+					 * number, not the st_ino seen before.
+					 * Skip the check for that one entry.
+					 */
+					if (st.st_ino && d->d_ino != st.st_ino &&
+					    (exists || bpos || ncalls != 2)) {
 						fprintf(stderr, "entry %s has inconsistent d_ino (%lld != %lld)\n",
 								filename,
 								(long long int)d->d_ino,

---
base-commit: 71641219a506ac62bfa231592394265ca812670e
change-id: 20261110-ovl077-stale-next-af1a98ce7151

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

