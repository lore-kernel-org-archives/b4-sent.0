From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH 6.12.y v2 0/4] virtio_balloon: quiesce balloon work before
 device shutdown
Date: Thu, 26 Nov 2026 06:18:40 +0000
Message-Id: <20261126-virtio-final-v2-0-4cfd5590e924@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEHPB2sC/02NzQ7CIBCEX6XZs1sLUWp8FeOBn8WuacAANpqm7
 y7oxeN8mflmhUyJKcO5WyHRwpljqEHuOrCTDjdCdjWDHKQSQipcOBWO6DnoGU/jURwGM3qnNdT
 JI5Hn11d3AdUL2b/h+uP5ae5kS3O1ptGZ0CQd7NRQpuBKjDM2vv//gG37AAinix2lAAAA
X-Change-ID: 20261126-virtio-final-875140b7fdaa
To: stable@vger.kernel.org
Cc: "Michael S. Tsirkin" <mst@redhat.com>, 
 "Denis V. Lunev" <den@openvz.org>, David Hildenbrand <david@kernel.org>, 
 Eric Auger <eric.auger@redhat.com>, Jason Wang <jasowang@redhat.com>, 
 virtualization@lists.linux.dev
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795673921; l=2322;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=ZT+5Ez28VjKU98DLLctCFr+rz8Hd8Cde9lAjru5yUy0=;
 b=9PfDIFEZgwlj/0l2msItZnuU1f/ifDvV1DPMOF0MTpIPRGlvQ40tpsR/ME6W4BEt+4zezYW5c
 bohXAhM7CJbDT4iCY/6pU+kWr/jsadhOSHaL5irOxQGJhyiS+YAstjQ
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This backports the fix for CVE-2026-90129 to 6.12.y, the same four
commits 6.18.y has:

  183a08715af1 virtgpu: don't reset on shutdown
  0d8aebe089b4 virtio: add virtio_device_shutdown() helper
  29536a923a94 virtio_balloon: factor out virtballoon_quiesce()
  7e17eef04600 virtio_balloon: quiesce balloon work before device shutdown

Since 8bd2fa086a04 the generic virtio shutdown breaks and resets the
device while the balloon's work items can still be running against it.
Patch 4 quiesces that work first. Patches 1-3 are what it builds on.

3 and 4 are clean picks. 1 and 2 needed small changes. 6.12 has no
reset_prepare/reset_done in struct virtio_driver, so patch 1 adds only
the .shutdown member. 6.12 has no virtio_irq_get_affinity(), so patch 2
puts the new helper right above virtio_dev_shutdown(). The function
bodies match upstream.

Tested on v6.12.119:
- x86_64 allmodconfig W=1 build of the touched objects, base vs
  patched, no new warnings
- x86_64 defconfig plus the touched virtio options boots and powers off
  under QEMU/KVM
- The race needs a balloon with free page reporting plus a reboot or
  kexec while it's busy. I didn't reproduce that.

6.1.y and 6.6.y need this too. I'll follow up for those once they're
tested.

Changes in v2
v2: resent through a whitespace-safe path; v1 was damaged by my mail client and does not apply.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

Thanks,
Dickson

---
Denis V. Lunev (3):
      virtio: add virtio_device_shutdown() helper
      virtio_balloon: factor out virtballoon_quiesce()
      virtio_balloon: quiesce balloon work before device shutdown

Michael S. Tsirkin (1):
      virtgpu: don't reset on shutdown

 drivers/gpu/drm/virtio/virtgpu_drv.c |  9 ++++++++
 drivers/virtio/virtio.c              | 41 ++++++++++++++++++++++++++----------
 drivers/virtio/virtio_balloon.c      | 34 ++++++++++++++++++++++++------
 include/linux/virtio.h               |  4 ++++
 4 files changed, 70 insertions(+), 18 deletions(-)
---
base-commit: e2e4b92c2b2a3ae78423cb343951cb5d2241b405
change-id: 20261126-virtio-final-875140b7fdaa

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

