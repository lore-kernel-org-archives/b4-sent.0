From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:12:24 +0800
Subject: [PATCH v5.4-v4.19 5/6] stat: use vfs_empty_path() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-4-y-v1-5-8a771c9bbe5f@gmail.com>
References: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1081;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=lbbjfwVQwhBMaQKhLfEbF06OhcMU5I+9P48PRWXjV58=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t/duEd97bWZSZWYr+0maaRO+Z57/o0I255hw
 /Y1wn2K5xyJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurf3QAKCRCwMePKe/7Z
 blEwEAC2CZBFiARpq0BzXdbsmeSaU+++3T5LIlILiPQILqslb3Sd+tbvA8YUxRClYEU2lR1J8bu
 9O8+qcWfYXacbT1Lw+n3Vp7/66c65DG1vmPCoATC708HjRZCnn7qjgNIF3VItPEhEPIguAtHi/f
 UjUtlk/6KWijVnA/XpK9JrgHIFz/9pf1zehNZa+Plu88S84Wd4PUCO3e95ZxB6c7cHQE6HOjTds
 rUjO7q2MNWAmfc2AwWmxqtg5ZNVHPSp2jWmGTC/M9apZ/KNH7ahbuJn+W91piZW2GvVSuDXM61b
 NHAMpje2zaB+f2sHmqgsTG7QxFzINMq8cp4wB2W1QRPY/hoEVNoLbX18wzp6EjMAytQtEjsHyWW
 nLtBO8duQmz1Br0otDUNMJa6YZHHSy3EW51kByUOVWs3JA4kJ0yY7gzBtaQ2MtSn4X0vUCaF05D
 hou5nPJ5KmDiTtlfweaRVQbr2FA6qlbuW8rFwpHvoY1QTXu6axlMnIUfD45f6gwCLK3Dmcj2P1D
 3h/4ui+c+jbw58YgMy+j4d5u5F85XjGMXTXefUMnjunFI6cn2w5llp77i1vOjzSgKaiV9bnouQe
 2zbCIBOcG6xxRo2yWx034hPaRxHjtUBWe9/ETB46yjHmjTvy6U22A9EYYNuiUT+07fF4EhlyhOC
 sMM7S/UMDdINJWw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Christian Brauner <brauner@kernel.org>

commit 27a2d0c upstream.

Use the newly added helper for this.

Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 4.19.x-5.4.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 11 ++---------
 1 file changed, 2 insertions(+), 9 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index 3ae958308e48..1aaa5d847db8 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -224,16 +224,9 @@ int vfs_fstatat(int dfd, const char __user *filename,
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

