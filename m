From: Dave Airlie <airlied@redhat.com>
Subject: [PATCH 0/2] nova/nouveau: add configs/module options to control
 binding behaviour
Date: Thu, 19 Nov 2026 11:38:23 +1000
Message-Id: <20261119-nova-nouveau-gsp-v1-0-4cde2bc41132@redhat.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqAIBAAvxJ7TnBFyvpKdJBabS8aShKIf0+6D
 MxhpkKmxJRhHSokKpw5hi44DnBcNngSfHYHJdWEiIsIsdiOp5B9hM+3QOnMbJReDGno2Z3I8fs
 vt721D0uK5XpiAAAA
X-Change-ID: 20261119-nova-nouveau-gsp-10f8782498e4
To: Lyude Paul <lyude@redhat.com>, Danilo Krummrich <dakr@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: dri-devel@lists.freedesktop.org, nouveau@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1451; i=airlied@redhat.com;
 h=from:subject:message-id; bh=a4R+CA33McYCg3MsCLoZGkMds+XhCjyC2e9aLNwAvnk=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq/lMX3zuL8Y2AWISRh7ealRDpz9EVaxPcLG55H
 GUDkx93P6OJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCav5TFwAKCRAMdPNZecSG
 vnCHD/9A8JSADHK6u4S3PFnLGfl3AlKX1XQ/M3NgiCJ2C/H5ixG2dGNm+EU58QykVRu8LBs8hBT
 DVTXl9Z5O/Wj+pNBCvAKcHj7cF9Ies0wFE1AkGjUm9pYKt+elLDwaihXjU6JQZ05GSQoixtIpdP
 +bIS/iGqbXI02QUT7fAtUCkMiMdsqpor38Xp4ZQ11BKKbafgkctr7eRydHvfpZLDCKL+7fD68tD
 gpjxuXUQ5bOj0qKuHKfFoBdpnMTvwZ86Jj5efdQl/5KVLKslE2B1aYZR767NZCNNqLso617eddz
 j5IZCQxTQMIgZMBJQOnvHyl1jRUiTCyJCSXHjR9X1XL6o67hVKPtp3haObrG6cf2Qbn3VODEG+n
 H3dTFbLKcxYfHdn8pvKprQEVjdhU/wP50jIRiPl3ckqjPnaZZ2F6sF88D2ei1NDLqgagJIFND+D
 +gNRwqw9mad0BWBAVqSOiGATCKeaSnqVKKPQzB40/aM3naGzV6punmsu5Rh937al3PI5MKm9wN/
 PZttHKHlHh8zd0TSojV05nk3uKLIWY+mxL/wAsJL9TpVXIbHSNRVVpKxzQfJ7upeirLgk5VKO8H
 fxIlao9BYQNitFgWVoL7qaQqK6uBCU2/37rHGjdJcCbzWO3RDUJEgMdJ+AuQFdpnTT7IWb7y+RG
 sNmVVxMYIFcsV8A==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We want to be able to build both nova and nouveau and maintain the
status quo for now of nouveau binding to all GSP enabled GPUs.

In the future we may suggest switching the default to nova, but
for now the default is to let users use command line options for testing
and developers building their own kernel can set the kconfig.

Signed-off-by: Dave Airlie <airlied@redhat.com>
---
Dave Airlie (2):
      drm/nouveau: add option to leave GSP-capable GPUs to other drivers
      nova-core: only bind to GPUs when explicitly requested

 drivers/gpu/drm/nouveau/Kconfig                    | 17 +++++++++++++++++
 drivers/gpu/drm/nouveau/include/nvkm/core/pci.h    |  2 +-
 drivers/gpu/drm/nouveau/nouveau_drm.c              |  9 ++++++++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/base.c  | 16 +++++++++++++++-
 drivers/gpu/drm/nouveau/nvkm/engine/device/pci.c   |  4 ++--
 drivers/gpu/drm/nouveau/nvkm/engine/device/priv.h  |  2 +-
 drivers/gpu/drm/nouveau/nvkm/engine/device/tegra.c |  5 ++++-
 drivers/gpu/nova-core/Kconfig                      | 21 +++++++++++++++++++++
 drivers/gpu/nova-core/driver.rs                    | 13 +++++++++++++
 drivers/gpu/nova-core/nova_core.rs                 |  4 ++++
 10 files changed, 86 insertions(+), 7 deletions(-)
---
base-commit: e55a991e09e3b44f0b0d8206bb523dc57c086341
change-id: 20261119-nova-nouveau-gsp-10f8782498e4

Best regards,
-- 
Dave Airlie <airlied@redhat.com>

