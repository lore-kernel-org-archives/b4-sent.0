From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH 0/4] fuse: Fix several io-uring race conditions
Date: Mon, 18 May 2026 18:37:28 +0200
Message-Id: <20260518-fuse-io-uring-race-fixes-v1-0-36c9eba8ab18@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2LSQqAMAwAv1JyNlCL+1fEQ9GouVRJqAji3w0eZ
 4Z5QEmYFAb3gNDFykcyKAsH8x7TRsiLMQQfGl+XHa5ZzR2YhdOGEmfClW9SrPu28VXwS4gEtp9
 Cf7B7nN73A69LtUZqAAAA
X-Change-ID: 20260518-fuse-io-uring-race-fixes-59760420d2ae
To: security@kernel.org, Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org, xlabai <xlabai@tencent.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1157; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=h/KF1TqMRvuy4P4rPpT3qqO89Nwq5jpTLdk3RhsWkKs=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLK4HfxyORjPvZh56QsPo8jam+GvX60388++aD9dYYlWw
 NMFpY6nOkpZGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAiU3wZ/ifd3Llnsf2U21Ov
 zjijHKl/+j1Hsub0yiVfFd4bzzydu6OL4Z/lidNZyqZW9z5vu/efWUv7xRWhJ6Gc0/7MUDhWpzm
 Xfz47AA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is to fix race conditions reported by Berkant and Zhenghang.

So far not well tested yet, update about that will follow tomorrow.

To: security@kernel.org
To: Pavel Begunkov <asml.silence@gmail.com>
To: Luis Henriques <luis@igalia.com>
To: Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>
Cc: Berkant Koc <me@berkoc.com>
Cc: Zhenghang Xiao <kipreyyy@gmail.com>
Cc: Joanne Koong <joannelkoong@gmail.com>

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Bernd Schubert (3):
      fuse: Avoid use-after-free in fuse_uring_async_stop_queues
      fuse: Avoid queue->stopped races and set/read that value under lock
      fuse: {io-uring} Make a fuse_req on SQE commit only findable after memcpy

Zhenghang Xiao (1):
      fuse: clear ent->fuse_req in commit_fetch error path to prevent UAF

 fs/fuse/dev_uring.c | 48 +++++++++++++++++++++++++++++++-----------------
 1 file changed, 31 insertions(+), 17 deletions(-)
---
base-commit: 040d71ac647099f7bb5e480fcd74ba68abc3cb18
change-id: 20260518-fuse-io-uring-race-fixes-59760420d2ae

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

