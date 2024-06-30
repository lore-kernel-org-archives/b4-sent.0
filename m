From: Daniel Gomez <da.gomez@samsung.com>
Date: Sun, 30 Jun 2024 23:52:40 +0200
Subject: [PATCH v2 1/5] common/config: fix RECREATE_TEST_DEV initialization
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240630-common-fixes-v2-1-16d26fb1dee0@samsung.com>
References: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
In-Reply-To: <20240630-common-fixes-v2-0-16d26fb1dee0@samsung.com>
To: fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Zorro Lang <zlang@redhat.com>, 
 mcgrof@kernel.org, gost.dev@samsung.com, 
 Samsung Samsung <"Daniel Gomez d+samsung"@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719784382; l=996;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=CZBncsstQuBprsTkh+ba7qAwTYuluS865arve8XzUjg=;
 b=x0nrkTnmEGQsXr88t+voL8wIX+aZVsb4Z6MqR8eeX++5XJfaL9vK86soHVvdp7dlM96TyD3B+
 lE2yZztDPUhD2VhVioh/UVSZTNDeL71HWiIO3TrLFCFB9KOrnHQij1+
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Do not allow the overwriting of the RECREATE_TEST_DEV variable. When
this variable is enabled, common/rc -> common/config will reset it
to false after the test device recreation process. This allows for
differentiation in mount options for SCRATCH and TEST.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
Reviewed-by: Darrick J. Wong <djwong@kernel.org>
Reviewed-by: Zorro Lang <zlang@redhat.com>
---
 common/config | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/common/config b/common/config
index a1cd14de6..43b32b93d 100644
--- a/common/config
+++ b/common/config
@@ -94,7 +94,7 @@ export PWD=`pwd`
 export MALLOCLIB=${MALLOCLIB:=/usr/lib/libefence.a}
 export LOCAL_CONFIGURE_OPTIONS=${LOCAL_CONFIGURE_OPTIONS:=--enable-readline=yes}
 
-export RECREATE_TEST_DEV=false
+export RECREATE_TEST_DEV=${RECREATE_TEST_DEV:=false}
 
 # Handle mkfs.$fstyp which does (or does not) require -f to overwrite
 set_mkfs_prog_path_with_opts()

-- 
2.43.0

