From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 19 Nov 2026 10:48:47 +0100
Subject: [PATCH] rust: drm: enable standard fdinfo for Rust drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-fix-drm-rust-fdinfo-v1-1-c10f4134488d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAP7F/moC/0WM0QrCMAxFf2Xk2aCZ4Jy/IntY29RFsJNkE2Hs3
 20n4uO53HMWMFZhg0u1gPJLTMaUgXYV+KFPN0YJmaE+1CciajHKG4M+UGebMAZJccQzUxMbCqH
 1R8jmUznftuq1+7LN7s5+KqnycL0xOu2TH8r0C+7/5c1f1w8kFOGgoQAAAA==
X-Change-ID: 20261119-fix-drm-rust-fdinfo-8e17f71dd9c3
To: Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>
Cc: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Asahi Lina <lina+kernel@asahilina.net>, Lyude Paul <lyude@redhat.com>, 
 dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-api@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795081726; l=1843;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=xxqWVMVxZbBkPwfGR3DEyfjXL1JPRrrX4MkbzxGWQrE=;
 b=rPGVsN+1pazjTfjzZNIzCQIkNRmJM51jRUZ7lIiSyXuBw8ULl6w8n77Lj/7Cw4gLW85fu/kcM
 4snU6fRBnW0DNdVdLHz9Y6n9NGKz3jLwgSUWfzSlS2DrR/b8IgOqxz5
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DRM monitoring tools use drm-driver and drm-client-id in procfs fdinfo
to identify DRM clients. The common Rust DRM file operations leave
show_fdinfo unset, so these entries are missing for those clients.

Set show_fdinfo to drm_show_fdinfo. The DRM core helper emits the
standard client information and calls the separate driver statistics
hook if the driver provides one.

Fixes: c284d3e42338 ("rust: drm: gem: Add GEM object abstraction")
Closes: https://github.com/Rust-for-Linux/linux/issues/1266
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Matt Mireles reported the missing fdinfo fields on an Asahi kernel and
suggested using this helper.

The x86-64 LLVM=1 CLIPPY=1 build adds the drm_show_fdinfo callback to
nova-drm.ko's file operations table.

The pending move of the file operations into drm::device [1] should
carry this assignment into UnregisteredDevice::FOPS.

[1] https://lore.kernel.org/dri-devel/20261118163203.2483856-4-dakr@kernel.org/

OpenAI Codex assisted with coding and testing.
---
 rust/kernel/drm/gem/mod.rs | 1 +
 1 file changed, 1 insertion(+)

diff --git a/rust/kernel/drm/gem/mod.rs b/rust/kernel/drm/gem/mod.rs
index 85657a39e146..b37695f870d4 100644
--- a/rust/kernel/drm/gem/mod.rs
+++ b/rust/kernel/drm/gem/mod.rs
@@ -388,6 +388,7 @@ pub(super) const fn create_fops(owner: *mut bindings::module) -> bindings::file_
     fops.read = Some(bindings::drm_read);
     fops.llseek = Some(bindings::noop_llseek);
     fops.mmap = Some(bindings::drm_gem_mmap);
+    fops.show_fdinfo = Some(bindings::drm_show_fdinfo);
     fops.fop_flags = bindings::FOP_UNSIGNED_OFFSET;
 
     fops

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261119-fix-drm-rust-fdinfo-8e17f71dd9c3

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

