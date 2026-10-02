From: Jim Cromie <jim.cromie@gmail.com>
Subject: [PATCH 0/3] nouveau: fix 3 null-ptr derefs
Date: Fri, 02 Oct 2026 12:09:11 -0600
Message-Id: <20261002-my-fixups-v1-0-a83d20f9d3fe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwMj3dxK3bTMitKCYl1jI5MUI9M046QUA1MloPqColSgDNis6NjaWgD
 ve9JlWwAAAA==
X-Change-ID: 20261002-my-fixups-324d25f3bd05
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dave Airlie <airlied@redhat.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, Jim Cromie <jim.cromie@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790964559; l=908;
 i=jim.cromie@gmail.com; s=20260203; h=from:subject:message-id;
 bh=l1OzNkOrsT4f5QBYOcpWrv54bWAYIeRE0abj+dKKwBA=;
 b=bXg0YQm+JVFbyAzzrzbNaZnEeFWLW14SND0qnTb+OO0T8mgIoGF83EMcWZVbPeVO4LtzhBBXM
 i9k/xEtCNBvA4mTBQOfIKjqqsxuQj6i1jUC56re/dmmCcj4oQxXrNOq
X-Developer-Key: i=jim.cromie@gmail.com; a=ed25519;
 pk=C6E5ODlPQo7ZBynATXH9wg7K6HxP0pIXyf4s38Qw0XE=
X-Endpoint-Received: by B4 Relay for jim.cromie@gmail.com/20260203 with auth_id=958
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These 3 patches fix NULL ptr derefs I hit while booting kernels with
unrelated work (dynamic-debug) on a 2019 amdgpu+noueau laptop.  One of
them is possibly hard to reproduce, the others are "dependable".

Signed-off-by: Jim Cromie <jim.cromie@gmail.com>
---
Jim Cromie (3):
      drm/nouveau: Fix NULL pointer dereferences in GETPARAM ioctl
      drm/nouveau: Fix NULL pointer dereference in GET_ZCULL_INFO ioctl
      drm/nouveau/gsp: Fix NULL dereference in nvkm_gsp_gcx_ready()

 drivers/gpu/drm/nouveau/nouveau_abi16.c           | 27 ++++++++++++++++++-----
 drivers/gpu/drm/nouveau/nvkm/engine/device/user.c |  2 +-
 drivers/gpu/drm/nouveau/nvkm/subdev/gsp/base.c    |  2 +-
 3 files changed, 24 insertions(+), 7 deletions(-)
---
base-commit: 72d3fcf802c45d00b300f25b848a93c3a2bd7c7e
change-id: 20261002-my-fixups-324d25f3bd05

Best regards,
-- 
Jim Cromie <jim.cromie@gmail.com>

