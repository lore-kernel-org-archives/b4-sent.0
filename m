From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/2] ceph: serialize O_APPEND writes across clients
Date: Sat, 21 Nov 2026 03:21:04 +0200
Message-Id: <20261121-ceph-append-excl-v1-0-5870375edeb8@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTsJUwgLr0Jc1OmvjCG1aZWQE
 O5O0eW3eG+jgmwodG02ylis2DtWyKUhnXx8gi1Uk2vdIOKEFWlinxJiYKw689ArOtcF8W1PNUs
 ZD1t/y/H2d/neX9DP+aF9PwDiK5dVdAAAAA==
X-Change-ID: 20261121-ceph-append-excl-64ce323d1a04
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anthony D'Atri <anthony.datri@gmail.com>, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795224072; l=2848;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=RCPLg7Ke9jKSrF2JxKZJ5I96oPla1eTrmZ1jJ4NOnWs=;
 b=GOoO+Hp6nnCDWHPEgyORCvLlfMUbIJy2HFEj8sd5wMCj4biuKWBOUWTKeeaqoVUgLMwW8pV66
 KvtBjaGRA+UBlUENECfLOlwVX6D/boql/HSNcLLxbq4Sd7YoWmBSRgJ
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When two clients append to one file, the filelock is in MIX and both
hold Fw, so each appends at the end of file it has cached and may
overwrite what the other one appended.  Commit d2a8d446a09c ("ceph:
revalidate ki_pos for O_APPEND writes after cap acquisition") does
not cover this case: neither client waits for caps, and the other
client's size only arrives after it flushed its caps.

The MDS side [1] lets O_APPEND writers take turns on Fx, in request
order, and sends the current size together with Fx.  It is enabled by
the new CEPHFS_FEATURE_APPEND_EXCL feature bit; with an MDS that does
not have it, the client behaves as before.

Patch 1 fixes a reordering of the cap messages of an inode that this
work exposed: a later cap update could overtake the flush carrying the
new size, the MDS then finished its Fw gather early and gave Fx with
the old size to the other client.

Patch 2 is the O_APPEND change itself.

Tested on a vstart cluster with [1], KASAN and lockdep enabled, two
mounts (noshare, or ceph-fuse + kernel), 4 writers on each, without
any file locking; a lost record means one append overwrote another:

  +--------------------------------------+--------+------------------+
  | case                                 | runs   | lost records     |
  |                                      |        | base / patched   |
  +--------------------------------------+--------+------------------+
  | buffered, kernel + kernel            | 4      | ~3300-4000 / 0   |
  | O_DIRECT, kernel + kernel            | 10     | ~4000 / 0        |
  | buffered/O_DIRECT, ceph-fuse+kernel  | 6      | - / 0            |
  | 2 active MDS, export every 3 s       | 4      | - / 0            |
  | MDS failover during the writes       | 2      | - / 0            |
  +--------------------------------------+--------+------------------+

With an MDS without the feature the patched client loses records like
the base one, and does not hang.  xfstests -g quick shows the same 8
failures (ceph/006, fscrypt key tests) with and without the series.

[1] https://github.com/ceph/ceph/pull/70279

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Xiubo Li (2):
      ceph: send the cap messages of an inode in the order they were prepared
      ceph: serialize O_APPEND writes across clients on Fx

 fs/ceph/caps.c               | 208 +++++++++++++++++++++++++++++++++++++++++++
 fs/ceph/file.c               |  33 +++++--
 fs/ceph/inode.c              |   6 ++
 fs/ceph/mds_client.h         |   4 +-
 fs/ceph/super.h              |  17 ++++
 include/linux/ceph/ceph_fs.h |   1 +
 6 files changed, 261 insertions(+), 8 deletions(-)
---
base-commit: 6a9830a8f414d3830c584782568d0233be969d09
change-id: 20261121-ceph-append-excl-64ce323d1a04

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

