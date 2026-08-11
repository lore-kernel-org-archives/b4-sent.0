From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 11 Aug 2026 14:51:36 +0800
Subject: [PATCH] rust: block: gen_disk: set fops.owner from driver module
 pointer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260811-fix-gendisk-owner-v1-1-c0fe4a449ecb@linux.dev>
X-B4-Tracking: v=1; b=H4sIAHfGemoC/02OS47CMBBEr2L1eoz8SdKOr4JY2J02WCMSsENmJ
 MTdxwqzYPlKXdXvCZVL5gpePKHwlmte5gb6SwBdwnxmmafGYJQZlNNKpvwrzzxPuX7L5WfmIoP
 rJoWmD9FEaL1b4Xa0bx5Pby58f7Tp9R1CDJUlLddrXr3Y8GBkIdyrYaVL++iF7ZD6YGmYIqfRW
 RMTsev0mMhYHli5GDrEBJ+iXuyavR53zbTc6r8j24AYo0EayG9awen1+gPRm4Dd/AAAAA==
X-Change-ID: 20260810-fix-gendisk-owner-a84d0725ab2b
To: Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Miguel Ojeda <ojeda@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-block@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786431097; l=3831;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=pbm5nJARrive7EbKpkhyo8U1Z4SlieWC4PcXBCGvFvM=;
 b=T2ZchLdFCUfJ9WJciOwxNBzqrG3yMEJJcvWk+STpLw942FWZhVz/5uiYk3Bkx3TefgwMt8OcQ
 S8YbB8njRigC12DooF4toA7GBCkvnR5XylzIjA7XUofshKJlfno4VZ5
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Set `fops.owner` from the driver module pointer via
`this_module::<T::OwnerModule>().as_ptr()` instead of defaulting to
null, so the module cannot be unloaded while a block device is still
in use.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
The fops.owner fix series [1] covered DRM, miscdevice, configfs and
binder, but missed the block layer's `GenDisk` abstraction.

This patch was meant to be sent separately, but I forgot to send it.

[1] https://lore.kernel.org/r/20260723-fix-fops-owner-v9-0-c1c3af7f7bcb@linux.dev/
---
 rust/kernel/block/mq/gen_disk.rs | 34 ++++++++++------------------------
 1 file changed, 10 insertions(+), 24 deletions(-)

diff --git a/rust/kernel/block/mq/gen_disk.rs b/rust/kernel/block/mq/gen_disk.rs
index fc97dd8739746..215c407d466df 100644
--- a/rust/kernel/block/mq/gen_disk.rs
+++ b/rust/kernel/block/mq/gen_disk.rs
@@ -125,30 +125,9 @@ pub fn build<T: Operations>(
             )
         })?;
 
-        const TABLE: bindings::block_device_operations = bindings::block_device_operations {
-            submit_bio: None,
-            open: None,
-            release: None,
-            ioctl: None,
-            compat_ioctl: None,
-            check_events: None,
-            unlock_native_capacity: None,
-            getgeo: None,
-            set_read_only: None,
-            swap_slot_free_notify: None,
-            report_zones: None,
-            devnode: None,
-            alternative_gpt_sector: None,
-            get_unique_id: None,
-            // TODO: Set to `THIS_MODULE`.
-            owner: core::ptr::null_mut(),
-            pr_ops: core::ptr::null_mut(),
-            free_disk: None,
-            poll_bio: None,
-        };
-
-        // SAFETY: `gendisk` is a valid pointer as we initialized it above
-        unsafe { (*gendisk).fops = &TABLE };
+        // SAFETY: `gendisk` is a valid pointer. We have exclusive access,
+        // since the disk is not added to the VFS yet.
+        unsafe { (*gendisk).fops = &GenDisk::<T>::VTABLE };
 
         let cleanup_failure = ScopeGuard::new_with_data((gendisk, data), |(gendisk, data)| {
             // SAFETY: `gendisk` came from `__blk_mq_alloc_disk()` above and
@@ -211,6 +190,13 @@ pub struct GenDisk<T: Operations> {
     gendisk: *mut bindings::gendisk,
 }
 
+impl<T: Operations> GenDisk<T> {
+    const VTABLE: bindings::block_device_operations = bindings::block_device_operations {
+        owner: crate::module::this_module::<T::OwnerModule>().as_ptr(),
+        ..pin_init::zeroed()
+    };
+}
+
 // SAFETY: `GenDisk` is an owned pointer to a `struct gendisk` and an `Arc` to a
 // `TagSet` It is safe to send this to other threads as long as T is Send.
 unsafe impl<T: Operations + Send> Send for GenDisk<T> {}

---
base-commit: 2ee859ebf156157609f71060ae472711c8cbc326
change-id: 20260810-fix-gendisk-owner-a84d0725ab2b
prerequisite-patch-id: 347c5a3c6dbef9832bfce8419fc23e6e08ba477f
prerequisite-change-id: 20260519-fix-fops-owner-e3a77bb27c6c:v10
prerequisite-patch-id: 347c5a3c6dbef9832bfce8419fc23e6e08ba477f
prerequisite-patch-id: 190cfd53d3430ade053b15db36cac9e372e2566d
prerequisite-patch-id: fdb2387ea1074c3bf16028b58c3df73e2e1783b1
prerequisite-patch-id: f38222c64f7d29781036ae8673808cf4e9a9d430
prerequisite-patch-id: da94d5d3af25778145b976f65f7eac281dc6ae79
prerequisite-patch-id: e5c034ff639d7eebe730922db0ed02492f401dd0
prerequisite-patch-id: 502035d4e05da3ed939b8bd65801a6fd8a01d788
prerequisite-patch-id: 0ccf22bbdee039964cb064f33a8c7a0925dbd57b
prerequisite-patch-id: e0595d6120868cdf3e87fa335a81e10f0e346c80
prerequisite-patch-id: f27fc645020b296d289c31fc73dbfef993294464
prerequisite-patch-id: 159f88cf73892b94117070090a58c7b68e08b8c1

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

