From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH 00/13] drm/tyr: add debugfs support
Date: Thu, 26 Mar 2026 14:52:53 +0800
Message-Id: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMbXxGkC/3WO0WrDMAxFfyX4eQqWndiNKWP/Mfrg2HJqWJrOT
 sJK6b/PawMbbHsRXHF1jq4sU4qUmamuLNEac5xOJeBTxdzRngaC6EtmggvFpeDQNzBfEnjqlyF
 kkMHZELhqRKdZOTonCvHjDnw9PHKi96Vw58fyG2uqO7QMiBPsMHipdkG3qjWrYD8f2JqIGhINM
 c+UwDnbW/QCNUqzdl/9kXK228F+YyshZCOxVp3UqgWEt8vi6SWRP9q5dtP4/NvUIoodDOdlHSE
 teYZeY+esE9p6Zdb2bxdK5ByLsxa8axvN/5P1NhOUMMbZVKuuOSTXsMPt9gmCzGZ7jQEAAA==
X-Change-ID: 20260320-b4-tyr-debugfs-3fcaff064297
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>
Cc: rust-for-linux@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=4986;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=r7SvsGcxUE/1ip/uZcdmaMCPXtz523zlbTXzbMVPaBI=;
 b=H86QYjvzfEG7hqFj25/RlEQ4Xs0U51a9bf236E7Or0Z4KgyK3lcrn8/8WFfRzLmitz/mxdZgi
 hnnX0b6/jh8DGMCqjuuA3zx2/pwXXrbNDzSc5VbACfObDsl7ZZkIo6x
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset contains:
- hazptr: Add hazard pointer abstraction to kernel::sync
- revocable: Introduce HazPtrRevocable, and adapt Gary Guo's downstream
  LazyRevocable implementation to use hazard pointers internally,
  enabling safe sharing of debugfs-root data across the tyr module and
  DRM driver
- drm: Add device and GEM helper functions to support debugfs
- tyr: Add debugfs infrastructure and interfaces to expose GEM/VM
  information

See the full dependency and commit history at [1].

Link: https://gitlab.freedesktop.org/panfrost/linux/-/issues/11
Link: https://gitlab.freedesktop.org/panfrost/linux/-/merge_requests/59 [1]
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Alvin Sun (11):
      rust: sync: set_once: Rename InitError variants to fix clippy warning
      rust: sync: add hazard pointer abstraction
      rust: revocable: add HazPtrRevocable
      rust: revocable: make LazyRevocable use HazPtrRevocable
      rust: drm: add Device::primary_index()
      rust: drm/gem: add GEM object query helpers for debugfs
      rust: drm/gem/shmem: add resident_size() and madv() for debugfs
      drm/tyr: expose Vm gpuvm_core, gpuvm and va_range as pub(crate)
      drm/tyr: add debugfs infrastructure
      drm/tyr: add vms and gpuvas debugfs interface
      drm/tyr: add gems field and gems debugfs interface

Gary Guo (2):
      rust: sync: support [pin_]init for `SetOnce`
      rust: revocable: add lazily instantiated revocable variant

 drivers/gpu/drm/tyr/debugfs.rs  | 190 ++++++++++++++++++++++++++++++++++++
 drivers/gpu/drm/tyr/driver.rs   |  18 +++-
 drivers/gpu/drm/tyr/fw.rs       |   7 +-
 drivers/gpu/drm/tyr/mmu.rs      |   6 +-
 drivers/gpu/drm/tyr/tyr.rs      |  39 +++++++-
 drivers/gpu/drm/tyr/vm.rs       |   6 +-
 rust/bindings/bindings_helper.h |   1 +
 rust/helpers/hazptr.c           |  13 +++
 rust/helpers/helpers.c          |   1 +
 rust/kernel/drm/device.rs       |  10 ++
 rust/kernel/drm/gem/mod.rs      |  49 +++++++++-
 rust/kernel/drm/gem/shmem.rs    |  21 ++++
 rust/kernel/revocable.rs        | 209 +++++++++++++++++++++++++++++++++++++++-
 rust/kernel/sync.rs             |   1 +
 rust/kernel/sync/hazptr.rs      |  91 +++++++++++++++++
 rust/kernel/sync/set_once.rs    | 120 +++++++++++++++++++----
 16 files changed, 746 insertions(+), 36 deletions(-)
---
base-commit: 34cb4f916af10153c87fabaf6c34e4cafa170427
change-id: 20260320-b4-tyr-debugfs-3fcaff064297
prerequisite-change-id: 20260202-io-81fd368f7565:v2
prerequisite-patch-id: 74873afed2b65f5a11c33f0c0c54375c55079109
prerequisite-patch-id: ae853e8eb8d58c77881371960be4ae92755e83c6
prerequisite-patch-id: 0ab78b50648c7d8f66b83c32ed2af0ec3ede42a3
prerequisite-patch-id: 8d20a8db8cf4660c682ee91f3db04e640c144e33
prerequisite-patch-id: 299de9cd2789c19c22e2816f7c817d80d5a4f1db
prerequisite-patch-id: 661ee334905f359daa8fb8d808ed5f4a8085f5c9
prerequisite-change-id: 20260117-register-ccaba1d21713:v9
prerequisite-patch-id: e4cb34ef09bccb92e1c35435e346b3a0459d3cdf
prerequisite-patch-id: 2c3c42ae9f3f4544c088dffbe4a0527f28b1c135
prerequisite-patch-id: 9f40e176e1b67bada943e376950debabb3f196d5
prerequisite-patch-id: ccc86d3ab9f62883c90d1275c99720942bd2bcb3
prerequisite-patch-id: 216427f1fdf94755cca0ed0676c4290f85d45e5c
prerequisite-patch-id: 7e1ea4d184297dfaba1351a7cb23e3b6827fed46
prerequisite-patch-id: 29ff9ffe37669d23b5509bfefb0cc1f8950eaa7c
prerequisite-patch-id: e5723722ff970c585cbf559456fa4cda05f28952
prerequisite-patch-id: afdae76e12011bb158d2008b8cd1ffba084db0bb
prerequisite-patch-id: b0473d5c7af0bbeec6f6ec8dd36d8a09cc180fed
prerequisite-message-id: <20260206223431.693765-1-lyude@redhat.com>
prerequisite-patch-id: 454c4fe7a7bcc65b2c9cc69dd5dd8e4c1d952297
prerequisite-patch-id: aff529cc205f5ab35518b8e4568e6e1319eecaa9
prerequisite-patch-id: 9f7d5c4a8ed052f5c5f2a28c862a9392d7a812cc
prerequisite-patch-id: ec9d104ba7c67488f19e6dd1a50d1ec4f682f333
prerequisite-patch-id: e7a844bd6254643d1f23827886b487c196ee9968
prerequisite-patch-id: 3c57ebf13497cf57c586b955d5ce90f2f9fd8cdc
prerequisite-patch-id: 1a327345ac71599ece0b2272fba81472f70c568c
prerequisite-change-id: 20251128-gpuvm-rust-b719cac27ad6:v5
prerequisite-patch-id: 6a8ddd47a2e1c769c65a942b3d9315e6ae5cae7e
prerequisite-patch-id: d4ee9fb80025c4fd8129c3477cc3dc36e13076cb
prerequisite-patch-id: 0ad35cd3dfcf8a8804e9fed8df3e5612cf07da69
prerequisite-patch-id: 275a900645e14169911ee00bab54553c84b48ad0
prerequisite-patch-id: 2a2de2f6c4fac065de5c459026daa2c32f340d22
prerequisite-patch-id: 9a721bc700da778f2554cf32917dda4807744520
prerequisite-message-id: <20260131001602.2095470-1-lyude@redhat.com>
prerequisite-patch-id: 6c622d1df9166ad081acba46237f8cecbf728356
prerequisite-patch-id: 769892e477c161e6c7a57519ec635b1455310f1d
prerequisite-patch-id: 3c5f5070ded87e95a8045083a55501fbbe9f6313
prerequisite-patch-id: 10fbd8695264e67421946dda4d39e29d5fe77c64

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

