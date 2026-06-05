From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH RESEND v3 0/4] fuse: Fix several io-uring race conditions
Date: Sat, 06 Jun 2026 00:13:05 +0200
Message-Id: <20260606-fuse-io-uring-race-fixes-v3-0-6fdf5e5b3437@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Pavel Begunkov <asml.silence@gmail.com>, 
 Luis Henriques <luis@igalia.com>, Joanne Koong <joannelkoong@gmail.com>, 
 fuse-devel@lists.linux.dev
Cc: Miklos Szeredi <mszeredi@redhat.com>, Berkant Koc <me@berkoc.com>, 
 Zhenghang Xiao <kipreyyy@gmail.com>, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org, xlabai <xlabai@tencent.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1630; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=zzcjR3tdjVAc0vSCUYm4sf9kV9JI7lchlMuMEr7MUhQ=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLKUPb+tW3dDuibgg+rBPYsuveMurakXu+uzyeL0sxynT
 Ms/S9KEOkpZGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAi10sY/orkhT8pD70bISOv
 LLyjymwZf22q3ueiX2qu1q5a2e3Wcxn+1+9y/Prr/kqmjn3n8gQSeY7uklzkYHc10+eIcyjftSO
 WnAA=
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is to fix race conditions reported by Berkant and Zhenghang.

So far not well tested yet, update about that will follow tomorrow.

To: fuse-devel.lists.linux.dev
To: Pavel Begunkov <asml.silence@gmail.com>
To: Luis Henriques <luis@igalia.com>
To: Joanne Koong <joannelkoong@gmail.com>
Cc: Miklos Szeredi <mszeredi@redhat.com>
Cc: Berkant Koc <me@berkoc.com>
Cc: Zhenghang Xiao <kipreyyy@gmail.com>
Cc: Joanne Koong <joannelkoong@gmail.com>

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>

Changes in V3:
- Just "Fixes: " and CC: stable... updates and removal of security@kernel.org
  in favour of fuse-devel.lists.linux.dev so that it does not get lost

Changes in v2:
- fuse_uring_add_req_to_ring_ent() needs to re-initialize req->list
  after moving fuse_uring_add_to_pq() from fuse_uring_add_req_to_ring_ent
  to fuse_uring_send in orer to avoid handling fuse requests
  multiple times (Joanne).

---
Bernd Schubert (3):
      fuse: Avoid use-after-free in fuse_uring_async_stop_queues
      fuse: Avoid queue->stopped races and set/read that value under lock
      fuse: {io-uring} Make a fuse_req on SQE commit only findable after memcpy

Zhenghang Xiao (1):
      fuse: clear ent->fuse_req in commit_fetch error path to prevent UAF

 fs/fuse/dev_uring.c | 52 +++++++++++++++++++++++++++++++++++-----------------
 1 file changed, 35 insertions(+), 17 deletions(-)
---
base-commit: 040d71ac647099f7bb5e480fcd74ba68abc3cb18
change-id: 20260518-fuse-io-uring-race-fixes-59760420d2ae

Best regards,
--
Bernd Schubert <bernd@bsbernd.com>
-- 
Bernd Schubert <bernd@bsbernd.com>

