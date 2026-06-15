From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 15 Jun 2026 14:07:19 +0200
Subject: [PATCH 2/2] fuse: read fch->ring under fch->lock in
 fuse_uring_create()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260615-fix-7-2-next-v1-2-0a4c3908f13c@bsbernd.com>
References: <20260615-fix-7-2-next-v1-0-0a4c3908f13c@bsbernd.com>
In-Reply-To: <20260615-fix-7-2-next-v1-0-0a4c3908f13c@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1021; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=3hEUA5awiqvo0JJwcXM8kQp2TxGP6Af0S0ppwcEAk9s=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL0X/1QM/Gsv1Mky7fteu8RK3MOjSKJXRnz7yl+0GVTj
 Xl0IvBERykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEzE14aRYU+T+qV40aXe6a9i
 w2VMV+76YbN6cm1kjefeC2UKmpIJfAz/y5/+v/aKtYxz/aqoXeoTZGuuHdz57drtFYdcAla/iNn
 2hxMA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the race branch of fuse_uring_create() - another thread already created
the ring - fch->lock was dropped before fch->ring was read into res and
returned.  That read is safe, since the existence check guarding the branch
runs under fch->lock and is therefore already ordered against the
smp_store_release() publish, but doing it after unlock makes it look like
an unsynchronized lockless load and invites an unnecessary barrier.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 230177cc06c6..344e8b5ffb8c 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -260,8 +260,8 @@ static struct fuse_ring *fuse_uring_create(struct fuse_chan *fch)
 	}
 	if (fch->ring) {
 		/* race, another thread created the ring in the meantime */
-		spin_unlock(&fch->lock);
 		res = fch->ring;
+		spin_unlock(&fch->lock);
 		goto out_err;
 	}
 

-- 
2.53.0

