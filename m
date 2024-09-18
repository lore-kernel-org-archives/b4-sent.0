From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:04:00 +0800
Subject: [PATCH v6.1 4/5] stat: use vfs_empty_path() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-1-y-v1-4-364a92b1a34f@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1134;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=EyK7W+gaJlP6MleyB5ZjKTARugVXi3q5zqg6t2IMwYA=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t3UA16TVWzKRj2vwZhvWwWXDEwc8cMv2Vnor
 H0Q3LLdFt2JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurd1AAKCRCwMePKe/7Z
 bt5XEACvtr9AChpWdRZ4S+fMpV948LQLs6ho9P0GCSxsbIhh/yMv4uKWPaOsjbJgAO6jF/1g3/h
 ggrpDoinfS6Yd23t6RZHh2JTIPGO32DAskMfYV5v7H9Mg3WQKHz0DPX1R6Klb/ZtSWeExZb0aJj
 Ad9RmPPEExpGTW2E7c4UgRH3iKu9L3qCP/dhaa/KdXGkBDpROM4zK/rsWY75vleFXxjOM92cdBI
 uQLl6B6stR07Dc0Ekb2xuX2gMTCL/tBmyhTQEVQp6IWhtDqrYF96iezjbIvqXbE/D/h+Dfjbd2M
 4QadIVQDorgk9zqOTG8sWEdYBQ1lKcWTo3erHmvdnV+1CncS7zkGmBxFSv3ta6faOsUg1cqyWGr
 fpkeb3yr0CbkafkPxkAAk/xhjez4RITOdtCHQ4//2LrcULNr4Cd+nk+uika39e/eVc2gO/x/x22
 ZkXQVwNOtmReAe7cX2SVdK31p5Xe+VcaXPl0APelK11Nhfna1H/Ung0+DIsx7qic7tFnaZ6A5EG
 xQPPIGCZ8n7reYS8FCncsHAZ7FGFNya3obdMP2YbK3a5saJDcTGEqZ6azo3B2SWxQngCxJzx8n8
 1pTAUwPTGlfeQXLdf4WRulFrV+GAC91iprMpIirhmXJlNUalXbpdR/HJKcJ6M9A4544mkq+BFDC
 WfkuDaM0DezTySw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 27a2d0c upstream.

Use the newly added helper for this.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.1.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 12 ++----------
 1 file changed, 2 insertions(+), 10 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index 5843f73f3e7e..84e07356dfa4 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -269,16 +269,8 @@ int vfs_fstatat(int dfd, const char __user *filename,
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

