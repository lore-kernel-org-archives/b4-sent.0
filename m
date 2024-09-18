From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:02:52 +0800
Subject: [PATCH v6.6 3/4] stat: use vfs_empty_path() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-6-y-v1-3-8731db3f4834@gmail.com>
References: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>, stable@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1134;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=K5RqzZ4iIsUnBBGo5bPNmkAqQFUQwYdE9U7bJUF7y/c=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t2MDJfW7w/bCninC98+obzVX1a8ggZEW5GAv
 +fI02/VZOSJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdjAAKCRCwMePKe/7Z
 bnjvD/9yZl8ErbKAxJjj4T0H3MsMR70pX9SAqkIS7Z4lefhuyNanGVRxK43WVJxBRQIZUUHCVXc
 F5yTzUFD3jNgzjAL+SwUcrGLENtG72Qz/5YtYA0V/m0hGU0GKnEANgJo0lRfmvCStmnjv4ZQoff
 nqfPTgDy6Ja6qhbfiReKigh5UwpOLglP9JiV3vUkw6bBXF2WQVFzXrdrmc2mkT0B9+jPahw2+D9
 CxYhVSek1nMBRcjORpDMPw6FJsehwcQ5uxn49Y34GrdIYwifhblHZZJ4ePHomzZTgldpubj62jb
 vv7sU5Qws7QC7+7BIPTVqiWhM41A8+jwI8D2ayfd1DvGAn10fEpf2T3ujvaPS7gwdiY2X5eplvK
 ckavrkqxU6G/9aq9qJN940dEjBdYpi8/YUWh7yfLtiqlRFLZCYcLFvrg/ueQtJoKPdDl3l7IoWO
 UDvMf6Xwfe6l5AYjfkSJ8AEAO1LQnev0KcrpW58vYyMbQvZ925sn6JwRdab3rNWS/gi3bCVcW8D
 D0ugxRkVD5EHhwOVXzFLOaMnj7FyLa5cBXwCRWD5OR5aS07iarPQJ4ssWrEUxwRaFj2B7fxLVwL
 lv3yI+UR4C3HoviXoJS6DCdNLp5Sgb8tTVorof/qc3fPZnkYxejDptEYm+Qzm/jAtJoscr1Zt0h
 roDYiD2wXAWE55Q==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 27a2d0c upstream.

Use the newly added helper for this.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.6.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 12 ++----------
 1 file changed, 2 insertions(+), 10 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index 5375be5f97cc..045b2a02de50 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -284,16 +284,8 @@ int vfs_fstatat(int dfd, const char __user *filename,
 	 * If AT_EMPTY_PATH is set, we expect the common case to be that
 	 * empty path, and avoid doing all the extra pathname work.
 	 */
-	if (dfd >= 0 && flags == AT_EMPTY_PATH) {
-		char c;
-
-		ret = get_user(c, filename);
-		if (unlikely(ret))
-			return ret;
-
-		if (likely(!c))
-			return vfs_fstat(dfd, stat);
-	}
+	if (flags == AT_EMPTY_PATH && vfs_empty_path(dfd, filename))
+		return vfs_fstat(dfd, stat);
 
 	name = getname_flags(filename, getname_statx_lookup_flags(statx_flags), NULL);
 	ret = vfs_statx(dfd, name, statx_flags, stat, STATX_BASIC_STATS);

-- 
2.43.0

