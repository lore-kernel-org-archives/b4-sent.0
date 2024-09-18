From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:10:37 +0800
Subject: [PATCH v5.15-v5.10 1/4] vfs: mostly undo glibc turning 'fstat()'
 into 'fstatat(AT_EMPTY_PATH)'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-15-y-v1-1-5afb4401ddbe@gmail.com>
References: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2834;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=shkXBk+gnzTIPbC7R2tboulSE67SGBTGhMLzTghvzw8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t9oZdUD+fMtZyQknzM2S2xZgTNBVpkCHtZ+Q
 fSp0U4g5NOJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurfaAAKCRCwMePKe/7Z
 bhyZD/9ArmkkoE+BhMIr5PdZk1Or/Jt3JiCI4dy/eyIMnFtlx1f2V7HTvzahJ8iQ/Lg/Twc8Mdp
 80zqxSJgmUgfStce539KCLS7CTNKfdSfZ/eJCxwbA1l+Pe04MXt/LdhDxciqRp+yksv/PSMsgoP
 lf2VF2XOHjSinhIdyx5vd7FyLsHYSufgxV2S5+g3WLScx1mGWiqzR+gfzFAA+dDrkw/DtEYYzGQ
 PwkyStOG+S3GLbHxOxiumeAYyM05jwLnA7EFTInEPlfUTrjjL3aA2ehbBE/yeqtRaiuh8X86vCT
 zbOSJ745nS4LAiDF68uMu2VU1K/gn0scxmV7ON7qnzAPmomhsEaPictBlCyHpfjFILbITHlZTvb
 Rxvgqys781+l2J8T+7e6P1CineXHfYQAkIJq0atq+MVlk7qvA5edeyoucyc0y4cRIQBBVrLOtH6
 sJZq0A+k4jwHRy0+H889eDbDiUT5bm35W2jdoJ2PVF/z6gPEVngnUfx7avzPXJEXR0aZL8KQ5Qd
 PSx0PpinuE99O4QAkeb10TMXNFz5mkexEiRgiR0r5eZ5+ChlBB5fdZZ9muxq4iT2vojUXr2IGn+
 QJeNclB7Jcxh5BBxyXcRHG/0mRHl93Rdt68p1yZmSi9x3LskINSOSYSGEPhAEU2rPKH5UEbmBv/
 GDlMb2VRDdh01ag==
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

Cc: <stable@vger.kernel.org> # 5.10.x-5.15.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/fs/stat.c b/fs/stat.c
index 246d138ec066..9669f3268286 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -240,6 +240,22 @@ static int vfs_statx(int dfd, const char __user *filename, int flags,
 int vfs_fstatat(int dfd, const char __user *filename,
 			      struct kstat *stat, int flags)
 {
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
 	return vfs_statx(dfd, filename, flags | AT_NO_AUTOMOUNT,
 			 stat, STATX_BASIC_STATS);
 }

-- 
2.43.0

