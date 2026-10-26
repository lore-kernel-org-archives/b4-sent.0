From: Ke Sun <sunke@kylinos.cn>
Subject: [PATCH v5 00/11] drm/tyr: add VM and BO ioctl support
Date: Tue, 27 Oct 2026 00:40:53 +0800
Message-Id: <20261027-tyr-ioctls-v5-0-59dfe98cb003@kylinos.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJaC32oC/1WNzQ6CMBAGX8X07Jpt+QuefA/jobRbacRi2kogh
 He3EGPkOLuZb2YWyFsK7HyYmafBBtu7BMXxwFQr3Z3A6sRMoCixRg5x8mB7FbsAhiMZ1KoxsmR
 JaGQgaLx0ql0V7Z/g3yGCozGu/5cnY8ctdr0lbm2IvZ+29pCt129G1P+ZIQMEUdZFYRrOuS4uj
 6mzrg8n5di6M+Q/l6PAnZsnt8JcU1VpKUS2c5dl+QBMNEAyAQEAAA==
X-Change-ID: 20260901-tyr-ioctls-f10ef0dcbfa6
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
 Lorenzo Stoakes <ljs@kernel.org>, Lyude Paul <lyude@redhat.com>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, driver-core@lists.linux.dev, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793032870; l=4531;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=bBAFke2fJNrZEEGOOQEc7TX5IdMqHI9K3Ku4aJdqwK4=;
 b=nCwTUaF+5xXHNkykuInJkW3epGCTNQqM0QAwLO4uTbgJOFCY8AtlgQi++hWoCzHuFaT6uRtSI
 i1s7CmZyYbiDveCKqPxwj0jdjAv7A8KHl5K0K9Rw/9xGQ01qf0m9xSD
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the VM and BO ioctls to the Tyr driver, aligning its userspace
interface with panthor.

The series is based on Danilo's `drm-file` series on
`drm-rust-next`. It also carries Sami Tolvanen's buffer
cache-management patches from
https://gitlab.freedesktop.org/panfrost/linux sami/tyr/7.3/dev.

The panthor IGT tests pass on an RK3588S device.

A branch with the full series and all prerequisites applied is
available at:
https://gitlab.freedesktop.org/alvinsun039/linux.git tyr-ioctls

Link: https://gitlab.freedesktop.org/panfrost/linux/-/merge_requests/64
Signed-off-by: Ke Sun <sunke@kylinos.cn>
---
Changes in v5:
- Replace the mm-based task_size() (always returned 0) with Sami's
  CurrentTask::task_size() implementation (Deborah, Alice).
- Use from_safe_cast() for the id conversions and annotate the AddError
  fields so the VM pool patch compiles on its own (Deborah).
- Store a clone on pool conflicts and return the caller's VM instead of
  expect()-ing (Deborah).
- Drop the redundant project() in PinnedDrop (Deborah).
- Fix the rustfmt issues found in the series (Deborah).
- Link to v4: https://patch.msgid.link/20261020-tyr-ioctls-v4-0-704de77da223@kylinos.cn

Changes in v4:
- Rework VmPool teardown: add() returns an AddError the caller owns,
  a conflicting stored VM is killed with EBUSY, and remove() kills
  before the ID is reused (Daniel, Deborah).
- Wrap dev_dma_attr in a DmaAttr type with dma_attr()/is_coherent()
  and rename the patch accordingly (Danilo).
- Fetch the sg_table unconditionally in new_object() and drop the
  conditional flush call (Daniel).
- Use dev_dbg!() instead of dev_err!() for user-input validation and
  EOPNOTSUPP for the async VM_BIND path (Daniel).
- Drop the pr_err!() calls from the VM specification patch (Daniel).
- Link to v3: https://patch.msgid.link/20260929-tyr-ioctls-v3-0-26955fb111d5@kylinos.cn

Changes in v3:
- Drop the VmOwner wrapper and kill VMs explicitly on destroy and
  file close (Deborah).
- Add Sami Tolvanen's buffer cache-management patches: coherent
  devices map buffers cached, write-combine buffers flush at
  creation, and BO_CREATE accepts WB_MMAP.
- Drop the new_dummy_object refactor; the dummy object stays a direct
  Bo::new since new_object now fetches the sgtable for write-combine
  buffers.
- Document the LargeSizeConstants trait in the sizes patch (Miguel).
- Misc commit message and comment cleanups.
- Link to v2: https://lore.kernel.org/r/20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn

Changes in v2:
- Fold the VM pool into vm.rs and cap it at 32 VMs per file (Deborah).
- Add VmOwner so a VM is killed exactly once on drop, regardless of
  remaining references (Daniel).
- Replace the VmSpec enum with new_for_fw()/new_for_user()
  constructors (Daniel).
- Parse VM_BIND op types via VmBindOpType and use the kernel
  Atomic<bool> for the unusable flag (Daniel).
- Use PAGE_SIZE for the dummy object size (Daniel).
- Rename BoData::create_flags() to flags() (Daniel).
- Report VA-split failures with dev_err! at the caller.
- Link to v1: https://lore.kernel.org/r/20260902-tyr-ioctls-v1-0-e0fdbf8bd108@kylinos.cn

---
Alvin Sun (7):
      rust: sizes: add SZ_4G constant
      rust: sync: arc: relax `ForeignOwnable` for `Arc<T>`
      drm/tyr: add per-file VM pool
      drm/tyr: add user and MCU VM specifications
      drm/tyr: add BO creation and lookup helpers
      drm/tyr: add VM-related ioctls
      drm/tyr: add BO-related ioctls

Sami Tolvanen (4):
      rust: task: add task_size()
      rust: device: expose the device DMA attribute
      drm/tyr: gem: flush write-combine BOs from probe-time coherence
      drm/tyr: gem: map cached BOs for DRM_PANTHOR_BO_WB_MMAP

 drivers/gpu/drm/tyr/driver.rs   |  24 ++-
 drivers/gpu/drm/tyr/file.rs     | 407 +++++++++++++++++++++++++++++++++++++++-
 drivers/gpu/drm/tyr/fw.rs       |  21 ++-
 drivers/gpu/drm/tyr/gem.rs      |  76 +++++++-
 drivers/gpu/drm/tyr/vm.rs       | 355 +++++++++++++++++++++++++++++++++--
 rust/bindings/bindings_helper.h |   1 +
 rust/helpers/task.c             |   6 +
 rust/kernel/device.rs           |  24 +++
 rust/kernel/sizes.rs            |  12 ++
 rust/kernel/sync/arc.rs         |  12 +-
 rust/kernel/task.rs             |  12 ++
 11 files changed, 900 insertions(+), 50 deletions(-)
---
base-commit: 0315936d31de6de2668d14294486aebaaeece4b3
change-id: 20260901-tyr-ioctls-f10ef0dcbfa6

Best regards,
--  
Ke Sun <sunke@kylinos.cn>

