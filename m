From: Luigi Leonardi <luigi.leonardi@outlook.com>
Subject: [PATCH net-next v3 0/3] ioctl support for AF_VSOCK and
 virtio-based transports
Date: Wed, 26 Jun 2024 14:08:34 +0200
Message-Id: <20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMIEfGYC/x2MQQqAIBAAvyJ7ThArob4SEaVrLYSGSgjS37OOA
 zNTIGIgjDCyAgFviuRdhbZhoI/V7cjJVAYpZCeUVJy8TufiMCdut00b0w9KqBZqcAW0lP/ZBA4
 T/yyYn+cFLWo0gGYAAAA=
To: Stefano Garzarella <sgarzare@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Stefan Hajnoczi <stefanha@redhat.com>, 
 "Michael S. Tsirkin" <mst@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>, 
 Xuan Zhuo <xuanzhuo@linux.alibaba.com>
Cc: virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kvm@vger.kernel.org, 
 Luigi Leonardi <luigi.leonardi@outlook.com>, 
 Daan De Meyer <daan.j.demeyer@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719403717; l=2183;
 i=luigi.leonardi@outlook.com; s=20240626; h=from:subject:message-id;
 bh=6+8bqp4cDtpRaRrmfUU+dpvgtMMlgSZQodg1El7MI5E=;
 b=IWWqvzJ+wnZA9iJ5U6GbU25eUB91GRaT6iBrG0OwHjrkK+izvBFFcKxzBLy8WlPe7dE9aaGNU
 f+xPdDS3YU4CVbMfqX62lWk26eorcsZcbT4gx0vnmd7AdJG1Jz277m3
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=RYXD8JyCxGnx/izNc/6b3g3pgpohJMAI0LJ7ynxXzi8=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240626 with auth_id=177
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduce the support for ioctl(s) in AF_VSOCK.
The only ioctl currently available is SIOCOUTQ, which returns
the number of unsent or unacked packets. It is available for
SOCK_STREAM, SOCK_SEQPACKET and SOCK_DGRAM.

As this information is transport-dependent, a new optional callback
is introduced: unsent_bytes.

The first patch add ioctl support in AF_VSOCK, while the second
patch introduce support for SOCK_STREAM and SOCK_SEQPACKET
in all virtio-based transports: virtio_transport (G2H),
vhost-vsock (H2G) and vsock-loopback.

The latest patch introduce two tests for this new feature.
More details can be found in each patch changelog.

v2->v3
Applied all reviewers' suggetions:
    - Minor style and code changes
    - atomic_int replaced with an existing spin_lock.
Introduced lock_sock on ioctl call.
Rebased to latest net-next

v1->v2
Applied all Stefano's suggestions:
    - vsock_do_ioctl has been rewritten
    - ioctl(SIOCOUTQ) test is skipped when it is not supported
    - Minor variable/function name changes
    - rebased to latest net-next

Signed-off-by: Luigi Leonardi <luigi.leonardi@outlook.com>
---
Luigi Leonardi (3):
      vsock: add support for SIOCOUTQ ioctl for all vsock socket types.
      vsock/virtio: add SIOCOUTQ support for all virtio based transports
      test/vsock: add ioctl unsent bytes test

 drivers/vhost/vsock.c                   |  4 +-
 include/linux/virtio_vsock.h            |  7 +++
 include/net/af_vsock.h                  |  3 ++
 net/vmw_vsock/af_vsock.c                | 60 +++++++++++++++++++++--
 net/vmw_vsock/virtio_transport.c        |  4 +-
 net/vmw_vsock/virtio_transport_common.c | 35 ++++++++++++++
 net/vmw_vsock/vsock_loopback.c          |  7 +++
 tools/testing/vsock/util.c              |  6 +--
 tools/testing/vsock/util.h              |  3 ++
 tools/testing/vsock/vsock_test.c        | 85 +++++++++++++++++++++++++++++++++
 10 files changed, 206 insertions(+), 8 deletions(-)
---
base-commit: 50b70845fc5c22cf7e7d25b57d57b3dca1725aa5
change-id: 20240626-ioctl_next-fbbcdd596063

Best regards,
-- 
Luigi Leonardi <luigi.leonardi@outlook.com>

