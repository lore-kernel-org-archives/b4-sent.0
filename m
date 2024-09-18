From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:02:51 +0800
Subject: [PATCH v6.6 2/4] fs: new helper vfs_empty_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-6-y-v1-2-8731db3f4834@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1159;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=VS5qjZw+FoCkeKMb8vRJXj6g0W3ph2xyDi9Yx9IY3/Y=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t2MkDYa4zKzhXM4cv44fH3GZUJ7zL+k1ZJTG
 FcjcXbSQ56JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdjAAKCRCwMePKe/7Z
 bsB3EACH8lqyWASnYUFET/ssBY6eCT0d5Fm74SMPgJHa0wnNjb6kjExBi96CycF3kQ6TgSValKa
 bUeJ8ONhcKtoZWJ5wicTSzJu+RDRWBvTEv7emsDS7a0DzIBJA3KqE/ddbIdPWt2a8EMqkaT396O
 20iDaa4o+Qd6d0kwaTSHKTG2Z5zAzo2NkCV63zoSTGlaIrODT9Pt4pGDDquPB7erygjXFbnxw4l
 YL6OoGgfGaVc8rLWQzFR3Loj9djB+I4ud+jS553uWZOIxQFyKXiTRB4DqilXwWU83GPNXLnqh9r
 uF9C55oS0i97OsCD2vKO273tzgogGeFNW3V2EYzVkgp/+lnCJNl4dY2hxYSq3zrf6Djnn0B9c4l
 mgLO093mX5UH6VkWrPk++P29odnSmxoLpA7o2aY3sqwfJz64OU5h4yIeRKSMBbih4g7kG6v/JkF
 9EeXOcJUDYg3E3zBXB/g3IrD1R8MwDO4lr1igmD4/V1JuCx7tGcsnWfyax+pgaYE2deCt5NBQVw
 DbVXIJN6gt52VsqTdjCJBS7xeMPDBwqZiIczvUtQ2D6iQvm0JJ8UA1u8qeIGXqnuvsQ+JguuXBJ
 olfrfO5WdhsQpwJ4ezkql3syEYoKJ8Ns7HzlhUtfQxBL6749ni22rFlfvOEq4/VqqskKHB1KD//
 tk1Vt8JCzjLIVUw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 1bc6d44 upstream.

Make it possible to quickly check whether AT_EMPTY_PATH is valid.
Note, after some discussion we decided to also allow NULL to be passed
instead of requiring the empty string.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.6.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/fs.h | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/include/linux/fs.h b/include/linux/fs.h
index 2a554e4045a9..809b354dbddf 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -3454,4 +3454,21 @@ extern int vfs_fadvise(struct file *file, loff_t offset, loff_t len,
 extern int generic_fadvise(struct file *file, loff_t offset, loff_t len,
 			   int advice);
 
+static inline bool vfs_empty_path(int dfd, const char __user *path)
+{
+	char c;
+
+	if (dfd < 0)
+		return false;
+
+	/* We now allow NULL to be used for empty path. */
+	if (!path)
+		return true;
+
+	if (unlikely(get_user(c, path)))
+		return false;
+
+	return !c;
+}
+
 #endif /* _LINUX_FS_H */

-- 
2.43.0

