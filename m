From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH v2 0/3] nouveau: fix 3 null-ptr derefs
Date: Fri, 09 Oct 2026 11:44:23 -0600
Message-Id: <20261009-my-fixups-v2-0-839e2bbe514d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22MQQ7CIBBFr9LM2jEwWKOueg/TBRZoJ5HSgBKbh
 ruLXbt8/7+8DZKNbBPcmg2izZw4zBXo0MAw6Xm0yKYykKCzFILQr+j4814SKjoZap16GNFC9Zd
 o67O37n3lidMrxHVPZ/lb/1WyRIH6ogwJdzXK2W70mp/HIXjoSylfYs7o76IAAAA=
X-Change-ID: 20261002-my-fixups-324d25f3bd05
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Daniel Campos Ramos <Capitain_Jack@yahoo.com>, 
 Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791567877; l=1161;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=qFnpKLgFzGpj26HbsAUuI94pp4dsklj2mWHgmwxeK3k=;
 b=OEhSJHp9zZcm8RTWFCmeE4sI2nqpOYo7auJz0s/ut5P7fLlcljs0MFsuz4wx0f1iMm/Qc967C
 +pW26iIYTamDg4NGjTSfFeMqshwHenCkouxE1zMqrcvqJEBI16Q8Zlo
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These 3 patches fix NULL ptr derefs I hit while booting kernels with
unrelated work (dynamic-debug) on a 2019 amdgpu+noueau laptop.  One of
them is possibly hard to reproduce, the others are "dependable".

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Changes in v2:
- added check of gsp->rm into nvkm_gsp_rm(gsp)
- change if-then-else to if-early-fail, fallthru
- Link to v1: https://lore.kernel.org/r/20261002-my-fixups-v1-0-a83d20f9d3fe@gmail.com

---
Jim Cromie (3):
      nouveau: Fix NULL pointer dereferences in GETPARAM ioctl
      nouveau: Fix NULL pointer dereference in GET_ZCULL_INFO ioctl
      nouveau: Fix NULL dereference in nvkm_gsp_gcx_ready()

 drivers/gpu/drm/nouveau/include/nvkm/subdev/gsp.h |  2 +-
 drivers/gpu/drm/nouveau/nouveau_abi16.c           | 24 ++++++++++++++++++++---
 drivers/gpu/drm/nouveau/nvkm/engine/device/user.c |  2 +-
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c    |  2 +-
 4 files changed, 24 insertions(+), 6 deletions(-)
---
base-commit: 72d3fcf802c45d00b300f25b848a93c3a2bd7c7e
change-id: 20261002-my-fixups-324d25f3bd05

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

