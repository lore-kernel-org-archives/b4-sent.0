From: Timothy Garwood <gtimothy-dev@protonmail.com>
Date: Tue, 28 Jan 2025 18:12:49 +0100
Subject: [PATCH RFC] rust: HrTimerMode replacement with bitfield_options
 macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250128-bitfield-option-hrtimer-v1-1-31033d8e727f@protonmail.com>
X-B4-Tracking: v=1; b=H4sIABAQmWcC/12OzW4CMQyEX2Xlc13FYUlIrpV4AK6IQ368JVKXp
 UmIkBDv3rRFqOpx7Jlv5gaFc+ICdrhB5pZKWk5d0MsA4ehO74wpdg1SyLUgqdGnOiX+iLica/f
 iMdc0c0bNgc1E2niK0NPnzFO6/pD3sNu+weH3mPnz0lvq4/MssUOvGEmQfiLbCptCkpiDREnrG
 JQnZfxkm4K/Ax9ZEht0Mf6fWHB2IS/oNqP2K2NIOGeb/CZ4VxjDMs+p2iFfSkX1SiMc7vcvzvu
 GsBkBAAA=
X-Change-ID: 20250127-bitfield-option-hrtimer-7ece9f179b1d
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>
Cc: Andreas Hindborg <a.hindborg@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Timothy Garwood <gtimothy-dev@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1738084388; l=6528;
 i=gtimothy-dev@protonmail.com; s=20250123; h=from:subject:message-id;
 bh=affPqQwr4VVR21U7swKhRZpKaHYPLTxharXdiQNSgC4=;
 b=VJ/iKV8Q7wRnm7BTJCbWaD+dOCiWMaHQBFzn3IiVRplfKSyfdc1W7v0PRK83cr8pkmGddh526
 ow4r8fFvaR2CHyBD/up985X30u/D+RhJLdzVUpA+1jvbKIpZYizMhzy
X-Developer-Key: i=gtimothy-dev@protonmail.com; a=ed25519;
 pk=4MkQh/a3f6vfOYMYyJPEDyETzhXD/Sa4ZNZ/kAKxOOs=
X-Endpoint-Received: by B4 Relay for gtimothy-dev@protonmail.com/20250123 with auth_id=330
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

replace the HrTimerMode enum with a bitfield wrapper built using the
bitfield_options macro

---
This patch provides an example of usage of the bitfield_options macro
proposed in [1] as a replacement for the HrTimerMode enum introduced in
[2].
[1] is a RFC.
This patch depends on both [1] and [2]

Link:
https://lore.kernel.org/rust-for-linux/20250128-add-bitfield-options-macro-v2-1-d65349b389fc@protonmail.com
Link:
https://lore.kernel.org/rust-for-linux/20250110-hrtimer-v3-v6-12-rc2-v6-0-f71d50f16482@kernel.org
[2]

Signed-off-by: Timothy Garwood <gtimothy-dev@protonmail.com>
---
 rust/kernel/time/hrtimer.rs | 82 ++++++++++-----------------------------------
 1 file changed, 17 insertions(+), 65 deletions(-)

diff --git a/rust/kernel/time/hrtimer.rs b/rust/kernel/time/hrtimer.rs
index f759e4b1aa9f9fa6d55d5c144deedccc5d0590ae..ecbd7ebd7bf319291fec5bc5de31fe4a36d03c24 100644
--- a/rust/kernel/time/hrtimer.rs
+++ b/rust/kernel/time/hrtimer.rs
@@ -364,75 +364,27 @@ fn from(value: HrTimerRestart) -> Self {
     }
 }
 
-/// Operational mode of [`HrTimer`].
-#[derive(Clone, Copy)]
-pub enum HrTimerMode {
-    /// Timer expires at the given expiration time.
-    Absolute,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    Relative,
-    /// Timer does not move between CPU cores.
-    Pinned,
-    /// Timer handler is executed in soft irq context.
-    Soft,
-    /// Timer handler is executed in hard irq context.
-    Hard,
-    /// Timer expires at the given expiration time.
-    /// Timer does not move between CPU cores.
-    AbsolutePinned,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    /// Timer does not move between CPU cores.
-    RelativePinned,
-    /// Timer expires at the given expiration time.
-    /// Timer handler is executed in soft irq context.
-    AbsoluteSoft,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    /// Timer handler is executed in soft irq context.
-    RelativeSoft,
-    /// Timer expires at the given expiration time.
-    /// Timer does not move between CPU cores.
-    /// Timer handler is executed in soft irq context.
-    AbsolutePinnedSoft,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    /// Timer does not move between CPU cores.
-    /// Timer handler is executed in soft irq context.
-    RelativePinnedSoft,
-    /// Timer expires at the given expiration time.
-    /// Timer handler is executed in hard irq context.
-    AbsoluteHard,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    /// Timer handler is executed in hard irq context.
-    RelativeHard,
-    /// Timer expires at the given expiration time.
-    /// Timer does not move between CPU cores.
-    /// Timer handler is executed in hard irq context.
-    AbsolutePinnedHard,
-    /// Timer expires after the given expiration time interpreted as a duration from now.
-    /// Timer does not move between CPU cores.
-    /// Timer handler is executed in hard irq context.
-    RelativePinnedHard,
+kernel::bitfield_options! {
+    name: HrTimerMode,
+    type: bindings::hrtimer_mode,
+    options: [
+        {name: relative,
+            true: bindings::hrtimer_mode_HRTIMER_MODE_REL,
+            false: bindings::hrtimer_mode_HRTIMER_MODE_ABS
+        },
+        {name: pinned,
+            true: bindings::hrtimer_mode_HRTIMER_MODE_PINNED,
+            false: 0},
+        {name: hard,
+            true: bindings::hrtimer_mode_HRTIMER_MODE_HARD,
+            false: bindings::hrtimer_mode_HRTIMER_MODE_SOFT}
+    ]
 }
 
 impl From<HrTimerMode> for bindings::hrtimer_mode {
     fn from(value: HrTimerMode) -> Self {
-        use bindings::*;
-        match value {
-            HrTimerMode::Absolute => hrtimer_mode_HRTIMER_MODE_ABS,
-            HrTimerMode::Relative => hrtimer_mode_HRTIMER_MODE_REL,
-            HrTimerMode::Pinned => hrtimer_mode_HRTIMER_MODE_PINNED,
-            HrTimerMode::Soft => hrtimer_mode_HRTIMER_MODE_SOFT,
-            HrTimerMode::Hard => hrtimer_mode_HRTIMER_MODE_HARD,
-            HrTimerMode::AbsolutePinned => hrtimer_mode_HRTIMER_MODE_ABS_PINNED,
-            HrTimerMode::RelativePinned => hrtimer_mode_HRTIMER_MODE_REL_PINNED,
-            HrTimerMode::AbsoluteSoft => hrtimer_mode_HRTIMER_MODE_ABS_SOFT,
-            HrTimerMode::RelativeSoft => hrtimer_mode_HRTIMER_MODE_REL_SOFT,
-            HrTimerMode::AbsolutePinnedSoft => hrtimer_mode_HRTIMER_MODE_ABS_PINNED_SOFT,
-            HrTimerMode::RelativePinnedSoft => hrtimer_mode_HRTIMER_MODE_REL_PINNED_SOFT,
-            HrTimerMode::AbsoluteHard => hrtimer_mode_HRTIMER_MODE_ABS_HARD,
-            HrTimerMode::RelativeHard => hrtimer_mode_HRTIMER_MODE_REL_HARD,
-            HrTimerMode::AbsolutePinnedHard => hrtimer_mode_HRTIMER_MODE_ABS_PINNED_HARD,
-            HrTimerMode::RelativePinnedHard => hrtimer_mode_HRTIMER_MODE_REL_PINNED_HARD,
-        }
+        use kernel::bitfield::BitField;
+        value.bits()
     }
 }
 

---
base-commit: b9a6cbc3bad5eaf0e413c9487d8a0f2d3309bf0c
change-id: 20250127-bitfield-option-hrtimer-7ece9f179b1d
prerequisite-change-id: 20241017-hrtimer-v3-v6-12-rc2-215dc6b169bf:v6
prerequisite-patch-id: 23d01479b2ab6b48af65eb681817c753f2b36874
prerequisite-patch-id: 407fc78a43b558f7c6d9cde9a7bf211a06185afb
prerequisite-patch-id: d8f3138d942b3ebfa3549cf54f6bb1c522401ba9
prerequisite-patch-id: 11beab205013c97d7e9a686352b1359910b5938b
prerequisite-patch-id: 84bfb19dfd05dba3aac82b4f2b0031cf6aee8566
prerequisite-patch-id: fada7846a89465ac08b4ab049f9bc626abc27589
prerequisite-patch-id: 526e62d0d80535f4c1b2edb62ee8b7a0f6d86f78
prerequisite-patch-id: 201342b1c7635b147218cefdeded3bc326f59503
prerequisite-patch-id: 271bb7aa324adcf71bdc3c8fcfaefa269ed8ab74
prerequisite-patch-id: 75c30cfa3e81a8d4895567c16aa0b279616d0bdd
prerequisite-patch-id: 68c2afbd51b25083614b2d963b6d32cbb3c3bb9a
prerequisite-patch-id: 37d31228bd445445dbb1baa23ea83ab1e5c7a47b
prerequisite-patch-id: fa49bf80231519c5397367f2d9467f3c28868620
prerequisite-patch-id: d1c5ffd588712325a3372dd4f582ace4debd594d
prerequisite-change-id: 20241108-add-bitfield-options-macro-a847b39910aa:v2
prerequisite-patch-id: 7db40a5cde7387419cd346305da28e2c4932eca1

Best regards,
-- 
Timothy Garwood <gtimothy-dev@protonmail.com>

