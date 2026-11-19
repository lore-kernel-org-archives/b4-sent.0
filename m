From: =?utf-8?q?Jordan_DESNO=C3=8BS?= <jordan.desnoes@francetv.fr>
Subject: [PATCH 6.18.y 0/4] libceph: add CEPH_CRYPTO_AES256KRB5 support
Date: Thu, 19 Nov 2026 09:57:22 +0100
Message-Id: <20261119-aes256k-6-18-y-v1-0-bd5db87da2f5@francetv.fr>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAPK5/moC/yWMQQ6CQAwAv0J6tsRupC5+hXCApWg1QbMFIiH83
 RWOM8nMCiZRxeCWrRBlVtP3kIBOGYRHM9wFtUsM7uyYiEpsxFzBL2Qkjwte2r4r+OpLlgAp+kT
 p9bsPK+CcfL5AfXib2qeE8X+DbfsBs/cemXoAAAA=
X-Change-ID: 20261119-aes256k-6-18-y-4bfd567896ec
To: stable@vger.kernel.org
Cc: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Xiubo Li <xiubo.li@clyso.com>, Viacheslav Dubeyko <slava@dubeyko.com>, 
 ceph-devel@vger.kernel.org, 
 =?utf-8?q?Jordan_DESNO=C3=8BS?= <jordan.desnoes@francetv.fr>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795078645; l=1618;
 i=jordan.desnoes@francetv.fr; s=20261119; h=from:subject:message-id;
 bh=UpqiUKM7C7AR2lLJt+zJ2w1iHwSEDbb6nW94JSyxo8Q=;
 b=yfBLQPgOHbbFdt429ktoFdr+HMl0jyRmXE9h3Ngn+2eLDwuEe9lGv2j17vQJXxamT6ZM606jm
 F+xqrQAtd11ACdZ1SlPqvP7wmxnyLB3nyQUFAqxX69W8wI8cJE15wND
X-Developer-Key: i=jordan.desnoes@francetv.fr; a=ed25519;
 pk=NsqAnHujTt5QBjYGvDgx/bh9SKZzYfCniV8bhRv6vTA=
X-Endpoint-Received: by B4 Relay for jordan.desnoes@francetv.fr/20261119 with auth_id=1567
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Backport of the libceph aes256k series from v7.0, as discussed in [1].
Ilya is fine with it going to 6.18.y.

Patches 2 and 4 cherry-pick cleanly. Patches 1 and 3 conflict in
__ceph_x_decrypt() with 821365487aa5 ("libceph: Fix potential
out-of-bounds access in __ceph_x_decrypt()"), which 6.18.y already has;
the resolution gives the same code as mainline.

Tested on 6.18.58 against a Ceph 20.2.4 cluster restricted to aes256k:
rbd and CephFS via ceph-csi, map/unmap, reboot, and 24h of I/O across
ticket renewals. Build-tested on top of 6.18.64.

[1] https://lore.kernel.org/stable/PR1P264MB1805408F7C4A11E6F4D2F6BE887B2@PR1P264MB1805.FRAP264.PROD.OUTLOOK.COM/

Signed-off-by: Jordan DESNOËS <jordan.desnoes@francetv.fr>
---
Ilya Dryomov (4):
      libceph: generalize ceph_x_encrypt_offset() and ceph_x_encrypt_buflen()
      libceph: introduce ceph_crypto_key_prepare()
      libceph: add support for CEPH_CRYPTO_AES256KRB5
      libceph: adapt ceph_x_challenge_blob hashing and msgr1 message signing

 include/linux/ceph/ceph_fs.h |   5 +-
 net/ceph/Kconfig             |   1 +
 net/ceph/auth_x.c            | 195 ++++++++++++++++++++++---------
 net/ceph/auth_x_protocol.h   |  38 ++++++
 net/ceph/crypto.c            | 269 +++++++++++++++++++++++++++++++++++--------
 net/ceph/crypto.h            |  21 +++-
 net/ceph/messenger_v2.c      |  14 +--
 7 files changed, 428 insertions(+), 115 deletions(-)
---
base-commit: fd7cfd39c88596fec816639ad83cbf3e9d316372
change-id: 20261119-aes256k-6-18-y-4bfd567896ec

Best regards,
--  
Jordan DESNOËS <jordan.desnoes@francetv.fr>

