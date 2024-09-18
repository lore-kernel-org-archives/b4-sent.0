From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:10:38 +0800
Subject: [PATCH v5.15-v5.10 2/4] fs: new helper vfs_empty_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-15-y-v1-2-5afb4401ddbe@gmail.com>
References: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1116;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=NNdeRdWR8oQ0NFsZXKcLndO0clVTPZKHtPgFAjQVi/A=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t9opLBl8Es3PPOAB3sh2DYnhurwkAcr8xbwd
 t0+ZmqsmmmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurfaAAKCRCwMePKe/7Z
 bvZ/EACAsFifV4qsXKY44jmfyBeldyhGFRY5pwuMVHhdpCD6pudl286QKaFGcDxkhzx7XiDAF4m
 CxbYmME9OJ1WDbCcOWD4lIb3I/CIs7TO5MqfeChlVHE8Kusfegcj3TCJSVwOF3OWzNU7k7XhmpL
 NGNomlTBfjZfPFugUK88w66K6p64sHHs5XseQuLiIBcMg1X9NRbZ2ptYtNE/PSMflPZxOthJCua
 eRAr5bjrauavi7XFby692T4B3w7IhViG1fQLGU9lZBWLdVe47A/bH+gnc5eMVAofuDfsBS5OESD
 4VVRMQgt34Ws7IpRzrLc4aIHjetYl3348QjFD701IAUXLo9CDB4J4Ft0XKSMmjCIG1CZWWjEOKI
 b0IUt3V3JYykbK6po+qieno6bGCKAYtuhvKPyi+EW8zlm6sw9rQJmVrvhBrvfnv6yPAfG7faXsv
 Wwmriw34HtjMNaH4PONAzS6DBEi5gHI43nzsMOWcA1dolPn0/8VmHB3ch70aQro0VQQypIL5wa/
 ToLyiobwgGQEkDZdw1017gnyp77Do0zPnNu3AXw+9LUfz+Md53cc4MrBhkwn9cTrFR2TqEoWcKV
 p7eZ/cykC79iVs0B/1EACEpAFiGyZgR51cbNPMSWdy0TYWM99M7SrNjfWlhP8/aHf6v7bTGhXay
 KnBkJZWU31EDtRg==
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

Cc: <stable@vger.kernel.org> # 5.10.x-5.15.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/fs.h | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/include/linux/fs.h b/include/linux/fs.h
index 27da89d0ed5a..6fe2ae89bba6 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -3736,4 +3736,21 @@ static inline int inode_drain_writes(struct inode *inode)
 	return filemap_write_and_wait(inode->i_mapping);
 }
 
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

