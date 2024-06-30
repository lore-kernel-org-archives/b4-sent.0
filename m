From: Daniel Gomez <da.gomez@samsung.com>
Date: Sun, 30 Jun 2024 23:52:41 +0200
Subject: [PATCH v2 2/5] common/rc: add recreation support for tmpfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240630-common-fixes-v2-2-16d26fb1dee0@samsung.com>
References: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
In-Reply-To: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=514;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=NED506XPkdb3zAZGDWJkQ1ARWG9uUpz/0FpeqV97NdA=;
 b=aPBqOoxZ6flCITUcxmd7dJJFfjq+wEpbQWzMi6IVc43UoJuYHYFA4+rK8mSvyu2cmGTpvEncF
 w7gyh1pe+DTAq7eSG/9kXn22939pMx6eryhPQtv8MLqIo4Mx7WQr9G7
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for test device recreation (RECREATE_TEST_DEV=true) for
tmpfs.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 common/rc | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/common/rc b/common/rc
index 163041fea..51827119c 100644
--- a/common/rc
+++ b/common/rc
@@ -604,6 +604,9 @@ _test_mkfs()
     pvfs2)
 	# do nothing for pvfs2
 	;;
+	tmpfs)
+	# do nothing for tmpfs
+	;;
     udf)
         $MKFS_UDF_PROG $MKFS_OPTIONS $* $TEST_DEV > /dev/null
 	;;

-- 
2.43.0

