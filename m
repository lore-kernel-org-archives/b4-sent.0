From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:10:39 +0800
Subject: [PATCH v5.15-v5.10 3/4] stat: use vfs_empty_path() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-15-y-v1-3-5afb4401ddbe@gmail.com>
References: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1082;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=bCFrxJOZ1JlvAjj2Q1DjyhrDQOgyZ9D8tBLlcgyrtKc=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t9oR0f0W5q/TKDHi8vrrYol5brh4IWMqGm/o
 CrztW+Vov+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurfaAAKCRCwMePKe/7Z
 bjMoD/43wQkEksXRWesOQYsMnncO3tApr7WqjPjqHbkVdYflvX4RqGPyyLaxhy2WyD0s0y/2G/O
 /1P6hAlr6ZK5u/g0aGB6iMmVAI6zxJS+nR+6GP2rd16VpVB1Te+0r++QPtMUg85OgNgYx+HUI5M
 xshcVyMPmb+UXgbZ3FjkvZQ5q99aK7C2fEAHZ9XWvc+VIsO02yYVFDC7XShkwPea96oe9zzBTlJ
 FRifgVefZ0ehZEI0nKzXost8c7xCs3wEHOFs5Kod+9OCdtrqnc9WkItPMME1pzXKWeF0t3cxx+/
 qkS6k1j9+kEuzYt44X2wsvpwkb1CYoyjulmGKoqBEd8LsDrR/o85syu9fRvlD8YhbAqFIift/S5
 BjOM88WQpdkrwyH5TTek7l9rb/AoqTH329CgkF+SLw4YFsvCOsoByzpQEQ1oGY9quajjiYk54Au
 fNlTV1Kwn+aghE0qz96FLBDenXAUE8bhSfrJi7NAfki/DTsHjtNjc0iGv+HcyWQi88F9or5Y9GZ
 Cmdi2pDZf4gAgE5/YpQIYLu7iyS1yuDlaaUkXMwPgVd+EPXynexZYkx90fmBkDkrWc4HNLRrfpc
 sxMKvd70OZ0ZA/YX3KmNhC2GN0zce8TQemlDGW8EdA6/9xVD614cJcrqZIvqrv7CAn/1vOU2JvS
 objHa336Dvmj1pA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 27a2d0c upstream.

Use the newly added helper for this.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 5.10.x-5.15.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 11 ++---------
 1 file changed, 2 insertions(+), 9 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index 9669f3268286..b8faa3f4b046 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -246,16 +246,9 @@ int vfs_fstatat(int dfd, const char __user *filename,
 	 * If AT_EMPTY_PATH is set, we expect the common case to be that
 	 * empty path, and avoid doing all the extra pathname work.
 	 */
-	if (dfd >= 0 && flags == AT_EMPTY_PATH) {
-		char c;
+	if (flags == AT_EMPTY_PATH && vfs_empty_path(dfd, filename))
+		return vfs_fstat(dfd, stat);
 
-		ret = get_user(c, filename);
-		if (unlikely(ret))
-			return ret;
-
-		if (likely(!c))
-			return vfs_fstat(dfd, stat);
-	}
 	return vfs_statx(dfd, filename, flags | AT_NO_AUTOMOUNT,
 			 stat, STATX_BASIC_STATS);
 }

-- 
2.43.0

