From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 26 Nov 2026 18:39:33 +0100
Subject: [PATCH v2] rust: drm: enable standard fdinfo for Rust drivers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-fix-drm-rust-fdinfo-v2-1-b1653edf1e4f@gmail.com>
X-B4-Tracking: v=1; b=H4sIANRuCGsC/32OQQ6CMBBFr0K6dpQBIuDKexgWpZ1CjbSmBYIh3
 N0Wo0uXb/Lm5a/Mk9Pk2SVZmaNZe21NgOyQMNFz0xFoGZhlaXZGxBqUXkC6AdzkR1BSG2WhIix
 ViVLWImfh8+koaHv11nzYT+2dxBhT0Wi5J2gdN6KPp2/w9CsbWsYo9tqP1r32fTPG4P8pMwKCw
 FQVmBdFVclrN3D9OAo7sGbbtjeTtMqY8QAAAA==
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
 linux-kernel@vger.kernel.org, linux-api@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795714775; l=2361;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=Q2j2ETDtWfIZSvsCcbvYzOAWgDMeNdy/ivFkVQ1rlgI=;
 b=YYMlzYjjLBwQBVI/TNvkEOL/k8jXJiwB84BgOOL63cPbtrPY3kuMOpeybnCbtCTlUNTMtE5iS
 de4hmC1qM6jBEaYPOQWBjk4ig7ze5HxEge8udesd6l5BdVExQZ7ioNV
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

DRM monitoring tools use drm-driver and drm-client-id in procfs fdinfo
to identify DRM clients. The common Rust DRM file operations leave
show_fdinfo unset, so these entries are missing for those clients.

Set show_fdinfo to drm_show_fdinfo. The DRM core helper emits the
standard client information. Rust DRM does not yet expose the optional
driver-specific statistics hook.

Closes: https://github.com/Rust-for-Linux/linux/issues/1266
Tested-by: Janne Grunau <j@jannau.net>
Reviewed-by: Janne Grunau <j@jannau.net>
Reviewed-by: Gary Guo <gary@garyguo.net>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Danilo, VTABLE.fops points to UnregisteredDevice::FOPS. Procfs calls
FOPS.show_fdinfo, so this patch installs drm_show_fdinfo there. The helper
calls VTABLE.show_fdinfo when the driver supplies additional statistics.

Matt Mireles reported the missing fdinfo fields on an Asahi kernel and
suggested using this helper.

Janne Grunau tested v1 with the downstream Asahi driver on Apple silicon.

OpenAI Codex assisted with coding and testing.
---
Changes in v2:
- Rebase onto drm-rust-next and set the callback in UnregisteredDevice::FOPS
  now that the file operations have moved to drm::device.
- Drop the Fixes tag and clarify that Rust DRM has yet to expose the
  optional driver statistics hook.
- Add the Reviewed-by and Tested-by tags from v1.
- Link to v1: https://patch.msgid.link/20261119-fix-drm-rust-fdinfo-v1-1-c10f4134488d@gmail.com
---
 rust/kernel/drm/device.rs | 1 +
 1 file changed, 1 insertion(+)

diff --git a/rust/kernel/drm/device.rs b/rust/kernel/drm/device.rs
index 1c5b0abb492be..c460ba3706bf9 100644
--- a/rust/kernel/drm/device.rs
+++ b/rust/kernel/drm/device.rs
@@ -273,6 +273,7 @@ extern "C" fn fops_open(inode: *mut bindings::inode, filp: *mut bindings::file)
         fops.read = Some(bindings::drm_read);
         fops.llseek = Some(bindings::noop_llseek);
         fops.mmap = Some(bindings::drm_gem_mmap);
+        fops.show_fdinfo = Some(bindings::drm_show_fdinfo);
         fops.fop_flags = bindings::FOP_UNSIGNED_OFFSET;
 
         fops

---
base-commit: 4325f4aad9727a6e8e7f10c5d2ebf490470cf938
change-id: 20261119-fix-drm-rust-fdinfo-8e17f71dd9c3

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

