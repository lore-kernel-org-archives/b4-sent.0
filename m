From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH 0/2] w1: Fix the lifetime of slaves and their master
Date: Thu, 19 Nov 2026 20:12:12 +0000
Message-Id: <20261119-w1-slave-release-v1-0-c2948c825d08@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABxY/2oC/yXMQQ6CQAxG4auQrmlCSRDhKobFzPCjNQTMFNGEc
 HdHWH6L9zYyRIVRm20UsarpPCVInlF4uOkO1j6ZyqK8iEjDH2Eb3QqOGOEM7NGEor861FVFKXt
 FDPo9lrfutL39E2H5f2jff6NQkf10AAAA
X-Change-ID: 20261119-w1-slave-release-be9c0d8ae755
To: krzk@kernel.org
Cc: josef@toxicpanda.com, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795119133; l=967;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=FjSxTwkL1aOlYkxVoWOgRcFWNmB3Um9Pqtg9/7bZYlM=;
 b=2tWyQWDC/zdatYVFVnSSgXg0Yq2cu9+TuC/eYHAwyIL7j84MHuAMA+x/KktUIWnCvJFjlt15J
 pEyRcgqa4+2Cx7ojzVgRBNqa9DSAKHOCDVf7Ijar3mB+FJS+ceouR4x
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

w1_unref_slave() frees a slave right after unregistering its device,
while the device's release callback still uses the slave and its
master. Since commit 9fcbbac5ded4 removing a slave no longer waits for
that callback, so a delayed release (or any late reference to the
slave device) runs on freed memory.

Patch 1 frees the slave from its release callback. Patch 2 makes the
slave hold a reference to the master until then, since the master can
otherwise be freed before the delayed release of its last slave.

Found with a static analysis tool and checked by hand. Both problems
reproduce under KASAN with CONFIG_DEBUG_KOBJECT_RELEASE and a test w1
master in QEMU; details below the --- line of each patch.

---
Suyuan Wang (2):
      w1: Free the slave from its device release callback
      w1: Keep the master alive until the slave is released

 drivers/w1/w1.c | 22 +++++++++++++---------
 1 file changed, 13 insertions(+), 9 deletions(-)

