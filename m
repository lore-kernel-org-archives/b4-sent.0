From: Luigi Leonardi <luigi.leonardi@outlook.com>
Subject: [PATCH net-next v4 0/3] ioctl support for AF_VSOCK and
 virtio-based transports
Date: Tue, 30 Jul 2024 21:43:05 +0200
Message-Id: <20240730-ioctl-v4-0-16d89286a8f0@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAElCqWYC/x3MQQqAIBRF0a3IHyeYGUJbiQaVr/oQGiohRHtPG
 h643IcSIiPRIB6KuDlx8BWmEbQes98h2VWTVtoo2ynJYc2nVG62DmgXq3uq7RWxcfk/I3lk6VE
 yTe/7AVk6YbthAAAA
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
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722368602; l=2445;
 i=luigi.leonardi@outlook.com; s=20240730; h=from:subject:message-id;
 bh=jStHrVvNAMto3VMCwoFU19s4xerZyWvjOXpxzysnaOY=;
 b=eqym0Ppsx5dpCzMQoiM/1cKMD/+ebz8mGeFylVwkxwL8mGlRCHqBIg/k3R70eCQDn2G/A9Yti
 R9Ku7AXyrOjDW5U1DxugU3XXRsqwD8EB/UJ6+9Z++WCr/FQh6ESD5LA
X-Developer-Key: i=luigi.leonardi@outlook.com; a=ed25519;
 pk=rejHGgcyJQFeByIJsRIz/gA6pOPZJ1I2fpxoFD/jris=
X-Endpoint-Received: by B4 Relay for luigi.leonardi@outlook.com/20240730 with auth_id=192
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

v3->v4
- Fixed warnings produced by kernel test robots
- Functions are now *_unsent_bytes
- Minor style changes pointed out by Stefano
- Using opts->peer_port in tests
- Rebased to latest net-next
- Link to v3: https://lore.kernel.org/r/20240626-ioctl_next-v3-0-63be5bf19a40@outlook.com

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
      vsock: add support for SIOCOUTQ ioctl
      vsock/virtio: add SIOCOUTQ support for all virtio based transports
      test/vsock: add ioctl unsent bytes test

 drivers/vhost/vsock.c                   |  4 +-
 include/linux/virtio_vsock.h            |  6 +++
 include/net/af_vsock.h                  |  3 ++
 net/vmw_vsock/af_vsock.c                | 58 ++++++++++++++++++++--
 net/vmw_vsock/virtio_transport.c        |  4 +-
 net/vmw_vsock/virtio_transport_common.c | 35 ++++++++++++++
 net/vmw_vsock/vsock_loopback.c          |  6 +++
 tools/testing/vsock/util.c              |  6 +--
 tools/testing/vsock/util.h              |  3 ++
 tools/testing/vsock/vsock_test.c        | 85 +++++++++++++++++++++++++++++++++
 10 files changed, 202 insertions(+), 8 deletions(-)
---
base-commit: 1722389b0d863056d78287a120a1d6cadb8d4f7b
change-id: 20240730-ioctl-0da7dee1b725

Best regards,
-- 
Luigi Leonardi <luigi.leonardi@outlook.com>

