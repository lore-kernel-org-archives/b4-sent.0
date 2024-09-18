From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:03:59 +0800
Subject: [PATCH v6.1 3/5] fs: new helper vfs_empty_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-1-y-v1-3-364a92b1a34f@gmail.com>
References: <20240918-statx-stable-linux-6-1-y-v1-0-364a92b1a34f@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-6-1-y-v1-0-364a92b1a34f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1159;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=0Ym6bd1bjrK++KLUiMNu6AnkYMC8fXIq9/WmZjyb8hw=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t3UtvCDlyr3DdCz8bva21nbsM6sK6a7ng16K
 REfgLN6bL+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurd1AAKCRCwMePKe/7Z
 bl2cEADXbrDZCYc22iKd4nqQXj5NqmQD6ytsw8u03ADv+ykcKOdASt+1vLWdyvapup4gccgr+BL
 GoxqvzcCcGbc44ukjEEnQO2PKIkBEwTfBGXkBc/WoeA2Z/9zk+pwtO3DEltP4JuBlOmwlwZIZI8
 eunXKlRuC2GivCwmL+ESIiCRTu+8lUi9vmggx5PFXt0NbEMQxT1bxDI/4hweKUipfIA8355Er/z
 3HwF+c0oHE1Z/iQgc0DNQxYldYSYAo40YjskolLXTAUux0d7bM9z6MtN/fC60Uyk92OVtTlBBpU
 UuV1xllalmrqaIcXnTS++dpN489Ts5dmBiUYpei7OkfNB9Oga3mEbgD1P+hW82e1u0esfAO6n3L
 9m1CopN8qX7GKt/fIgEv5jv0yw/NCkX240fJxntGO74/crD20xoYjRiCJWuZh+6DW0FxsiCeazg
 fPuQYAYapEknHGVgiDrcM1bXd2EmKiM3m/Fo8UbIrkcn2aRrNBRimntboVK7m5pIudeSh6ZmHNe
 BXPrSPtmXNOUC+dQERx9VipGL9k8gszy3HFueGoqZkhbj/Wj1Up23Q4by4jSV63mVA4J1Dlnf7I
 dkWLPoLg3+WV0BLp0t7ZAjsgQbqcASvZ+FdsDGsQZkLvLkvG+0c3sm5BquBA4EW2o7ABQFcAdkR
 lTRrQG3ionsH0tQ==
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

Cc: <stable@vger.kernel.org> # 6.1.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/fs.h | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/include/linux/fs.h b/include/linux/fs.h
index f2206c78755a..deb0abe728a7 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -3692,4 +3692,21 @@ extern int vfs_fadvise(struct file *file, loff_t offset, loff_t len,
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

