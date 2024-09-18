From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:03:58 +0800
Subject: [PATCH v6.1 2/5] file: add fd_raw cleanup class
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-1-y-v1-2-364a92b1a34f@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=931;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=XON4BDwsa+hxqLqygmHBBmblYX/h+QaejNN2ENhk19I=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t3U76r3DAs4+64W5q44SmnJ3oIBH9Z93C5/K
 O3aQCe5aSqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurd1AAKCRCwMePKe/7Z
 bvCjD/9epvrQt6tb9IUFFm7WcZOUDhRve8+gcdsnluBNl4dHkmFTNnBeJQ+w7DX2FOTr7s+q9sL
 G6a3qiC3O7tFdAYVlhJsQCPPz9/5dnGmrJdmT3BLwL+LhzWkDAP9BsQWBTyfm8ff/RBU1CBCkTA
 iI+t+RQ9wUVTYuhCB/8DJFNpSzlnMkY9TE004A7580QfRFke0W9QVDWouu6ImbTsUrFmbPGcUai
 B0U+J7l9XVJTQLydY4tutahsrj4b5aW7ptMNJb98z7KGMxIBBNwu4To0NEz5bom+x6umb8lVFe0
 wIARqSLR9tI6RgqPbGAjyfxgn2SPM/np3jAwm/kTIQG/RX9Tm28KJAZDns88ou4nD1nPIhZmS0Q
 7agpEe0epzKcgexef91C06+TQh7pSLYLYDvtYqzaUFYu1YQd1L/2svV5ZA2p5Pdwo3bL95gEqRQ
 8kJfBrQJwHT0CIpowRu4Wf/9L3Bc4Tx/spnBz9z2eTUwbFtyzo9rpNgqovsoMSwC63CZeikgs6Z
 Ju81+6CiSugskx6qwjxv4uqq/qnKURlyzNWUa1iuqWhxQ98ScmOylCFjbXaYda0yqu1CgPsUTj4
 8g5BBCnYGqQDIo6GqVCRsJqGeyXKXTBWU5LpURmAaWyHsrZ2lnyfnqgwhGb95CKLRrVChVTSdMo
 DJTuxAhvgoirB1g==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit a0fde7e upstream.

So we can also use CLASS(fd_raw, f)(fd) for codepaths where we allow
FMODE_PATH aka O_PATH file descriptors to be used.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.1.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 include/linux/file.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/file.h b/include/linux/file.h
index 6e9099d29343..963df2dc4f61 100644
--- a/include/linux/file.h
+++ b/include/linux/file.h
@@ -82,6 +82,7 @@ static inline void fdput_pos(struct fd f)
 }
 
 DEFINE_CLASS(fd, struct fd, fdput(_T), fdget(fd), int fd)
+DEFINE_CLASS(fd_raw, struct fd, fdput(_T), fdget_raw(fd), int fd)
 
 extern int f_dupfd(unsigned int from, struct file *file, unsigned flags);
 extern int replace_fd(unsigned fd, struct file *file, unsigned flags);

-- 
2.43.0

