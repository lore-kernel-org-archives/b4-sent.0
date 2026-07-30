From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH v2 0/9] drm/tyr: add debugfs support
Date: Fri, 31 Jul 2026 01:05:38 +0800
Message-Id: <20260731-tyr-debugfs-v2-v2-0-aea19eccb996@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGKEa2oC/1XMQQqDMBCF4avIrDsliZLYrnqP4sKYiQ4ULYkGR
 bx7U7vq8n/wvh0iBaYI92KHQIkjT2MOdSmgG9qxJ2SXG5RQWphS4LwFdGSX3kdMCrWoO/LGOE0
 3yKd3IM/rCT6b3APHeQrb6Sf5XX9UqTTa6l+TKFCYyrbOydpI/XjxuKxXRwma4zg+qlmAN6wAA
 AA=
X-Change-ID: 20260730-tyr-debugfs-v2-608cef77d6e9
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 =?utf-8?q?Ma=C3=ADra_Canal?= <mcanal@igalia.com>, 
 Melissa Wen <mwen@igalia.com>, Wambui Karuga <wambui.karugax@gmail.com>, 
 Eric Anholt <eric@anholt.net>, Ben Gamari <bgamari@gmail.com>, 
 rust-for-linux@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785431148; l=2996;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=WJNElWu592lk+DfJprCvpZbrcam1TYEaJCYoPn+lj7Q=;
 b=5uoDnSU8u5kq7EhDMiaBRuQHiGpZrD11Ztv+I5OqhiaghHW9Wpa0JFufAsAC3Mz0phtpateqv
 0WljLYcj1fAB/As9nX153I0hY4FuXbUXJcxYSbLv6+Np1EliuGd08Wz
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add debugfs support for the Tyr DRM driver.

The series adds a SeqShow trait for seq_file-backed debugfs files with
lifecycle hooks, a DrmSeqShow adapter with DRM device lifecycle
management, and a gpuvas debugfs file in Tyr exposing GPU VA space
information.

Additionally, fix a use-after-free in the DRM debugfs open/release
paths where a device could be unregistered while a debugfs file remains
open.

This is based on drm-rust-next and depends on:

[PATCH v10 0/7] drm/tyr: firmware loading and MCU boot support
  https://lore.kernel.org/r/20260728-fw-boot-b4-v10-0-9187aefa3f2f@collabora.com

See the full dependency and commit history at [1].

Link: https://gitlab.freedesktop.org/panfrost/linux/-/issues/11
Link: https://gitlab.freedesktop.org/panfrost/linux/-/merge_requests/59 [1]
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Changes in v2:
- Reworked the debugfs implementation per feedback from Danilo on v1:
  dropped the hazptr/revocable-based approach in favor of the DRM
  debugfs_init callback and generic seq_file abstractions.
- Fixed a UAF in drm_debugfs where a device could be unregistered while
  a debugfs file remains open (drm_dev_get/put across file lifetime).
- Link to v1: https://lore.kernel.org/r/20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev

---
Alvin Sun (9):
      rust: seq_file: add as_raw() method
      rust: debugfs: add SeqShow trait and seq_file file operations
      rust: debugfs: add Entry::from_raw and ScopedDir::from_dentry
      drm: move debugfs_init after dev->registered is set
      rust: drm: add debugfs_init callback to Driver trait
      rust: drm: add DrmSeqShow seq_file adapter
      rust: drm: gpuvm: add dump_gpuva_info to UniqueRefGpuVm
      drm/tyr: add gpuvas debugfs file
      drm/debugfs: hold device reference for the lifetime of open files

 drivers/gpu/drm/drm_debugfs.c   | 45 ++++++++++++++++---
 drivers/gpu/drm/drm_drv.c       |  5 +++
 drivers/gpu/drm/tyr/debugfs.rs  | 65 +++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/driver.rs   | 16 +++++++
 drivers/gpu/drm/tyr/fw.rs       |  8 ++++
 drivers/gpu/drm/tyr/tyr.rs      |  1 +
 drivers/gpu/drm/tyr/vm.rs       |  5 +++
 rust/bindings/bindings_helper.h |  1 +
 rust/kernel/debugfs.rs          | 35 ++++++++++++++-
 rust/kernel/debugfs/entry.rs    | 15 ++++++-
 rust/kernel/debugfs/file_ops.rs | 97 +++++++++++++++++++++++++++++++++++++++++
 rust/kernel/debugfs/traits.rs   | 30 ++++++++++++-
 rust/kernel/drm/debugfs.rs      | 49 +++++++++++++++++++++
 rust/kernel/drm/device.rs       | 36 ++++++++++++++-
 rust/kernel/drm/driver.rs       | 11 +++++
 rust/kernel/drm/gpuvm/mod.rs    |  8 ++++
 rust/kernel/drm/mod.rs          |  1 +
 rust/kernel/seq_file.rs         |  6 +++
 18 files changed, 422 insertions(+), 12 deletions(-)
---
base-commit: 0ffc014cb2abfc79d161662b125e085b3e7107e7
change-id: 20260730-tyr-debugfs-v2-608cef77d6e9

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

