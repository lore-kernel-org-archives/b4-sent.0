From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:03:57 +0800
Subject: [PATCH v6.1 1/5] vfs: mostly undo glibc turning 'fstat()' into
 'fstatat(AT_EMPTY_PATH)'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-1-y-v1-1-364a92b1a34f@gmail.com>
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
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2860;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=QpOtGBrgeHzWDdE6/MS31uJ7mQXSVII/5YAq8cJFDr8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t3UddGKj9ZZ0KoV0I1aG51iFs0byEjDnboI/
 0RA5uvyvt6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurd1AAKCRCwMePKe/7Z
 bhdLD/0QLtqm0+gUFBQTySw8bIBIaMwAJ2y/zoMcZksCGXJ7vwdYmU/pR0FFUOZEuZGrR6B5m8z
 Sj0V+pvLsGOficEjIYUs+eBa5FB0wGcGoC+CK/84NyU6cuZ0CryqMdYj8VXlWKHs7kllOTxUSmo
 eNOGkrBXBMwKi+6mNKdxrqK85YDHu/9EOyio0wS5qdSxDiofYMNg/EWpZ6TO6tNHHd0qF6/X2ls
 8Y/6h4fE7bGO+dZUcquNaTGq/yRqRbijDqPqdYhLG/MsB9YodL2k5zvrd4uDqEO+TrhPfQ3Sn9l
 Kw2u2SBIJ6QUOjNM8/9MMiho7qP/0F32XjZScmmfhq3qHyed+TjMc45mSaFBZLW6keWjKwXWzj6
 QlnxJRieXYQe575Eke0ZiBH5RGQaDpRmhADqwzWuIvEC1ySNnOg+BSDDisogzLzSRDfScYKtmLI
 aOn15uBPCh+QPzCh5/ZnyI4XvziE6gEWkvaWqWRINmHK4OAQOjvbN+gMV4iTh7LL84NArQG9wJB
 6nthGTI6lIn2eSA2AVo6PlMj45P9YLIqT48KnXiUtBhGc2K8N27mzMvT7YqZZw6E/SLkkd3dWsA
 GFPx8+qE/m7KHPiyQoiXMdSVdX4XlaeW4nAy5AXa92SOksyfOBC9G2HpqtkciBQzG/fiOzkP/wA
 iS8qLKiDMgKCx7A==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Linus Torvalds <torvalds@linux-foundation.org>

commit 9013c51 upstream.

Mateusz reports that glibc turns 'fstat()' calls into 'fstatat()', and
that seems to have been going on for quite a long time due to glibc
having tried to simplify its stat logic into just one point.

This turns out to cause completely unnecessary overhead, where we then
go off and allocate the kernel side pathname, and actually look up the
empty path.  Sure, our path lookup is quite optimized, but it still
causes a fair bit of allocation overhead and a couple of completely
unnecessary rounds of lockref accesses etc.

This is all hopefully getting fixed in user space, and there is a patch
floating around for just having glibc use the native fstat() system
call.  But even with the current situation we can at least improve on
things by catching the situation and short-circuiting it.

Note that this is still measurably slower than just a plain 'fstat()',
since just checking that the filename is actually empty is somewhat
expensive due to inevitable user space access overhead from the kernel
(ie verifying pointers, and SMAP on x86).  But it's still quite a bit
faster than actually looking up the path for real.

To quote numers from Mateusz:
 "Sapphire Rapids, will-it-scale, ops/s

  stock fstat	5088199
  patched fstat	7625244	(+49%)
  real fstat	8540383	(+67% / +12%)"

where that 'stock fstat' is the glibc translation of fstat into
fstatat() with an empty path, the 'patched fstat' is with this short
circuiting of the path lookup, and the 'real fstat' is the actual native
fstat() system call with none of this overhead.

Link: https://lore.kernel.org/lkml/20230903204858.lv7i3kqvw6eamhgz@f/
Reported-by: Mateusz Guzik <mjguzik@gmail.com>
Signed-off-by: Linus Torvalds <torvalds@linux-foundation.org>

Cc: <stable@vger.kernel.org> # 6.1.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/fs/stat.c b/fs/stat.c
index ef50573c72a2..5843f73f3e7e 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -263,6 +263,23 @@ int vfs_fstatat(int dfd, const char __user *filename,
 	int statx_flags = flags | AT_NO_AUTOMOUNT;
 	struct filename *name;
 
+	/*
+	 * Work around glibc turning fstat() into fstatat(AT_EMPTY_PATH)
+	 *
+	 * If AT_EMPTY_PATH is set, we expect the common case to be that
+	 * empty path, and avoid doing all the extra pathname work.
+	 */
+	if (dfd >= 0 && flags == AT_EMPTY_PATH) {
+		char c;
+
+		ret = get_user(c, filename);
+		if (unlikely(ret))
+			return ret;
+
+		if (likely(!c))
+			return vfs_fstat(dfd, stat);
+	}
+
 	name = getname_flags(filename, getname_statx_lookup_flags(statx_flags), NULL);
 	ret = vfs_statx(dfd, name, statx_flags, stat, STATX_BASIC_STATS);
 	putname(name);

-- 
2.43.0

