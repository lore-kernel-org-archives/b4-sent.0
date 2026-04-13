From: Bernd Schubert <bernd@bsbernd.com>
Date: Mon, 13 Apr 2026 11:41:27 +0200
Subject: [PATCH v4 4/8] fuse: Fetch a queued fuse request on command
 registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-4-982b6414b723@bsbernd.com>
References: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
In-Reply-To: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=1270;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=SapXYOUPrCC+IfOqeimWzfPE/HV07KldNfKiLGyNNSw=;
 b=EPwi4FVaFDjmBp1J7pXGISbHKeRMNU6yXZhtr9LXA/DIa/R4Ri8og3SaXvHdYKA238G3sR5Nm
 dzLTbGaM0YtDTc0b1ndUrv9C3DQ7byXzVIabQqvKXpMvAwEUDSFm8ID
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Bernd Schubert <bschubert@ddn.com>

This is a preparation for the upcoming reduced fuse-io-uring queue
feature, i.e. less queues than system cores.

With the reduced queue feature fuse-io-uring is marked as ready
after receiving the 1st ring entry, as any available queue
can now handle ring requests.  At this time other queues just
might be in the process of registration and then a race might
happen

fuse_uring_queue_fuse_req -> no queue entry registered yet
    list_add_tail -> fuse request gets queued

So far fetching requests from the list only happened from
FUSE_IO_URING_CMD_COMMIT_AND_FETCH, but without new requests
on the same queue, it would actually never send requests
from that queue - the request would be stuck.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index 1d1305d38efa07641128a865aec1745d2e040b93..9dcbc39531f0e019e5abf58a29cdf6c75fafdca1 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1196,6 +1196,8 @@ static int fuse_uring_register(struct io_uring_cmd *cmd,
 
 	fuse_uring_do_register(ent, cmd, issue_flags);
 
+	fuse_uring_next_fuse_req(ent, queue, issue_flags);
+
 	return 0;
 }
 

-- 
2.43.0

