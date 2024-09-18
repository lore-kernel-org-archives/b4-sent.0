From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:12:20 +0800
Subject: [PATCH v5.4-v4.19 1/6] fs: implement vfs_stat and vfs_lstat in
 terms of vfs_fstatat
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-4-y-v1-1-8a771c9bbe5f@gmail.com>
References: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Christoph Hellwig <hch@lst.de>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1917;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=CQCVg6bGtOP7dyIJeUlTzT0EMwWixKIfeNRTX+C5op0=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t/dN6H2v5zhZ+VZu7qHixmznKxNo+3Rk1z6P
 MeyL1nJkueJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurf3QAKCRCwMePKe/7Z
 bnotEACicVudyiCwiXPeNPSwGr7S4Ztlm5l8+E5WotWOBHH5e0d5rrkI1IelGuDBBfhhyCbYz0t
 HgmGj3EtwPIuA3KXS5hKhVnncohkyujzu3s7++7GWQBdAAbYZxqnua3ptUx5Nynf13+9Hr2xCbk
 eRYyvnXqVED+TubKqcC+TrlwDy4t63C+pMC5woVgZEh/voFNabz/iCKwaNy35AmsSds+guma01G
 qpkwjRtvy8/HKg6TutXvwz8UJKCTtLq1p3JPD8QS+ztW7kvxz6WyqL7HurZGhn0MHjc63ftA4EY
 OAnTA+fmPsYrX2HzYxduBYuP+1F4ZyRruTilheJFDWjJ+uKNAfFbo3XyRuyYQDHcf098hAdMjkO
 eRnlTJm5RkHxbu6vdnPlljNKHp2I0/OsqmPwk7KVWgP8/X3ZrDAMg7Sqa+mvJxanGscjujSPphH
 xYbGXc5Gtcc1zdPWHjvfZH24x+ooNeKMH0Tf9LkRnv2G2BvQEaB4sJp1ECWWuG1GNdwLhf4s0uu
 SI1phaQB7NwHGc1cBARomx9Rs7NPp/e86l8ajhbCLy6kPMDvbsZxJ0yKvYP7P+sEqnVrI/f9MYL
 FFJgLw7y403UUtsRbhWPVfTjdsNQJy/tuT+9O6+MAUIAyA17Q7MP4T8EN4vUalmz80yBFRNq8Lc
 ZfnlJfEosGcs1yg==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christoph Hellwig <hch@lst.de>

commit 0b2c669 upstream.

Go through vfs_fstatat instead of duplicating the *stat to statx mapping
three times.

Signed-off-by: Christoph Hellwig <hch@lst.de>
Signed-off-by: Al Viro <viro@zeniv.linux.org.uk>

Cc: <stable@vger.kernel.org> # 4.19.x-5.4.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/fs.h | 18 ++++++++----------
 1 file changed, 8 insertions(+), 10 deletions(-)

diff --git a/include/linux/fs.h b/include/linux/fs.h
index d4f5fcc60744..2db4e5f7d00b 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -3262,16 +3262,6 @@ extern int iterate_dir(struct file *, struct dir_context *);
 extern int vfs_statx(int, const char __user *, int, struct kstat *, u32);
 extern int vfs_statx_fd(unsigned int, struct kstat *, u32, unsigned int);
 
-static inline int vfs_stat(const char __user *filename, struct kstat *stat)
-{
-	return vfs_statx(AT_FDCWD, filename, AT_NO_AUTOMOUNT,
-			 stat, STATX_BASIC_STATS);
-}
-static inline int vfs_lstat(const char __user *name, struct kstat *stat)
-{
-	return vfs_statx(AT_FDCWD, name, AT_SYMLINK_NOFOLLOW | AT_NO_AUTOMOUNT,
-			 stat, STATX_BASIC_STATS);
-}
 static inline int vfs_fstatat(int dfd, const char __user *filename,
 			      struct kstat *stat, int flags)
 {
@@ -3283,6 +3273,14 @@ static inline int vfs_fstat(int fd, struct kstat *stat)
 	return vfs_statx_fd(fd, stat, STATX_BASIC_STATS, 0);
 }
 
+static inline int vfs_stat(const char __user *filename, struct kstat *stat)
+{
+	return vfs_fstatat(AT_FDCWD, filename, stat, 0);
+}
+static inline int vfs_lstat(const char __user *name, struct kstat *stat)
+{
+	return vfs_fstatat(AT_FDCWD, name, stat, AT_SYMLINK_NOFOLLOW);
+}
 
 extern const char *vfs_get_link(struct dentry *, struct delayed_call *);
 extern int vfs_readlink(struct dentry *, char __user *, int);

-- 
2.43.0

