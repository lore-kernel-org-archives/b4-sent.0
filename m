From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH v2 0/3] nova/nouveau: add configs/module options to control
 binding behaviour (v2)
Date: Mon, 23 Nov 2026 12:50:26 +1000
Message-Id: <20261123-nova-nouveau-gsp-v2-0-5e8c27aa8555@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NQQ7CIBREr9L8tRg+EqWueg/TBcJvYSE00BJNw
 93FHsDNJG+SebNDpuQpw73bIVHx2cfQQJw6ME6HmZi3jUFwcUXEnoVYdIutkN7YnBeGfFI3JWS
 vSEKbLYkm/z6Uj7Gx83mN6XM8FPy1f2QFGWfSWBJPIxEvYkhknV7PJr5grLV+AUqGK1mxAAAA
X-Change-ID: 20261119-nova-nouveau-gsp-10f8782498e4
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1789; i=airlied@redhat.com;
 h=from:subject:message-id; bh=IQCBoG1+S/7f8h44/YGxX/CWODzrYVl8kCsL3KZ4I/k=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBrA6n1R6zlkhvEaaCyFyedYEwVHp1wtW+AkOVc9
 7oo+hB3yPSJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCawOp9QAKCRAMdPNZecSG
 vtiVD/9mqrXacWm7aSQDVc5zvQqY304JMu/3BpMdQpx4kB4xbHO+kBdTPFoTvdo62Jehv2N02q/
 sCH7tp+qWk3jFaHcgIuNRn2qR6J12HOuDMNohpcBTotg7BWxjOQhonGxVe/VH6nNwub/f0lL1rA
 jTBOPMpikuD4A1ZN9xAxw3PFG1uRVhpTYoi54HSG62m/NNNNEMwApeatvTZ0OLebCgAdZcu7SBI
 BT5fopdwVmNF/DdIuKKX5eLMcCtJMEbB6X9h2wC3OawrhFrltQCbe9GkWzMAN3yjsRoUVSGBiOB
 VYdW9i7ISn/Z60qgphBZxXR6XIecq+7EzbhxRCY2mP8tzQHp6lYyYRSzzm0lcYXQtUJI4vUCeav
 ctpMeK89B6ekxielkKgJ7UZojWYniOFoL6Xt8tuL8JDDpC3BI4lCYr9BQVIL4TDpWqicQvg4Xeu
 KKoUalumlPR6SbgXtJXUsia47qUZUR8kFE6WS5oMbzbiAvBQuMRErFaW0xs2ViFr/CTSCtfIcix
 nUaK0zQfw0lnYWB0UjHHgu1OdyU+IfQX3LnqvLLVMgk6VcosdF8xcKBsXGabPtrmMBFMVjG1GJH
 usuGV0zBJpHSe3AagqGmTP10zA2iFm/KKZllfctGDGqBBH/fCVuPMx4LG+6fOK5nF2VSaRWlok8
 aUZg+xrKXqc8TwQ==
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
Changes in v2:
- nouveau dtor path is broken, so fix that before adding the new code. (Sashiko)
- Link to v1: https://lore.kernel.org/r/20261119-nova-nouveau-gsp-v1-0-4cde2bc41132@redhat.com

---
Dave Airlie (3):
      drm/nouveau/nvkm: fix device leak on ctor failure
      drm/nouveau: add option to leave GSP-capable GPUs to other drivers
      nova-core: only bind to GPUs when explicitly requested

 drivers/gpu/drm/nouveau/Kconfig                    | 17 +++++++++++++
 drivers/gpu/drm/nouveau/include/nvkm/core/pci.h    |  2 +-
 drivers/gpu/drm/nouveau/nouveau_drm.c              |  9 ++++++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/base.c  | 29 +++++++++++++++++++---
 drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c   |  8 +++---
 drivers/gpu/drm/nouveau/nvkm/engine/device/priv.h  |  2 +-
 drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c | 18 ++++++++++----
 drivers/gpu/nova-core/Kconfig                      | 21 ++++++++++++++++
 drivers/gpu/nova-core/driver.rs                    | 13 ++++++++++
 drivers/gpu/nova-core/nova_core.rs                 |  4 +++
 10 files changed, 108 insertions(+), 15 deletions(-)
---
base-commit: e55a991e09e3b44f0b0d8206bb523dc57c086341
change-id: 20261119-nova-nouveau-gsp-10f8782498e4

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

