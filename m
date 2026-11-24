From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v3 0/2] nova/nouveau: add configs/module options to control
 binding behaviour (v2)
Date: Tue, 24 Nov 2026 15:50:01 +1000
Message-Id: <20261124-nova-nouveau-gsp-v3-0-e1440479ded6@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NwQ6CMAyA4VchOztDu02GJ9/DeJijwA4yssGiI
 by7g5MmxkuTv0m/LixScBTZuVhYoOSi80MOcSiY7c3QEXdNboYlngCg5oNPJo85kZl5F0cOZas
 rjbLWJFk+GwO17rmT11vu3sXJh9f+IcG2/YMl4CWXtiG8Wwkg8BKo6c10tP7BNi3hh4Dih4BZU
 KQtVsZopdSXsK7rG+d5zgPzAAAA
X-Change-ID: 20261119-nova-nouveau-gsp-10f8782498e4
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1837; i=airlied@redhat.com;
 h=from:subject:message-id; bh=BZXGlfXXCG7eCTKLww014DE7HV6m3p7Wje5A+Rg73p8=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrBSWOFSwK6lxURuYvQ5bWlKqsfnsppYaaUczIg
 LMhdBezKWKJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawUljgAKCRAMdPNZecSG
 vrAID/93OnZriA540yJJeh3VlC271R8JLiItQlm0KoVrTcVEhFKuGg9A5qgtKj8ApNUS3SkUO6G
 rToJLzQmeYLt5KpwhcgxHr5AwIXm/66JCDiMlmEYuP38Wc6qvOYS0+SGDqcV9cUEPQ6G3IEr02e
 UgWZlTR6eAnDdDavLZfPUkV+kbiIAtJ2Yt4EwiCl+0LljN/y49mfr577xB+sI8Dlbvp9DhD8yYt
 trPRqmh+osAEZBd4fjauPRXRGJfi9wAsc6OpcxrJytypav6ZqzezPq/9lbQvBCzfZLp+K01i6yZ
 l/Dv7MWEYu4bRbEwxYXseKPULvAQsPtGqabAEppxAsqm01X6U5G4dy1kZrUpXUjOOpozFfuuhW9
 GnK8Cgrm/kqN5KqxjDSRNnU/pA1CgJiuznhxbcCtO0e3F5MXew17zsGsJYwpMHddDHBZoRW/j9F
 It1N3HZWnVIpJow95pI8Dda+ads8EHUHaU1sQ94vKqFAas/c3aWP7wVIv3nCSyX5LfIRlDMlf0A
 LQB7gPdxmOb7dhloKyUhhPDjhdhTMm69CLzt8Kdy8pcthiBbpZtHf0S2oILwn2KECFjz4TeRnau
 CZghjrQR2VzMnLJkyZFcpgWOtCud+IpDxH6PxeTrOnfhGOztdse+qFast3XXCznZqQTg3SKYgsL
 Z7JC+ucr2+bXYfQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We want to be able to build both nova and nouveau and maintain the
status quo for now of nouveau binding to all GSP enabled GPUs.

In the future we may suggest switching the default to nova, but
for now the default is to let users use command line options for testing
and developers building their own kernel can set the kconfig.

This contains a precursor patch to fix the nouveau device cleanup paths.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Changes in v3:
- back to single nouveau patch
  - fixes ctor teardown path (Danilo)
  - fixes passing bind_gsp flag (John)
- nova
  - move to using a function (Danilo)
- Link to v2: https://lore.kernel.org/r/20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com

Changes in v2:
- nouveau dtor path is broken, so fix that before adding the new code. (Sashiko)
- Link to v1: https://lore.kernel.org/r/20261119-nova-nouveau-gsp-v1-0-4cde2bc41132@redhat.com

---
Dave Airlie (2):
      drm/nouveau: add option to leave GSP-capable GPUs to other drivers
      nova-core: only bind to GPUs when explicitly requested

 drivers/gpu/drm/nouveau/Kconfig                   | 17 ++++++
 drivers/gpu/drm/nouveau/include/nvkm/core/pci.h   |  6 +-
 drivers/gpu/drm/nouveau/nouveau_drm.c             |  9 ++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/base.c | 67 ++++++++++++++++++-----
 drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c  | 11 +++-
 drivers/gpu/nova-core/Kconfig                     | 21 +++++++
 drivers/gpu/nova-core/driver.rs                   |  4 ++
 drivers/gpu/nova-core/nova_core.rs                | 23 ++++++++
 8 files changed, 139 insertions(+), 19 deletions(-)
---
base-commit: e55a991e09e3b44f0b0d8206bb523dc57c086341
change-id: 20261119-nova-nouveau-gsp-10f8782498e4

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

