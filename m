From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH v5 0/9] Fix missing fops.owner in Rust DRM/misc
 abstractions
Date: Wed, 24 Jun 2026 20:57:23 +0800
Message-Id: <20260624-fix-fops-owner-v5-0-aa1cba242f05@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADPUO2oC/3XPy27DIBAF0F+xWJeIhzHBq/5HlQWPoUGqTQI2S
 RX530sdqbVqdTmIc+/MA2VIATLqmwdKUEIOcayDeGmQPevxHXBwdUaMsI4IqrAPd+zjJeN4GyF
 h4FpKY5i0nUUVXRLUH2vg2+k5J7jONXd6PiKjM2AbhyFMfVPkgeJkJdr29c1P2xCydVDwXI2Pa
 dATVtpIOHJDLaV94ei75RzyFNPnekWha81/CxeKCWYOnDpy4jRtXz/CON8PtWWNKmzDGd1xVrl
 3ShGprNBkx/kv7xjbcV55q1wrrOGScPaXt1vOd7ytvG7thSdSOmG3fFmWLyxAcufPAQAA
X-Change-ID: 20260519-fix-fops-owner-e3a77bb27c6c
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Arnd Bergmann <arnd@arndb.de>, Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>, Rae Moar <raemoar63@gmail.com>, 
 Breno Leitao <leitao@debian.org>, Jens Axboe <axboe@kernel.dk>, 
 Dave Ertman <david.m.ertman@intel.com>, Leon Romanovsky <leon@kernel.org>, 
 Igor Korotin <igor.korotin@linux.dev>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-modules@vger.kernel.org, 
 driver-core@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 nova-gpu@lists.linux.dev, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-block@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-pci@vger.kernel.org, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782305851; l=8727;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=S8BpAUMxXmLbUpuQFq+mwTLqJlR9c4l9ytkf4UReLGo=;
 b=qdjRUUm+rexqQr5dKVAf/YsvjDB2bcHw6yDQWRe6yt3QYSgSLCACzc3uMn6rSpAxCUCszszZJ
 fnuD5IJBKcpAe03VNg/6TQi+YRVtfa/W+/H3XcsSyugJZAjUz8nk4nA
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

During tyr debugfs development, a kernel NULL pointer dereference was
encountered after `rmmod tyr` while gnome-shell still held /dev/card1 open:

```
  [158827.868132] Unable to handle kernel NULL pointer dereference at virtual address 0000000000000000
  [158827.868918] Mem abort info:
  [158827.869177]   ESR = 0x0000000086000004
  [158827.869519]   EC = 0x21: IABT (current EL), IL = 32 bits
  [158827.870000]   SET = 0, FnV = 0
  [158827.870281]   EA = 0, S1PTW = 0
  [158827.870571]   FSC = 0x04: level 0 translation fault
  [158827.871043] user pgtable: 4k pages, 48-bit VAs, pgdp=0000000108dec000
  [158827.871623] [0000000000000000] pgd=0000000000000000, p4d=0000000000000000
  [158827.872242] Internal error: Oops: 0000000086000004 [#1]  SMP
  [158827.872246] Modules linked in: tyr sunrpc snd_soc_simple_card rk805_pwrkey snd_soc_simple_card_utils rtw88_8822bu display_connector rtw88_usb rtw88_8822b snd_soc_rockchip_i2s_tdm snd_soc_hdmi_codec
  rtw88_core]
  [158827.872337] CPU: 4 UID: 1000 PID: 11276 Comm: gnome-s:disk$0 Tainted: G                 N  7.1.0-rc1+ #331 PREEMPT
  [158827.880534] Tainted: [N]=TEST
  [158827.880535] Hardware name: FriendlyElec NanoPi R6C/NanoPi R6C, BIOS v1.1 04/09/2025
  [158827.880538] pstate: 60400009 (nZCv daif +PAN -UAO -TCO -DIT -SSBS BTYPE=--)
  [158827.880542] pc : 0x0
  [158827.880547] lr : _RNvNtCs257m05FHVbX_3tyr2vm8pt_unmap+0x8c/0x12c [tyr]
  [158827.880578] sp : ffff800083c236b0
  [158827.880579] x29: ffff800083c236d0 x28: ffff00013f8a0000 x27: 0000000000000000
  [158827.880585] x26: 000000000000007c x25: ffff000108e6ed80 x24: 0000000000401000
  [158827.880590] x23: 0000000000000000 x22: 0000000040000000 x21: 0000000000001000
  [158827.880595] x20: ffff00010f778138 x19: 0000000000400000 x18: 00000000ffffffff
  [158827.880600] x17: 000000040044ffff x16: 045000f2b5503510 x15: 0720072007200720
  [158827.880606] x14: 0720072007200720 x13: 0000000000401000 x12: 0000000000400000
  [158827.880611] x11: ffff800083c239d0 x10: ffff000141e4fd88 x9 : 0000000000000000
  [158827.880615] x8 : 0000000000000000 x7 : 0000000000000000 x6 : 0000000000400000
  [158827.880620] x5 : ffff00013f8a0000 x4 : 0000000000000000 x3 : 0000000000000001
  [158827.880625] x2 : 0000000000001000 x1 : 0000000000400000 x0 : ffff00010f778138
  [158827.880630] Call trace:
  [158827.880632]  0x0 (P)
  [158827.880635]  _RNvXs6_NtCs257m05FHVbX_3tyr2vmNtB5_9GpuVmDataNtNtNtCsgmSOfgXi5CZ_6kernel3drm5gpuvm11DriverGpuVm13sm_step_unmap+0x3c/0x120 [tyr]
  [158827.891166]  _RNvMs4_NtNtNtCsgmSOfgXi5CZ_6kernel3drm5gpuvm6sm_opsINtB7_5GpuVmNtNtCs257m05FHVbX_3tyr2vm9GpuVmDataE13sm_step_unmapB13_+0x18/0x34 [tyr]
  [158827.891187]  op_unmap_cb+0x78/0xb0
  [158827.891196]  __drm_gpuvm_sm_unmap+0x18c/0x1b4
  [158827.891204]  drm_gpuvm_sm_unmap+0x38/0x4c
  [158827.891209]  _RNvMs5_NtCs257m05FHVbX_3tyr2vmNtB5_2Vm7exec_op+0x1cc/0x254 [tyr]
  [158827.894085]  _RNvMs5_NtCs257m05FHVbX_3tyr2vmNtB5_2Vm11unmap_range+0x124/0x188 [tyr]
  [158827.894105]  _RINvNtCs5hGKnPbRUFW_4core3ptr13drop_in_placeNtNtCs257m05FHVbX_3tyr3gem8KernelBoEBK_+0x44/0xd8 [tyr]
  [158827.894125]  _RINvNtCs5hGKnPbRUFW_4core3ptr13drop_in_placeINtNtNtCsgmSOfgXi5CZ_6kernel5alloc4kvec3VecNtNtCs257m05FHVbX_3tyr2fw7SectionNtNtBL_9allocator7KmallocEEB1r_+0x3c/0x100 [tyr]
  [158827.894147]  _RINvNtCs5hGKnPbRUFW_4core3ptr13drop_in_placeINtNtNtCsgmSOfgXi5CZ_6kernel4sync3arc3ArcNtNtCs257m05FHVbX_3tyr2fw8FirmwareEEB1p_+0x94/0x190 [tyr]
  [158827.894167]  _RNvMs4_NtNtCsgmSOfgXi5CZ_6kernel3drm6deviceINtB5_6DeviceNtNtCs257m05FHVbX_3tyr6driver12TyrDrmDriverE7releaseBW_+0x30/0x98 [tyr]
  [158827.899550]  drm_dev_put.part.0+0x88/0xc0
  [158827.899557]  drm_minor_release+0x18/0x28
  [158827.899562]  drm_release+0x144/0x170
  [158827.899567]  __fput+0xe4/0x30c
  [158827.899573]  ____fput+0x14/0x20
  [158827.899579]  task_work_run+0x7c/0xe8
  [158827.899586]  do_exit+0x2a8/0xac4
  [158827.899590]  do_group_exit+0x34/0x90
  [158827.899594]  get_signal+0xaac/0xabc
  [158827.899599]  arch_do_signal_or_restart+0x90/0x3e8
  [158827.899606]  exit_to_user_mode_loop+0x140/0x1d0
  [158827.899613]  el0_svc+0x2f4/0x2f8
  [158827.899620]  el0t_64_sync_handler+0xa0/0xe4
  [158827.899627]  el0t_64_sync+0x198/0x19c
  [158827.899632] ---[ end trace 0000000000000000 ]---
```

The root cause: `fops.owner` was `NULL` in Rust DRM drivers, so the kernel
never blocked module unloading while file descriptors were open. This leads to
use-after-free when drm_release (or other fops) is called on freed module code.

The series moves `THIS_MODULE` into the `ModuleMetadata` as a const, threads it
through `#[vtable]` to set `fops.owner` in DRM/miscdevice, and updates configfs
and rnull to use `this_module::<LocalModule>()`.

Assisted-by: opencode:glm-5.2
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Changes in v5:
- Add `#[inline]` to the `this_module()` helper.
- Fix configfs doc comment to reference `crate::LocalModule` instead of
  bare `LocalModule`.
- Link to v4: https://lore.kernel.org/r/20260623-fix-fops-owner-v4-0-0daf5f077d5c@linux.dev

Changes in v4:
- Move module-related types into a new `rust/kernel/module.rs`.
- Migrate binder from the `module!`-generated `THIS_MODULE` static to
  `this_module::<LocalModule>()`.
- Reorganise the series so that every commit builds independently, and
  drop the legacy `THIS_MODULE` static once all users are migrated.
- Link to v3: https://lore.kernel.org/r/20260622-fix-fops-owner-v3-0-49d45cb37032@linux.dev

Changes in v3:
- Renamed vtable associated type `ThisModule` to `OwnerModule`
- Added `this_module()` helper for ergonomic `THIS_MODULE` access
- Refined vtable macro implementation: one-liner detection and single `defined_items` set
- Reordered commits to place doctest fallback before vtable auto-insert
- Link to v2: https://lore.kernel.org/r/20260521-fix-fops-owner-v2-0-fd99079c5a04@linux.dev

Changes in v2:
- Merged old `static THIS_MODULE` and v1's `MODULE_PTR` into a single
  `ModuleMetadata::THIS_MODULE` const
- `#[vtable]` macro now auto-inserts `type ThisModule`, removing all per-driver
  manual patches from v1
- Added configfs & rnull usage site updates and doctest `LocalModule` fallback
- Link to v1: https://lore.kernel.org/r/20260519-fix-fops-owner-v1-0-2ded9830da14@linux.dev

---
Alvin Sun (9):
      rust: module: move module types into `module.rs`
      rust: module: add `THIS_MODULE` const to `ModuleMetadata` trait
      rust: doctest: add LocalModule fallback for #[vtable] ThisModule
      rust: macros: auto-insert OwnerModule in #[vtable]
      rust: drm: set fops.owner from driver module pointer
      rust: miscdevice: set fops.owner from driver module pointer
      rust: configfs: use `LocalModule` for `THIS_MODULE`
      rust: binder: use `LocalModule` for `THIS_MODULE`
      rust: macros: remove `THIS_MODULE` static from `module!`

 drivers/android/binder/rust_binder_main.rs |  3 +-
 drivers/block/rnull/configfs.rs            |  6 +--
 rust/kernel/auxiliary.rs                   |  2 +-
 rust/kernel/configfs.rs                    |  8 +--
 rust/kernel/drm/device.rs                  |  3 +-
 rust/kernel/drm/gem/mod.rs                 |  4 +-
 rust/kernel/i2c.rs                         |  2 +-
 rust/kernel/lib.rs                         | 75 +++-------------------------
 rust/kernel/miscdevice.rs                  |  4 +-
 rust/kernel/module.rs                      | 80 ++++++++++++++++++++++++++++++
 rust/kernel/net/phy.rs                     |  6 ++-
 rust/kernel/pci.rs                         |  2 +-
 rust/kernel/platform.rs                    |  2 +-
 rust/kernel/usb.rs                         |  2 +-
 rust/macros/lib.rs                         |  6 +++
 rust/macros/module.rs                      | 34 ++++++-------
 rust/macros/vtable.rs                      | 41 +++++++++++++--
 scripts/rustdoc_test_gen.rs                | 16 ++++++
 18 files changed, 188 insertions(+), 108 deletions(-)
---
base-commit: b7e5ac83cb16f7ffd11dc23736f84276602100ed
change-id: 20260519-fix-fops-owner-e3a77bb27c6c
prerequisite-change-id: 20260519-miscdev-use-format-9ab7e83b1c11:v3
prerequisite-patch-id: 405b334ff0d48ad350014f05a2321bdbaa025400
prerequisite-patch-id: 604b631c81d5423f4ebb2e12ba2d22e9ce371bfc
prerequisite-patch-id: cb550d94cefe01920e0d3ced2b2bcbecd76f3907
prerequisite-patch-id: 3bc830839742591460cb86d9472c04f4686dc600
prerequisite-patch-id: 571058244bc8c7088638d2e3225713011246c7e9
prerequisite-patch-id: 347c5a3c6dbef9832bfce8419fc23e6e08ba477f
prerequisite-patch-id: 3e202d988b56b88446f7535e90d3f00cf5f15701

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

