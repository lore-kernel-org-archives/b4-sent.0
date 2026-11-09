From: Ke Sun <sunke@kylinos.cn>
Subject: [PATCH v6 00/10] drm/tyr: add VM and BO ioctl support
Date: Mon, 09 Nov 2026 08:36:43 +0800
Message-Id: <20261109-tyr-ioctls-v6-0-b2896bf2b3c9@kylinos.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJwV8WoC/2WQzW7CMBCEXyXyuUZrxz8YVRXvUfXg2GuwIE5rh
 wiEePc6oUKgHmdX387OXEnBHLGQTXMlGadY4pCqUG8NcXubdkijr5pw4AoMMDpeMo2DG4+FBgY
 YwLsuWEUq0NmCtMs2uf2M+NzTfCojTXge5/13xhDPi9nnV9X7WMYhXxbvqZ2nfzbcPNtMLQXKl
 ZEydIwxL7eHyzGmoaxcIvOdSTxYBhxeWFFZDcKj1t5y3v5j5TOrX1hZWWl8QLN2HcAre7sHyvh
 zqqWN91Skx1LsUtqmeV+OMtDAmeB6xRnIVgvKqLeHvD1gTnhcDXn38SjPDX0fx03jaq/Or8GgV
 MI5a6xbc2FbZZwx0nYawTMV2vrG7RfsvIVxwwEAAA==
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
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, driver-core@lists.linux.dev, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184620; l=6331;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=oGqTiUtORqt7n4EG0Z3MQXdgq8LN86uO3RFcLiKSUTQ=;
 b=D20rai7ipiOrUaAh7pEnAyLO6C4APPpErqt2r4hevEwbnSFlX5WF2owYIQA4WoNROZJgmc5Vm
 A06zMI3l3NpA5SeC3vx4DEekQ48W0cXRJtsxcuR987jdak1C6NiiNyF
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the VM and BO ioctls to the Tyr driver, aligning its userspace
interface with panthor.

The series is based on v2 of Danilo's lifetime-parameterized DRM File
private data series:
https://lore.kernel.org/all/20261107021427.2105374-1-dakr@kernel.org/

It also carries Sami Tolvanen's buffer cache-management patches from
https://gitlab.freedesktop.org/panfrost/linux sami/tyr/7.3/dev.

The panthor GEM and VM IGT tests pass on an RK3588S device. The group
and dev_query tests are not supported yet.

A branch with the full series and all prerequisites applied is
available at:
https://gitlab.freedesktop.org/alvinsun039/linux.git tyr-ioctls

Link: https://gitlab.freedesktop.org/panfrost/linux/-/merge_requests/64
Signed-off-by: Ke Sun <sunke@kylinos.cn>
---
Changes in v6:
- Rebase onto v2 of Danilo's lifetime-parameterized DRM File private
  data series and use the Driver::File<'a> associated type instead of
  ForLt.
- Drop the unrelated Firmware::new closure rework from the VM
  specifications patch (Deborah).
- Merge the write-combine and WB_MMAP patches into one, with the full
  should_map_wc() helper in a single place (Deborah).
- Accept DRM_PANTHOR_BO_WB_MMAP directly in the BO_CREATE patch,
  reject NO_MMAP combined with WB_MMAP, and return EOPNOTSUPP for
  unsupported requests such as an exclusive VM (Deborah).
- Pass the bound device from file.inner_with() to new_object() and
  drop the unsafe as_bound() access (Deborah).
- Expose all three DmaAttr values as constants instead of providing
  is_coherent() (Deborah).
- Validate the VM id before the empty-ops early return in VM_BIND and
  reject sync objects before the size check, as in Panthor (Deborah).
- Require an exact ops stride for now, use from_safe_cast for the id
  and size conversions, and add TODO notes for variable strides and
  zerocopy FromBytes (Deborah).
- Link to v5: https://patch.msgid.link/20261027-tyr-ioctls-v5-0-59dfe98cb003@kylinos.cn

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

Sami Tolvanen (3):
      rust: task: add task_size()
      rust: device: expose the device DMA attribute
      drm/tyr: support write-combine BO mappings

 drivers/gpu/drm/tyr/driver.rs   |  25 ++-
 drivers/gpu/drm/tyr/file.rs     | 390 +++++++++++++++++++++++++++++++++++++++-
 drivers/gpu/drm/tyr/fw.rs       |   5 +-
 drivers/gpu/drm/tyr/gem.rs      |  79 +++++++-
 drivers/gpu/drm/tyr/vm.rs       | 355 ++++++++++++++++++++++++++++++++++--
 rust/bindings/bindings_helper.h |   1 +
 rust/helpers/task.c             |   6 +
 rust/kernel/device.rs           |  27 +++
 rust/kernel/sizes.rs            |  12 ++
 rust/kernel/sync/arc.rs         |  12 +-
 rust/kernel/task.rs             |  12 ++
 11 files changed, 883 insertions(+), 41 deletions(-)
---
base-commit: cef0cd809e564cca9ac824a369c995ab7e0d16f3
change-id: 20260901-tyr-ioctls-f10ef0dcbfa6
prerequisite-message-id: <20261107021427.2105374-1-dakr@kernel.org>
prerequisite-patch-id: e17775a2fb002d71edd479f6002dc3380b9b6bb4
prerequisite-patch-id: 388c5b871c09dbb6bad46c68be04813bcbdaadb6
prerequisite-patch-id: f31098f7dcd1b2d7843767f9ef778788f8773477
prerequisite-patch-id: b0ea30b4c39e5a43e53ceaf28bd8b39db5b26a76
prerequisite-patch-id: e0735b7cd0f226e702c0edc4ed889340f93d24cf
prerequisite-patch-id: 086eb00ec9c9c445c99bbb8d1a052b3fad56b5bd
prerequisite-patch-id: d186dd1af2f3ce256afd8c7b6ff749d74def5d1a

Best regards,
--  
Ke Sun <sunke@kylinos.cn>

