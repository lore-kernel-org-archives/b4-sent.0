From: Dave Airlie <airlied@redhat.com>
Date: Wed, 11 Nov 2026 15:23:24 +1000
Subject: [PATCH v7 1/2] rust: time: expose as_nanos for clock sources.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-nova-timer-v7-1-3031c2476551@redhat.com>
References: <20261111-nova-timer-v7-0-3031c2476551@redhat.com>
In-Reply-To: <20261111-nova-timer-v7-0-3031c2476551@redhat.com>
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Alexandre Courbot <acourbot@nvidia.com>
Cc: nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 Dave Airlie <airlied@redhat.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=890; i=airlied@redhat.com;
 h=from:subject:message-id; bh=3VDfb37tDtN07HLm+c2mhReutHmj5DLfx9YKQGaiDDc=;
 b=owEBbQKS/ZANAwAKAQx081l5xIa+AcsmYgBq8/vSkG3bdpelMCxucgoWBPx4cJxEDlRmt/Azw
 hHaVrTnRwWJAjMEAAEKAB0WIQQQptkdobBb0p9t66wMdPNZecSGvgUCavP70gAKCRAMdPNZecSG
 vqwAD/4xYad2O1hVWkteur7JpWt4xlI5qAJ5V0++0k1no4GDrZ5XEUbsoRvT1rWf9HhP4re/rug
 FsPKhwXTbgi2krQpPdGGi2Lfi7IpL2mhC4f4jbK+1GUQPIQzECj4rd3pBsrdpMBUyWEGhfFMK0o
 /GY2MkJuHBBIQ00tTIn3Hp3Dc6QXl78l5BtSsN3pj9JFQhSTbLAr5GaFbz6yp94Swm1G5Ffg9Pi
 K07QvYKn+ewLB/bgXM5DhhwaSIUYq/GfxJ23m9cEQ2NUWZ3mP1shr14QXq4xzUgpBv/WiOKlr6f
 AYUJ6Ksr6UXRuQdvAq5J2o0LC9G324tnaZIW6PtpqFcO5xkxUaH5kE7pzcWpX84xsMT3kZqfRNw
 EmF6T9E7uqA18CVdLOicxqKFpYlX5GL7Ye4FW1N89Tqx3h1f6UUleaoDGRqXZd7UvaRB+zz/MEt
 3cnpNxAYtJGakK7lLxEg4oe4Rv9a0ImX95IgpHdtKwXcIDk7qTpGU1LdbPPvUjQiwQLheM1KNF5
 UXhfrmTz6Qa+sFjZgApS54LOh27TwKqn/KKFLLkVzXVSdudM56L1ocfQDWBwqtzp/tw+LO/hBkx
 vQr3zOuy2B1VfyfZBPjPjF5tcb8b/YQ6xoS5dTUV9YGHhV3d5YjYs5pOYMBtA+GHPNQi+ErKwNq
 JP0DDTa/pmUZegQ==
X-Developer-Key: i=airlied@redhat.com; a=openpgp;
 fpr=10A6D91DA1B05BD29F6DEBAC0C74F35979C486BE
X-Endpoint-Received: by B4 Relay for airlied@redhat.com/default with auth_id=1321
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The nouveau C driver does ktime_to_ns(ktime_get()) to program
the cpu ns into some hw/fw, so allow this method for rust drivers.

This is needed for following nova patch.

Reviewed-by: FUJITA Tomonori <fujita.tomonori@gmail.com>
Reviewed-by: Alexandre Courbot <acourbot@nvidia.com>
Signed-off-by: Dave Airlie <airlied@redhat.com>
---
 rust/kernel/time.rs | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/time.rs b/rust/kernel/time.rs
index b6a2aab12a50..4409291f3ffa 100644
--- a/rust/kernel/time.rs
+++ b/rust/kernel/time.rs
@@ -215,8 +215,9 @@ pub fn elapsed(&self) -> Delta {
         Self::now() - *self
     }
 
+    /// Return the raw nanoseconds values since the epoch of clock `C`.
     #[inline]
-    pub(crate) fn as_nanos(&self) -> i64 {
+    pub fn as_nanos(&self) -> i64 {
         self.inner
     }
 

-- 
2.56.0

