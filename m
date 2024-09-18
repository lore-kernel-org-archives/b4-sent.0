From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:12:23 +0800
Subject: [PATCH v5.4-v4.19 4/6] fs: new helper vfs_empty_path()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-4-y-v1-4-8a771c9bbe5f@gmail.com>
References: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1161;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=EYzTtx4WfUuets9SJVOnFqg05Micjvp+v1D6XppGYQY=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t/da9VVbzSOdM+CPOCM6K9MndKp6pQ7ppFDv
 SrJFJsLFQ+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurf3QAKCRCwMePKe/7Z
 bh5QD/9Fx/EnoLO4EloMc7UpLPmUwiStv+abbyt9H8hvmayjroYdsUtm6QwKmdZV6COGzLuhQIR
 7z/UX5cfkwadDwS3HTRcW6v+e3+06bWfVHL2IvAbtvS8N7VwVRq4QpTiouuYpWsZ36WUSYQxyLC
 ybnDWhCIfBbGnnhRzmzfkqL49tjAHeWlIKOSRydPgRyXPl3RHdikWhh2NQFVSiDv/xrJPyIGNo6
 NW4ZHdS4QrU1TS88vGAJZlLRDALikj/13voqcme4A/gHC6RquqxPU1wU4neVZ6X2rzhuWCwG8eQ
 DswVi8ZzDc1fuFjyYr7x/XF4tbeaXD1IdH9vMmjc0otVm2QpNwE4tHI0UQfju8iKpQP6fLVSzST
 4mvl3uiikVzjiChkVT5BPTGrY8QxzB9rz3A9oNjo+fF7xhQCdzVCyjL2Nl0BOZS1t3OksNcwVoz
 655/H0Q09sAacgZIQQH2vHCZoaNIqMHoH7Iyio4iNZN6eUpKXQkUFITCH+TpWh2R00utdXMhU5w
 dizCwz/5uwaCcDgvFHS9pdwb2sXLMIbGFpkr9/xDmQR8KxfgUpTXv9/j9aJFrLTM22T26eX+san
 FmEgQX0AVXExKPNKFHAZpEx2obP6++aA1iluQEwfrBfg/U43oP5m6naHlGvVJp0f/RtEe3ytBEf
 S4FnwM+yQkLHwIw==
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

Cc: <stable@vger.kernel.org> # 4.19.x-5.4.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/fs/stat.c b/fs/stat.c
index 526fa0801cad..3ae958308e48 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -150,6 +150,23 @@ int vfs_statx_fd(unsigned int fd, struct kstat *stat,
 }
 EXPORT_SYMBOL(vfs_statx_fd);
 
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
 /**
  * vfs_statx - Get basic and extra attributes by filename
  * @dfd: A file descriptor representing the base dir for a relative filename

-- 
2.43.0

